---@class AutoApproveConfig
---@field allowed_cmds? string[] Allowed commands for cmd_runner and mcp execute_command.
---@field secret_files? string[] List of files (in glob format) that should not be sent to LLM.
---@field project_root? string Allow file operations in this directory and below.
---@field codecompanion? table<string,boolean> Code Companion tools to protect (when true).
---@field mcphub_neovim? boolean If true then protect @mcp Neovim tools.
---@field mcphub_filesystem? boolean If true then protect @mcp filesystem tools.
---@field mcphub_git? boolean If true then protect @mcp git tools.
---@field mcphub_shell? boolean If true then protect @mcp shell tools.
local defaults = {
    allowed_cmds = nil,
    secret_files = {
        '.env*',
        'env*.sh',
    },
    project_root = nil,
    codecompanion = {
        cmd_runner = true,
        create_file = true,
        insert_edit_into_file = true,
        read_file = true,
    },
    mcphub_neovim = true,
    mcphub_filesystem = true,
    mcphub_git = true,
    mcphub_shell = true,
}

local M = {
    config = vim.deepcopy(defaults),
}

local function notify(message, level)
    local info = debug.getinfo(2, 'n')
    if info and info.name then
        message = info.name .. ': ' .. message
    end
    message = 'auto_approve: ' .. message
    vim.notify(message, level or vim.log.levels.INFO)
end

---@param opts? AutoApproveConfig
function M.setup(opts)
    opts = opts or {}
    M.config = vim.tbl_deep_extend('force', vim.deepcopy(defaults), opts)
end

-- Updates CodeCompanion config to protect tools based on user-defined settings.
-- Tools with already set requires_approval to a function won't be modified.
function M.setup_codecompanion()
    local config = require 'codecompanion.config'
    local tools = config.config.strategies.chat.tools

    for tool_name, protect in pairs(M.config.codecompanion) do
        if not protect then
            goto continue
        end

        tools[tool_name].opts = tools[tool_name].opts or {}
        if type(tools[tool_name].opts.requires_approval) == 'function' then
            goto continue
        end

        if tool_name == 'cmd_runner' then
            ---@type boolean|function(CodeCompanion.Agent.Tool, CodeCompanion.Agent)
            tools[tool_name].opts.requires_approval = M.cmd_runner
        elseif
            tool_name == 'create_file'
            or tool_name == 'read_file'
            or tool_name == 'insert_edit_into_file'
        then
            ---@type boolean|function(CodeCompanion.Agent.Tool, CodeCompanion.Agent)
            tools[tool_name].opts.requires_approval = M.filepath
        else
            notify('unknown tool: ' .. tool_name, vim.log.levels.ERROR)
        end

        ::continue::
    end
end

local function is_cmd_allowed(cmd)
    -- Strip "cd {project_root} && " prefix if present
    if M.config.project_root and M.config.project_root ~= '' then
        local prefix = 'cd ' .. M.config.project_root .. ' && '
        if vim.startswith(cmd, prefix) then
            cmd = cmd:sub(#prefix + 1)
        end
    end

    for _, allowed_cmd in ipairs(M.config.allowed_cmds or {}) do
        if cmd == allowed_cmd then
            return true
        end
    end
    return false
end

-- Auto-approve command execution using whitelist.
---@param tool CodeCompanion.Agent.Tool
---@return boolean requires_approval
function M.cmd_runner(tool, _)
    return not is_cmd_allowed(tool.args.cmd)
end

local function is_project_path(filepath)
    if not M.config.project_root or M.config.project_root == '' then
        return false
    end

    local project_dir = vim.uv.fs_realpath(M.config.project_root)
    if not project_dir then
        return false
    end

    local abs_path = vim.fn.fnamemodify(filepath, ':p')
    abs_path = vim.uv.fs_realpath(abs_path) or abs_path

    return abs_path == project_dir or vim.startswith(abs_path, project_dir .. '/')
end

local function is_secret_file(filepath)
    local filename = vim.fn.fnamemodify(filepath, ':t')
    for _, glob in ipairs(M.config.secret_files or {}) do
        local regex = vim.fn.glob2regpat(glob)
        if vim.fn.match(filename, regex) ~= -1 then
            return true
        end
    end
    return false
end

-- Auto-approve file operations only in project dir (current git repo or cwd)
-- excluding secret files.
---@param tool CodeCompanion.Agent.Tool
---@return boolean requires_approval
function M.filepath(tool, _)
    return not is_project_path(tool.args.filepath) or is_secret_file(tool.args.filepath)
end

-- Auto-approve command execution using whitelist.
-- Auto-approve file operations only in project dir (current git repo or cwd).
-- Supported MCP servers:
--  - Neovim
--  - Filesystem
--  - Git
--  - Shell
---@module 'mcphub'
---@param params MCPHub.ParsedParams
---@return boolean | nil | string auto_approve Nil same as false, string to deny with error.
function M.mcphub(params)
    -- Respect CodeCompanion's auto tool mode when enabled
    if vim.g.codecompanion_auto_tool_mode then
        return true -- Auto approve when CodeCompanion auto-tool mode is on.
    end

    local auto_approve = false

    if params.server_name == 'neovim' and M.config.mcphub_neovim then
        if params.tool_name == 'execute_command' then
            auto_approve = is_project_path(params.arguments.cwd)
                and is_cmd_allowed(params.arguments.command)
        elseif
            params.tool_name == 'delete_item'
            or params.tool_name == 'find_files'
            or params.tool_name == 'list_directory'
            or params.tool_name == 'move_item'
            or params.tool_name == 'read_file'
            or params.tool_name == 'replace_in_file'
            or params.tool_name == 'write_file'
        then
            auto_approve = is_project_path(params.arguments.path)
            if params.tool_name == 'move_item' then
                auto_approve = auto_approve and is_project_path(params.arguments.new_path)
            end
        end
    elseif params.server_name == 'filesystem' and M.config.mcphub_filesystem then
        if params.tool_name == 'move_file' then
            auto_approve = is_project_path(params.arguments.source)
                and is_project_path(params.arguments.destination)
        elseif params.tool_name == 'read_multiple_files' then
            auto_approve = vim.iter(params.arguments.paths):fold(true, function(acc, path)
                return acc and is_project_path(path)
            end)
        elseif
            params.tool_name == 'create_directory'
            or params.tool_name == 'directory_tree'
            or params.tool_name == 'edit_file'
            or params.tool_name == 'get_file_info'
            or params.tool_name == 'list_directory'
            or params.tool_name == 'read_file'
            or params.tool_name == 'search_files'
            or params.tool_name == 'write_file'
        then
            auto_approve = is_project_path(params.arguments.path)
        end
    elseif params.server_name == 'git' and M.config.mcphub_git then
        auto_approve = is_project_path(params.arguments.repo_path)
    elseif params.server_name == 'shell' and M.config.mcphub_shell then
        if params.tool_name == 'shell_exec' then
            auto_approve = is_cmd_allowed(params.arguments.command)
        end
    end

    if auto_approve then
        return true
    end
    if not params.is_auto_approved_in_server then
        vim.api.nvim_exec_autocmds('User', { pattern = 'MCPHubApprovalWindowOpened' })
    end
    return params.is_auto_approved_in_server -- Respect servers.json configuration.
end

return M

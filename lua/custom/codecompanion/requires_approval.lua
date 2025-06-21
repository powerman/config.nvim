---@class CodeCompanionRequiresApprovalConfig
---@field allowed_cmds? string[] Allowed commands for cmd_runner and mcp execute_command.
---@field allow_cwd? boolean If true then allow file operations in cwd without git repo.
---@field std? string[] List of Code Companion tools to protect.
---@field mcp_neovim? boolean If true then protect @mcp Neovim tools.
local defaults = {
    allowed_cmds = {},
    allow_cwd = false,
    std = {
        'cmd_runner',
        'create_file',
        'insert_edit_into_file',
        'read_file',
    },
    mcp_neovim = true,
}

local M = {
    config = vim.deepcopy(defaults),
}

--- Configures CodeCompanion to require approval on command execution and file operations if
--- - user does not set custom require_appoval callback,
--- - the command is not in the allowed list,
--- - file operation is not in the current repository or current directory.
---
---@param opts? CodeCompanionRequiresApprovalConfig
function M.setup(opts)
    opts = opts or {}
    M.config = vim.tbl_deep_extend('force', vim.deepcopy(defaults), opts)

    local config = require 'codecompanion.config'
    local tools = config.config.strategies.chat.tools

    for _, tool_name in ipairs(M.config.std) do
        tools[tool_name].opts = tools[tool_name].opts or {}
        if tool_name == 'cmd_runner' then
            if type(tools[tool_name].opts.requires_approval) ~= 'function' then
                ---@type boolean|function(CodeCompanion.Agent.Tool, CodeCompanion.Agent)
                tools[tool_name].opts.requires_approval = M.cmd_runner
            end
        elseif
            tool_name == 'create_file'
            or tool_name == 'read_file'
            or tool_name == 'insert_edit_into_file'
        then
            if type(tools[tool_name].opts.requires_approval) ~= 'function' then
                ---@type boolean|function(CodeCompanion.Agent.Tool, CodeCompanion.Agent)
                tools[tool_name].opts.requires_approval = M.filepath
            end
        else
            error('std tool is not supported: ' .. tool_name)
        end
    end
    if tools.use_mcp_tool then
        tools.use_mcp_tool.opts = tools.use_mcp_tool.opts or {}
        if type(tools.use_mcp_tool.opts.requires_approval) ~= 'function' then
            tools.use_mcp_tool.opts.requires_approval = M.mcp
        end
    end
end

local function is_cmd_allowed(cmd)
    for _, allowed_cmd in ipairs(M.config.allowed_cmds) do
        if cmd == allowed_cmd then
            return true
        end
    end
    return false
end

-- Auto-approve command execution using whitelist.
---@param tool CodeCompanion.Agent.Tool
function M.cmd_runner(tool, _)
    return not is_cmd_allowed(tool.args.cmd)
end

local function is_project_path(filepath)
    local git_dir = vim.fn.finddir('.git', '.;')
    if git_dir == '' and not M.config.allow_cwd then
        return false
    end

    local project_dir = vim.uv.fs_realpath(vim.fn.fnamemodify(git_dir, ':h'))
    if not project_dir then
        return false
    end

    local abs_path = vim.fn.fnamemodify(filepath, ':p')
    abs_path = vim.uv.fs_realpath(abs_path) or abs_path

    return abs_path == project_dir or vim.startswith(abs_path, project_dir .. '/')
end

-- Auto-approve file operations only in project dir (current git repo or cwd).
---@param tool CodeCompanion.Agent.Tool
function M.filepath(tool, _)
    return not is_project_path(tool.args.filepath)
end

---@param cfg CustomMCPServerConfig
local function resetCustomAutoApprove(cfg, tool_name)
    if type(cfg.autoApprove) == 'nil' or type(cfg.autoApprove) == 'boolean' then
        cfg.autoApprove = false
    else
        local t = cfg.autoApprove ---@cast t table<string>
        cfg.autoApprove = vim.tbl_filter(function(item)
            return item ~= tool_name
        end, t)
    end
end

-- Auto-approve command execution using whitelist.
-- Auto-approve file operations only in project dir (current git repo or cwd).
-- Supported MCP servers:
--  - Neovim
--
-- It's impossible to use a simple `return true` in requires_approval with MCP:
-- it breaks because the request to run a tool doesn't get the required response
-- if the call isn't approved by CodeCompanion (not sure why this happens).
-- Anyway, when CodeCompanion requests approval for an MCP tool call, it doesn't
-- show the actual tool and arguments to the user. So even if it worked, the UX
-- would be poor.
-- Let's work around these issues by elevating MCPHub's approval instead.
--
-- Disable MCPHub's autoApprove on the first call with unsafe args.
-- This will trigger MCPHub's approval request for that unsafe call and all
-- subsequent calls until auto-approve is manually re-enabled.
---@param tool CodeCompanion.Agent.Tool
function M.mcp(tool, _)
    local resetAutoApprove = false
    local resetNativeAutoApprove = false

    if tool.args.server_name == 'neovim' and M.config.mcp_neovim then
        if
            tool.args.tool_name == 'delete_item'
            or tool.args.tool_name == 'find_files'
            or tool.args.tool_name == 'list_directory'
            or tool.args.tool_name == 'move_item'
            or tool.args.tool_name == 'read_file'
            or tool.args.tool_name == 'replace_in_file'
            or tool.args.tool_name == 'write_file'
        then
            resetNativeAutoApprove = resetNativeAutoApprove
                or not is_project_path(tool.args.tool_input.path)
        end
        if tool.args.tool_name == 'move_item' then
            resetNativeAutoApprove = resetNativeAutoApprove
                or not is_project_path(tool.args.tool_input.new_path)
        elseif tool.args.tool_name == 'execute_command' then
            resetNativeAutoApprove = resetNativeAutoApprove
                or not is_project_path(tool.args.tool_input.cwd)
                or not is_cmd_allowed(tool.args.tool_input.command)
        end
    end

    if resetAutoApprove then
        local cfg = require('mcphub.state').servers_config[tool.args.server_name] or {}
        resetCustomAutoApprove(cfg, tool.args.tool_name)
    elseif resetNativeAutoApprove then
        local cfg = require('mcphub.state').native_servers_config[tool.args.server_name] or {}
        resetCustomAutoApprove(cfg, tool.args.tool_name)
    end

    return false
end

return M

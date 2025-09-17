---@class AutoApproveConfig
---@field allowed_cmds? string[] Allowed commands for cmd_runner, neovim__execute_command, shell__shell_exec. Supports patterns (e.g., 'go test *').
---@field cmd_env? boolean Allow safe environment variables in commands (default: true).
---@field cmd_glob? boolean Allow * ? in command args (default: false).
---@field cmd_redir? boolean Allow safe output redirections in commands (default: true).
---@field cmd_control? boolean Allow command control operators: &&, ||, |&, |, ; (default: true).
---@field secret_files? string[] List of files (in glob format) that should not be sent to LLM.
---@field project_root? string Allow file operations in this directory and below.
---@field codecompanion? table<string,boolean> Code Companion tools to protect (when true).
---@field mcphub_neovim? boolean If true then protect @mcp Neovim tools.
---@field mcphub_filesystem? boolean If true then protect @mcp filesystem tools.
---@field mcphub_git? boolean If true then protect @mcp git tools.
---@field mcphub_shell? boolean If true then protect @mcp shell tools.
local defaults = {
    allowed_cmds = {},
    cmd_env = true,
    cmd_glob = false,
    cmd_redir = true,
    cmd_control = true,
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

local UNSAFE_CMD_SUBSTRINGS = {
    '../',
    '`', -- Isn't included in "safe quoted chars", so this is just an extra precaution.
    '$(', -- Isn't included in "safe quoted chars", so this is just an extra precaution.
}

local UNSAFE_ENV_NAME_PREFIXES = {
    'LD_',
    'DYLD_',
    'CLASSPATH=',
    'GIO_EXTRA_MODULES=',
    'GTK_PATH=',
    'LIBGL_DRIVERS_PATH=',
    'LIBRARY_PATH=',
    'NODE_PATH=',
    'PATH=',
    'PERL5LIB=',
    'PKG_CONFIG_PATH=',
    'PYTHONPATH=',
    'QT_PLUGIN_PATH=',
    'RUBYLIB=',
}

-- Not included in these 3 sets: ' " ~ and ASCII control except \t\r\n
local SAFE_UNQUOTED = '%%+,%-./0-9:@A-Z^_a-z\128-\255'
local SAFE_DQ = '%s!#&()*;<=>?[%]{|}' -- Escaped $ \ ` are allowed by safe_dq function.
local SAFE_SQ = '$\\`' .. SAFE_DQ

local SAFE_ENV_NAME_SET = 'A-Za-z0-9_'
local SAFE_ENV_VAL_SET = '~' .. SAFE_UNQUOTED
local SAFE_ENV_VAL_SQ_SET = '"' .. SAFE_SQ .. SAFE_ENV_VAL_SET
local SAFE_ENV_VAL_DQ_SET = "'" .. SAFE_DQ .. SAFE_ENV_VAL_SET

local SAFE_ARG_SET = '=~' .. SAFE_UNQUOTED
local SAFE_ARG_SQ_SET = '"' .. SAFE_SQ .. SAFE_ARG_SET
local SAFE_ARG_DQ_SET = "'" .. SAFE_DQ .. SAFE_ARG_SET

local SAFE_ARG_GLOB = '*?' -- Support for [] will also require ! and ^ so postpone it for now.

local SAFE_REDIR_PATTERNS = {
    '[0-9]>&[0-9]',
    '[12]?>%s*/dev/null', -- to /dev/null
    '[12]?>%s*[A-Za-z0-9_.%-][/A-Za-z0-9_.%-]*', -- to relative file
}

local CONTROL_OPERATORS = { '&&', '||', '|&', '|', ';' }

local function safe_dq(s, set)
    -- Do not allow escaped " just in case, to prevent bypassing checks.
    -- Escaping for shell needs only $, \, and ` - the rest are for grep regexp etc.
    local escaped = SAFE_SQ .. SAFE_UNQUOTED
    return s:gsub('\\[' .. escaped .. ']', ''):match('^"[' .. set .. ']*"$')
end

local M = {
    config = vim.deepcopy(defaults),
    session_allowed_cmds = {}, -- Commands added via :AutoApproveAddAllowedCmd.
}

local function notify(message, level)
    local info = debug.getinfo(2, 'n')
    if info and info.name then
        message = info.name .. ': ' .. message
    end
    message = 'auto_approve: ' .. message
    vim.notify(message, level or vim.log.levels.INFO)
end

--- Validate a single command pattern.
---@param cmd string Command to validate.
---@return boolean valid Whether command is valid.
local function validate_command(cmd)
    local msg = 'skip allowed cmd '
    if type(cmd) ~= 'string' then
        notify(msg .. vim.inspect(cmd) .. ': must be a string', vim.log.levels.ERROR)
        return false
    elseif vim.trim(cmd) == '' then
        notify(msg .. vim.inspect(cmd) .. ': empty string', vim.log.levels.ERROR)
        return false
    elseif vim.startswith(vim.trim(cmd), '*') then
        notify(msg .. vim.inspect(cmd) .. ': cannot start with *', vim.log.levels.ERROR)
        return false
    end
    return true
end

---@param opts? AutoApproveConfig
function M.setup(opts)
    opts = opts or {}
    M.config = vim.tbl_deep_extend('force', vim.deepcopy(defaults), opts)

    for i = #M.config.allowed_cmds, 1, -1 do
        if validate_command(M.config.allowed_cmds[i]) then
            M.config.allowed_cmds[i] = vim.trim(M.config.allowed_cmds[i])
        else
            table.remove(M.config.allowed_cmds, i)
        end
    end
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

-- Command parsing with simple pattern matching.
-- Supports patterns with * wildcards and automatic approval for environment variables,
-- redirections, and command chains.

--- Check if command is not safe.
---@param cmd string
---@return boolean
local function is_cmd_unsafe(cmd)
    -- Remove quotes to prevent bypassing security checks (e.g., `."."/` is a `../`).
    local cleaned_cmd = cmd:gsub('["\']', '')

    for _, substring in ipairs(UNSAFE_CMD_SUBSTRINGS) do
        if cleaned_cmd:find(substring, 1, true) then
            return true
        end
    end
    return false
end

--- Check if environment variable is not safe.
---@param name string
---@return boolean
local function is_env_unsafe(name)
    for _, prefix in ipairs(UNSAFE_ENV_NAME_PREFIXES) do
        if vim.startswith(name .. '=', prefix) then
            return true
        end
    end
    return false
end

--- Trim safe environment variables from the beginning of command.
---@param cmd string Full command which may start with env vars.
---@return string cmd Rest of command without prefix containing safe env vars.
local function trim_safe_env_vars(cmd)
    if not M.config.cmd_env then
        return cmd
    end

    while true do
        local _, e, k = cmd:find('^([' .. SAFE_ENV_NAME_SET .. ']+)=')
        if not e then
            return cmd
        end

        local value_pos = e + 1
        _, e = cmd:find('^[' .. SAFE_ENV_VAL_SET .. ']*%s+', value_pos)
        if not e then
            _, e = cmd:find("^'[" .. SAFE_ENV_VAL_SQ_SET .. "]*'%s+", value_pos)
        end
        if not e then
            _, e = cmd:find('^"[^"]*"', value_pos)
            if e and not safe_dq(cmd:sub(value_pos, e), SAFE_ENV_VAL_DQ_SET) then
                e = nil
            end
            if e then
                _, e = cmd:find('^%s+', e + 1)
            end
        end
        if not e then
            return cmd
        end

        if is_env_unsafe(k) then
            return cmd
        end
        cmd = cmd:sub(e + 1)
    end
end

--- Split allowed_cmd pattern into space-separated tokens.
---@param allowed_cmd string
---@return string[] tokens
local function split_allowed_cmd(allowed_cmd)
    local tokens = {}
    local i = 1
    local len = #allowed_cmd
    while i <= len do
        local _, e = allowed_cmd:find('^%s*', i)
        i = e + 1

        local from = i
        while i <= len do
            _, e = allowed_cmd:find([[^[^%s'"]+]], i)
            if not e then
                _, e = allowed_cmd:find("^%b''", i)
            end
            if not e then
                _, e = allowed_cmd:find('^%b""', i)
            end
            if not e then
                break
            end
            i = e + 1
        end

        if from >= i then -- No match: either end of string or unbalanced quote.
            if i <= len then -- Unbalanced quote, take the rest of the string.
                if #tokens == 0 or allowed_cmd:match('^%s', i - 1) ~= nil then -- Separate token.
                    table.insert(tokens, allowed_cmd:sub(i))
                else -- Part of previous token.
                    tokens[#tokens] = tokens[#tokens] .. allowed_cmd:sub(i)
                end
            end
            break
        end

        table.insert(tokens, allowed_cmd:sub(from, i - 1))
    end
    return tokens
end

--- Try to get safe argument from the beginning of a command.
---@param cmd string Command to check
---@return string arg Argument if found.
---@return boolean space_after Whether there was a space after the argument.
---@return string remaining_cmd Unmodified command if no safe arg found.
local function try_get_safe_arg(cmd)
    local safe_arg_set = SAFE_ARG_SET
    if M.config.cmd_glob then
        safe_arg_set = safe_arg_set .. SAFE_ARG_GLOB
    end

    local i = 1
    while i <= #cmd do
        local _, e = cmd:find('^[' .. safe_arg_set .. ']+', i)
        if not e then
            _, e = cmd:find("^'[" .. SAFE_ARG_SQ_SET .. "]*'", i)
        end
        if not e then
            _, e = cmd:find('^"[^"]*"', i)
            if e and not safe_dq(cmd:sub(i, e), SAFE_ARG_DQ_SET) then
                e = nil
            end
        end
        if not e then
            break
        end
        i = e + 1
    end
    local remaining_cmd, n = cmd:sub(i):gsub('^%s+', '')
    if i <= #cmd and n == 0 then -- No space or end of string after arg.
        return '', false, cmd
    end
    return cmd:sub(1, i - 1), n > 0, remaining_cmd
end

--- Check if a command part matches a pattern.
---@param pattern string Pattern to match against
---@param cmd string Command to check
---@return string | nil remaining_cmd if matches, otherwise nil
local function match_allowed_cmd(pattern, cmd)
    local pattern_tokens = split_allowed_cmd(pattern)

    for i, p_token in ipairs(pattern_tokens) do
        if vim.endswith(p_token, '*') then
            local prefix = p_token:sub(1, -2)
            prefix = prefix:gsub('["\']', '')
            while true do
                local arg, space_after, remaining_cmd = try_get_safe_arg(cmd)
                arg = arg:gsub('["\']', '')
                if not vim.startswith(arg, prefix) then
                    break
                end

                cmd = remaining_cmd
                if not space_after then
                    break
                end
            end
        elseif vim.startswith(cmd, p_token) then
            cmd = cmd:sub(#p_token + 1)
            local n
            cmd, n = cmd:gsub('^%s+', '')
            if n == 0 and i < #pattern_tokens then
                -- Special case: if next token is the last and is '*' then everything is fine.
                if i + 1 == #pattern_tokens and pattern_tokens[i + 1] == '*' then
                    break
                end
                return nil -- No space after token and not the last token.
            end
        else
            return nil -- Token does not match.
        end
    end

    return cmd
end

--- Strip redirections from command.
---@param cmd string Command part to process
---@return string cleaned_cmd Command with redirections removed
local function strip_redirections(cmd)
    if not M.config.cmd_redir then
        return cmd
    end

    repeat
        local prev_cmd = cmd
        for _, pattern in ipairs(SAFE_REDIR_PATTERNS) do
            cmd = cmd:gsub('^' .. pattern .. '%s*', '')
        end
    until cmd == prev_cmd

    return cmd
end

-- TODO: Implement blacklist for commands with non-obvious execution capabilities:
-- find -exec, find -execdir, find -ok, find -okdir, fd -exec - these are the most dangerous
-- as users often forget they can execute arbitrary commands.
-- Another example is ack --pager and envs like EDITOR, GIT_PAGER, PAGER, MANPAGER, etc.
-- Other similar commands to research: rsync --rsh, awk -f and sed -e with system(),
-- sort --compress-program, tar --use-compress-program (it actually have a lot of ways to run
-- a command from it args).

-- TODO: Implement command wrapper parsing for commands whose main purpose is
-- executing other commands: xargs, timeout, nohup, watch, parallel, mise exec, mise x, env.
-- These should skip the (allowed) wrapper and validate the actual command being executed.

--- Check if command is allowed based on patterns.
---@param cmd string Full command to check
---@return boolean allowed Whether command is allowed
local function is_cmd_allowed(cmd)
    cmd = vim.trim(cmd)

    -- Strip "cd {project_root} && " prefix if present
    if M.config.project_root and M.config.project_root ~= '' then
        local prefix = 'cd ' .. M.config.project_root .. ' && '
        if vim.startswith(cmd, prefix) then
            cmd = cmd:sub(#prefix + 1)
        end
    end

    if is_cmd_unsafe(cmd) then
        return false
    end

    local allowed_cmds = {}
    for _, allowed_cmd in ipairs(M.session_allowed_cmds) do
        table.insert(allowed_cmds, allowed_cmd)
    end
    for _, allowed_cmd in ipairs(M.config.allowed_cmds) do
        table.insert(allowed_cmds, allowed_cmd)
    end

    while true do
        cmd = trim_safe_env_vars(cmd)

        if cmd == '' then
            return false
        end

        local operator_found = false

        for _, allowed_cmd in ipairs(allowed_cmds) do
            local after_cmd = match_allowed_cmd(allowed_cmd, cmd)
            if after_cmd ~= nil then
                after_cmd = strip_redirections(after_cmd)

                if after_cmd == '' or after_cmd == ';' then
                    return true
                end

                if M.config.cmd_control then
                    for _, op in ipairs(CONTROL_OPERATORS) do
                        if vim.startswith(after_cmd, op) then
                            cmd = vim.trim(after_cmd:sub(#op + 1))
                            operator_found = true
                            break
                        end
                    end
                    if operator_found then
                        break
                    end
                end
            end
        end

        if not operator_found then
            return false
        end
    end
end

-- Auto-approve command execution using whitelist.
---@param tool CodeCompanion.Tools.Tool
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
---@param tool CodeCompanion.Tools.Tool
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
    if vim.g.codecompanion_yolo_mode then
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

vim.api.nvim_create_user_command('AutoApproveAddAllowedCmd', function(opts)
    local cmd = opts.args
    if validate_command(cmd) then
        table.insert(M.session_allowed_cmds, vim.trim(cmd))
    end
end, { nargs = '+', desc = 'Add command to session approval list' })

vim.api.nvim_create_user_command('AutoApproveResetAllowedCmds', function()
    M.session_allowed_cmds = {}
end, { desc = 'Clear all session approval commands' })

vim.api.nvim_create_user_command('AutoApproveListAddedAllowedCmds', function()
    vim.print('There are ' .. #M.session_allowed_cmds .. ' added allowed_cmds.')
    for _, cmd in ipairs(M.session_allowed_cmds) do
        vim.print(cmd)
    end
end, { desc = 'List current session approval commands' })

return M

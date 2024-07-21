---@param s string String to split.
---@param pat string Pattern to split on.
---@return Iterator string Elements of s including empty before first/after last sep.
local function split(s, pat)
    pat = pat or '%s+'
    local st, g = 1, s:gmatch('()(' .. pat .. ')')
    local function getter(segs, seps, sep)
        st = sep and seps + #sep
        return s:sub(segs, (seps or 0) - 1)
    end
    return function()
        if st then
            return getter(st, g())
        end
    end
end

--- Removes first elem from t.
---@param t any[]
---@param elem any
---@return boolean: True if removed.
local function remove_elem(t, elem)
    for i, v in ipairs(t) do
        if v == elem then
            table.remove(t, i)
            return true
        end
    end
    return false
end

local M = {}

-- Keeps current project's paths (to be able to remove them from $PATH).
M._PATH = {}

---@class Config
---@field root_patterns string[]

-- Setup project-specific $PATH to use required version of a tool (Formatter|Linter|LSP|…).
---@param cfg Config
M.setup = function(cfg)
    vim.api.nvim_create_autocmd('FileType', { -- Use FileType just to run before LSPAttach.
        desc = 'Setup project-specific $PATH',
        group = vim.api.nvim_create_augroup('project.path', { clear = true }),
        once = true,
        callback = function()
            for _, root_pattern in ipairs(cfg.root_patterns) do
                M.prepend_PATH(vim.fn.getcwd(), root_pattern)
            end
        end,
    })
end

-- Lookup for a directory bin_subdir in file's project root directory and add it to $PATH.
M.prepend_PATH = function(file, bin_subdir)
    local root_dir = require('lspconfig.util').root_pattern(bin_subdir)(file)
    if not root_dir then
        return
    end
    local bin_dir = root_dir .. '/' .. bin_subdir
    if not vim.fn.isdirectory(bin_dir) then
        return
    end
    table.insert(M._PATH, bin_dir)
    vim.env.PATH = bin_dir .. ':' .. vim.env.PATH
end

-- Remove from $PATH everything added by previous prepend_PATH() calls.
M.reset_PATH = function()
    local PATH = {}
    for path in split(vim.env.PATH, ':') do
        if not remove_elem(M._PATH, path) then
            table.insert(PATH, path)
        end
    end
    M._PATH = {}
    vim.env.PATH = table.concat(PATH, ':')
end

return M

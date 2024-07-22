local M = {}

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
    if vim.fn.isdirectory(bin_dir) == 0 then
        return
    end
    vim.env.PATH = bin_dir .. ':' .. vim.env.PATH
end

return M

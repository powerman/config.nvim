vim.filetype.add {
    -- extension = {},
    filename = {
        ['~/.markdownlintrc'] = 'ini', -- Also can be 'jsonc'.
    },
    -- pattern = {},
}

if vim.g.debug_lsp then
    vim.lsp.set_log_level 'trace'
    require('vim.lsp.log').set_format_func(vim.inspect)
end

vim.diagnostic.config {
    underline = false, -- Do not underline text related to diagnostics.
    signs = {
        text = { -- Use icons instead of letters E/W/I/H.
            [vim.diagnostic.severity.ERROR] = '❌', -- 󰅚
            [vim.diagnostic.severity.WARN] = '', -- 󰀪
            [vim.diagnostic.severity.INFO] = '', -- 󰋽
            [vim.diagnostic.severity.HINT] = '󰌶', -- 󰌵💡󱠂
        },
    },
    float = {
        source = true, -- Useful for debugging issues with LSP/linters.
    },
    severity_sort = true, -- Ensure higher severity sign will be shown.
    virtual_text = false,
    virtual_lines = { current_line = true },
}

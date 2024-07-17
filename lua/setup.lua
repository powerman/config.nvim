if vim.g.debug_lsp then
    vim.lsp.set_log_level 'trace'
    require('vim.lsp.log').set_format_func(vim.inspect)
end

vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, {
    border = vim.g.float_border,
    max_width = math.floor(vim.fn.winwidth(0) * vim.g.float_max_width),
})
vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(vim.lsp.handlers.signature_help, {
    border = vim.g.float_border,
    max_width = math.floor(vim.fn.winwidth(0) * vim.g.float_max_width),
})

vim.diagnostic.config {
    underline = false, -- Do not underline text related to diagnostics.
    signs = {
        text = { -- Use icons instead of letters E/W/I/H.
            [vim.diagnostic.severity.ERROR] = '❌', -- 󰅚
            [vim.diagnostic.severity.WARN] = '', -- 󰀪
            [vim.diagnostic.severity.INFO] = '', -- 
            [vim.diagnostic.severity.HINT] = '󰌶', -- 󰌵💡󱠂
        },
    },
    float = {
        border = vim.g.float_border,
        source = true, -- Useful for debugging issues with LSP/linters.
    },
    severity_sort = true, -- Ensure higher severity sign will be shown.
}

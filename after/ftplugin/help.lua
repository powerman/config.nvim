vim.opt_local.signcolumn = 'auto'

vim.api.nvim_buf_set_keymap(0, 'n', 'q', ':lclose<CR><C-W>q', {
    noremap = true,
    nowait = true,
    silent = true,
    desc = '[Q]uit the current window',
})

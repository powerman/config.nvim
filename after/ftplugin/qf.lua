vim.opt_local.signcolumn = 'auto'

vim.keymap.set('n', 'q', '<Cmd>quit<CR>', {
    buffer = true,
    nowait = true,
    silent = true,
    desc = '[Q]uit the current window',
})

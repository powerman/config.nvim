-- [[ Setting basic autocommands ]]
--
--  See `:help lua-guide-autocommands`.

-- Highlight when yanking (copying) text.
--  Try it with `yap` in normal mode.
--  See `:help vim.highlight.on_yank()`.
vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking (copying) text',
    group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
    callback = function()
        vim.highlight.on_yank()
    end,
})

-- Starting `nvim` with multiple files will open them in tabs, so you can use
-- `nvim file1 file2` instead of `nvim -p file1 file2`.
vim.api.nvim_create_autocmd('VimEnter', {
    desc = 'On start open multiple files in own tabs instead of hidden buffers',
    group = vim.api.nvim_create_augroup('start-in-tabs', { clear = true }),
    callback = function()
        vim.cmd 'if argc() > 1 && !&diff | tab sball | tabfirst | endif'
    end,
})

-- After closing a tab switch to a previous tab instead of a next tab.
local close_tab_group = vim.api.nvim_create_augroup('close_tab', { clear = true })
local closed_tab_nr = 0
vim.api.nvim_create_autocmd('TabLeave', {
    group = close_tab_group,
    callback = function()
        closed_tab_nr = vim.fn.tabpagenr()
    end,
})
vim.api.nvim_create_autocmd('TabEnter', {
    desc = 'After closing a tab switch to a previous tab instead of a next tab',
    group = close_tab_group,
    callback = function()
        if vim.fn.tabpagenr() ~= 1 and vim.fn.tabpagenr() == closed_tab_nr then
            vim.cmd 'tabprevious'
        end
    end,
})

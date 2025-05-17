--[[ Setting basic autocommands ]]
--
--  See `:help lua-guide-autocommands`.

-- NOTE:  <CR>   Begin a new line below the cursor and insert text.

-- Highlight when yanking (copying) text.
vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking (copying) text',
    group = vim.api.nvim_create_augroup('user.highlight_yank', { clear = true }),
    callback = function()
        vim.highlight.on_yank()
    end,
})

-- Starting `nvim` with multiple files will open them in tabs, so you can use
-- `nvim file1 file2` instead of `nvim -p file1 file2`.
vim.api.nvim_create_autocmd('VimEnter', {
    desc = 'On start open multiple files in own tabs instead of hidden buffers',
    group = vim.api.nvim_create_augroup('user.start_in_tabs', { clear = true }),
    nested = true,
    command = 'if argc() > 1 && !&diff | tab sball | tabfirst | endif',
})

-- For usual files <Enter> begins a new line below the cursor and insert text.
vim.api.nvim_create_autocmd('BufWinEnter', {
    desc = 'Enter begins a new line below the cursor and insert text',
    group = vim.api.nvim_create_augroup('user.map_enter_to_o', { clear = true }),
    callback = function(ev)
        if
            not vim.bo.readonly
            and ev.file ~= 'quickfix'
            and vim.bo.ft ~= 'qf'
            and not vim.wo.diff
            and vim.bo.ft ~= 'diff'
        then
            vim.keymap.set('n', '<CR>', 'o', {
                buffer = ev.buf,
                desc = 'Begin a new line below the cursor and insert text',
            })
        end
    end,
})

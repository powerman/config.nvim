-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Add hotkey to save current buffer: <F2>.
vim.keymap.set('n', '<F2>', ':w<CR>', { desc = 'Save current buffer' })
vim.keymap.set('v', '<F2>', '<Esc>:w<CR>gv', { desc = 'Save current buffer' })
vim.keymap.set('i', '<F2>', '<C-O>:w<CR>', { desc = 'Save current buffer' })

-- Add hotkey to toggle wrap: <F5>.
vim.keymap.set('n', '<F5>', ':set wrap!<CR>', { desc = 'Toggle wrap' })
vim.keymap.set('i', '<F5>', '<C-O>:set wrap!<CR>', { desc = 'Toggle wrap' })

-- Add hotkey to quit if no unsaved changes: <F10>.
vim.keymap.set('n', '<F10>', ':qa<CR>', { desc = 'Quit if no unsaved changes' })
vim.keymap.set('v', '<F10>', '<Esc>:qa<CR>', { desc = 'Quit if no unsaved changes' })
vim.keymap.set('i', '<F10>', '<Esc>:qa<CR>', { desc = 'Quit if no unsaved changes' })

-- Set highlight on search, but clear on pressing <Esc> in normal mode
vim.opt.hlsearch = true
vim.keymap.set('n', '<Esc>', '<Cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set(
    'n',
    '[d',
    vim.diagnostic.goto_prev,
    { desc = 'Go to previous [D]iagnostic message' }
)
vim.keymap.set(
    'n',
    ']d',
    vim.diagnostic.goto_next,
    { desc = 'Go to next [D]iagnostic message' }
)
vim.keymap.set(
    'n',
    '<Leader>e',
    vim.diagnostic.open_float,
    { desc = 'Show diagnostic [E]rror messages' }
)
vim.keymap.set(
    'n',
    '<Leader>q',
    vim.diagnostic.setloclist,
    { desc = 'Open diagnostic [Q]uickfix list' }
)

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking (copying) text',
    group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
    callback = function()
        vim.highlight.on_yank()
    end,
})

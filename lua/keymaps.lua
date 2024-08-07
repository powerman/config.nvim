--[[ Setting basic keymaps ]]
--
--  See `:help vim.keymap.set()`.

-- NOTE:  <F2>         Save current buffer.
-- NOTE:  <F5>         Toggle wrap.
-- NOTE:  <F10>        Quit if no unsaved changes.
-- NOTE:  <C-Insert>   Yank (copy) selection.
-- NOTE:  ]d [d        LSP: Next/prev diagnostic.
-- NOTE:  <Leader>e    LSP: Show diagnostic under cursor.
-- NOTE:  <Leader>q    LSP: Open diagnostics in quickfix list.

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

-- Add hotkey to yank selection: <C-Insert>.
vim.keymap.set('v', '<C-Insert>', 'y', { desc = 'Yank selection' })

-- Allow Ctrl-L to clear the screen in insert mode too.
vim.keymap.set('i', '<C-L>', '<C-O><C-L>', { desc = 'Clears and redraws the screen' })

-- Allow Ctrl-W to work with windows in insert mode too.
vim.keymap.set('i', '<C-W>', '<C-O><C-W>', { desc = '+window' })

-- Set highlight on search, but clear on pressing <Esc> in normal mode
vim.opt.hlsearch = true
vim.keymap.set('n', '<Esc>', '<Cmd>nohlsearch<CR>', { desc = 'Stop the search highlighting' })

-- Diagnostic keymaps
vim.keymap.set(
    'n',
    '[d',
    vim.diagnostic.goto_prev,
    { desc = 'Go to previous diagnostic message' }
)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
vim.keymap.set(
    'n',
    '<Leader>e',
    vim.diagnostic.open_float,
    { desc = 'Show diagnostic error messages' }
)
vim.keymap.set(
    'n',
    '<Leader>q',
    vim.diagnostic.setloclist,
    { desc = 'Open diagnostic quickfix list' }
)

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

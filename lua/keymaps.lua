--[[ Setting basic keymaps ]]
--
--  See `:help vim.keymap.set()`.

-- NOTE:  <F2>         Save current buffer.
-- NOTE:  <F5>         Toggle wrap.
-- NOTE:  <F10>        Quit if no unsaved changes.
-- NOTE:  <C-Up>       Scroll window up.
-- NOTE:  <C-Down>     Scroll window down.
-- NOTE:  <C-Insert>   Yank (copy) selection.
-- NOTE:  <Esc>        Stop the search highlighting.
-- NOTE:  ]d [d        LSP: Next/prev diagnostic.
-- NOTE:  <Leader>e    LSP: Show diagnostic under cursor.
-- NOTE:  <Leader>q    LSP: Open diagnostics in quickfix list.
-- NOTE:  :-)          Smiley: 󰱱.
-- NOTE:  :-(          Smiley: 󰱶.
-- NOTE:  :-/          Smiley: 󱃞.

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

-- Scroll window without moving cursor.
vim.keymap.set('n', '<C-Up>', '<C-Y>', { desc = 'Scroll window up' })
vim.keymap.set('v', '<C-Up>', '<C-Y>', { desc = 'Scroll window up' })
vim.keymap.set('i', '<C-Up>', '<C-O><C-Y>', { desc = 'Scroll window up' })
vim.keymap.set('n', '<C-Down>', '<C-E>', { desc = 'Scroll window down' })
vim.keymap.set('v', '<C-Down>', '<C-E>', { desc = 'Scroll window down' })
vim.keymap.set('i', '<C-Down>', '<C-O><C-E>', { desc = 'Scroll window down' })

-- Add hotkey to yank selection: <C-Insert>.
vim.keymap.set('v', '<C-Insert>', 'y', { desc = 'Yank (copy) selection' })

-- Allow Ctrl-L to clear the screen in insert mode too.
vim.keymap.set('i', '<C-L>', '<C-O><C-L>', { desc = 'Clears and redraws the screen' })

-- Allow Ctrl-W to work with windows in insert mode too.
vim.keymap.set('i', '<C-W>', '<C-O><C-W>', { desc = '+window' })

-- Clear highlights on search when pressing <Esc> in normal mode.
vim.keymap.set('n', '<Esc>', '<Cmd>nohlsearch<CR>', { desc = 'Stop the search highlighting' })

-- Diagnostic keymaps
vim.keymap.set('n', '[d', function()
    vim.diagnostic.jump { count = -1, float = true }
end, { desc = 'Go to previous diagnostic message' })
vim.keymap.set('n', ']d', function()
    vim.diagnostic.jump { count = 1, float = true }
end, { desc = 'Go to next diagnostic message' })
vim.keymap.set(
    'n',
    '<Leader>e',
    vim.diagnostic.open_float,
    { desc = 'Show diagnostic under cursor' }
)
vim.keymap.set(
    'n',
    '<Leader>q',
    vim.diagnostic.setloclist,
    { desc = 'Open diagnostic in quickfix list' }
)

-- Smiley keymaps. Type fast enough (within `timeoutlen`) to replace text with emojis.
vim.api.nvim_set_keymap('i', ':-)', '󰱱', { noremap = true })
vim.api.nvim_set_keymap('i', ':-(', '󰱶', { noremap = true })
vim.api.nvim_set_keymap('i', ':-/', '󱃞', { noremap = true })

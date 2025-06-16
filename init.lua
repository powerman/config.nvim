--[[ Configuration ]]
--
--  INFO: Use <Leader>sc to search cheatsheet with most useful features of this configuration.
--
--  See https://learnxinyminutes.com/docs/lua/.
--  See `:help lua-guide`.

-- NOTE:  nvim --cmd 'let debug_lsp=1'   LSP: Enable debugging.

-- Use <Space> as both <Leader> and <LocalLeader> keys.
-- See `:help mapleader`.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Set to false if you prefer to manually open diagnostic with <Leader>e.
-- See also `vim.diagnostic.config { virtual_lines }` in `setup.lua` as an alternative.
vim.g.auto_open_diagnostic = false

-- Set to true if you have a Nerd Font installed and selected in the terminal.
vim.g.have_nerd_font = true

-- Set to true if you use a Nerd Font with "Mono" suffix in font name (small icons).
vim.g.mono_nerd_font = false

-- Border for floating windows.
-- See allowed values in `:h nvim_open_win()`.
vim.g.float_border = 'rounded'

-- Max size for floating windows.
-- Must be <=1.
vim.g.float_max_height = 0.96
vim.g.float_max_width = 0.96

-- Set to true if you want transparent background.
-- Auto-detected for urxvt terminal, false in other terminals.
vim.g.transparent = string.find(vim.env.TERM or '', '^rxvt') ~= nil
    and string.find(vim.env.COLORFGBG or '', '%d$') == nil

-- You can start Neovim this way to enable it: `nvim --cmd 'let debug_lsp=1'`.
vim.g.debug_lsp = vim.g.debug_lsp or false

-- Setup Nerd Fonts.
require 'nerd-fonts'

-- Setting options.
require 'options'

-- Setting basic keymaps (working without plugins).
require 'keymaps'

-- Setting basic autocommands (working without plugins).
require 'autocmd'

-- Rest of basic setup (working without plugins).
require 'setup'

-- Install `lazy.nvim` plugin manager.
require 'lazy-bootstrap'

-- Install and configure all plugins.
require 'lazy-plugins'

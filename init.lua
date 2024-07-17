--[[ Configuration ]]
--
--  See https://learnxinyminutes.com/docs/lua/.
--  See `:help lua-guide`.

-- Run `nvim --cmd 'let debug_lsp=1'` to enable LSP debugging.
vim.g.debug_lsp = vim.g.debug_lsp or false

-- Set <space> as the leader key.
-- See `:help mapleader`.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Set to true if you have a Nerd Font installed and selected in the terminal.
vim.g.have_nerd_font = true

-- Set to true if you use a Nerd Font with "Mono" suffix in font name (small icons).
vim.g.mono_nerd_font = false

-- Set to false if you prefer to manually open diagnostic with <Leader>e.
vim.g.auto_open_diagnostic = true

-- Border for floating windows.
-- See allowed values in `:h nvim_open_win()`.
vim.g.float_border = 'rounded'

-- Max size for floating windows.
-- Must be <=1.
vim.g.float_max_height = 0.96
vim.g.float_max_width = 0.96

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

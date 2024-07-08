--[[ Configuration ]]
-- See https://learnxinyminutes.com/docs/lua/.
-- See `:help lua-guide`.

-- Set <space> as the leader key.
-- See `:help mapleader`.
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Set to true if you have a Nerd Font installed and selected in the terminal.
vim.g.have_nerd_font = true

-- Set to true if you use a Nerd Font with "Mono" suffix in font name (small icons).
vim.g.mono_nerd_font = false

-- Setup Nerd Fonts.
require 'nerd-fonts'

-- [[ Setting options ]]
require 'options'

-- [[ Basic Keymaps ]]
require 'keymaps'

-- [[ Install `lazy.nvim` plugin manager ]]
require 'lazy-bootstrap'

-- [[ Configure and install plugins ]]
require 'lazy-plugins'

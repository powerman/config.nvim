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

-- Fix icon width for Nerd Fonts v3.2.1.
vim.fn.setcellwidths {
  { 0x23fb, 0x23fe, 2 }, -- IEC Power Symbols
  { 0x2665, 0x2665, 2 }, -- Octicons
  { 0x2b58, 0x2b58, 2 }, -- IEC Power Symbols
  { 0xe000, 0xe00a, 2 }, -- Pomicons
  { 0xe0b8, 0xe0c8, 2 }, -- Powerline Extra
  { 0xe0ca, 0xe0ca, 2 }, -- Powerline Extra
  { 0xe0cc, 0xe0d7, 2 }, -- Powerline Extra
  { 0xe200, 0xe2a9, 2 }, -- Font Awesome Extension
  { 0xe300, 0xe3e3, 2 }, -- Weather Icons
  { 0xe5fa, 0xe6b5, 2 }, -- Seti-UI + Custom
  { 0xe700, 0xe7c5, 2 }, -- Devicons
  { 0xea60, 0xec1e, 2 }, -- Codicons
  { 0xed00, 0xefce, 2 }, -- Font Awesome
  { 0xf000, 0xf2ff, 2 }, -- Font Awesome
  { 0xf300, 0xf375, 2 }, -- Font Logos
  { 0xf400, 0xf533, 2 }, -- Octicons
  { 0xf0001, 0xf1af0, 2 }, -- Material Design
}

-- [[ Setting options ]]
require 'options'

-- [[ Basic Keymaps ]]
require 'keymaps'

-- [[ Install `lazy.nvim` plugin manager ]]
require 'lazy-bootstrap'

-- [[ Configure and install plugins ]]
require 'lazy-plugins'

-- The line beneath this is called `modeline`. See `:help modeline`.
-- vim: ts=2 sts=2 sw=2 et

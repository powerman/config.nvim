--[[ A super powerful autopair plugin for Neovim that supports multiple characters ]]
--
--  - Automatically adds pair for a quote/bracket/paren/etc.
--  - Automatically indent when pressing <CR> inside bracket/paren/etc.

---@module 'lazy'
---@type LazySpec
return {
    'windwp/nvim-autopairs',
    dependencies = { 'hrsh7th/nvim-cmp' },
    lazy = true,
    event = 'InsertEnter',
    config = true,
}

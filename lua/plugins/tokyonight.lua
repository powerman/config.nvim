--[[ A clean, dark Neovim theme, with support for lsp, treesitter and lots of plugins ]]

-- NOTE:  Telescope colorscheme  Select colorscheme.

---@type LazySpec
return {
    {
        'folke/tokyonight.nvim',
        version = '*',
        lazy = false, -- This is active theme.
        priority = 1000, -- Make sure to load this before all the other start plugins.
        ---@type tokyonight.Config
        opts = {
            style = 'night',
            on_highlights = function(hl, c)
                -- Added in `mini.lua`.
                hl.MiniStatuslineLazyUpdates = {
                    fg = c.info,
                    bg = c.fg_gutter,
                }
            end,
        },
        config = function(_, opts)
            require('tokyonight').setup(opts)
            vim.cmd.colorscheme 'tokyonight'
        end,
    },
}

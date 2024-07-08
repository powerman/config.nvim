-- [[ A clean, dark Neovim theme, with support for lsp, treesitter and lots of plugins ]]
--
-- NOTE: Cmd `Telescope colorscheme` let you see installed colorschemes and change it.

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
        },
        config = function(_, opts)
            require('tokyonight').setup(opts)
            vim.cmd.colorscheme 'tokyonight'
        end,
    },
}

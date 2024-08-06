--[[ A clean, dark Neovim theme, with support for lsp, treesitter and lots of plugins ]]

-- NOTE:  Telescope colorscheme  Select colorscheme.

---@module 'lazy'
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
            ---@param hl tokyonight.Highlights
            ---@param c ColorScheme
            on_highlights = function(hl, c)
                -- Added in `mini.lua`.
                hl.MiniStatuslineLazyUpdates = {
                    fg = c.info,
                    bg = c.fg_gutter,
                }
                -- Markdown: `code inline`.
                hl['@markup.raw.markdown_inline'].fg = c.teal
                hl['@markup.raw.markdown_inline'].bg = 'NONE'
                -- Markdown: url.
                hl['@markup.link'].fg = c.purple
                hl['@markup.link.url.markdown_inline'] = '@markup.link'
                -- Markdown: emphasises.
                hl['@markup.strong'].fg = c.blue
                hl['@markup.italic'].fg = c.blue
                hl['@markup.strikethrough'].fg = c.fg_gutter
            end,
        },
        config = function(_, opts)
            require('tokyonight').setup(opts)
            vim.cmd.colorscheme 'tokyonight'
        end,
    },
}

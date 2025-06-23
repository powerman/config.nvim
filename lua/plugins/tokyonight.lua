--[[ A clean, dark Neovim theme, with support for lsp, treesitter and lots of plugins ]]

-- NOTE:  Telescope colorscheme   Select colorscheme.

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
            transparent = vim.g.transparent,
            styles = {
                sidebars = vim.g.transparent and 'transparent' or 'dark',
                floats = vim.g.transparent and 'transparent' or 'dark',
            },
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
                -- Window: separator.
                hl.WinSeparator.fg = c.dark3
                -- Diff:
                hl.DiffAdd.bg = '#2b3c3e'
                hl.DiffChange.bg = hl.DiffAdd.bg
                hl.DiffDelete.bg = '#472a36'
                hl.DiffText.bg = '#508050'
                -- Added in `gitsigns.lua`.
                hl.GitSignsAdd = { fg = c.green }
                hl.GitSignsChange = { fg = c.yellow }
                hl.GitSignsDelete = { fg = c.red }
                hl.GitSignsDeleteVirtLnInline = { bg = '#602020' }
                hl.GitSignsAddInline = { fg = hl.DiffText.bg, reverse = true }
                hl.GitSignsChangeInline = hl.GitSignsAddInline
                hl.GitSignsDeleteInline = hl.GitSignsAddInline
                -- Added in `codecompanion.lua`.
                hl.MiniDiffOverContext = { bg = hl.DiffDelete.bg }
                hl.MiniDiffOverContextBuf = { bg = hl.DiffAdd.bg }
                hl.MiniDiffOverChange = hl.GitSignsDeleteVirtLnInline
                hl.MiniDiffOverChangeBuf = { bg = hl.DiffText.bg }
                hl.MiniDiffSignAdd = hl.GitSignsAdd
                hl.MiniDiffSignChange = hl.GitSignsChange
                hl.MiniDiffSignDelete = hl.GitSignsDelete
            end,
        },
        config = function(_, opts)
            require('tokyonight').setup(opts)
            vim.cmd.colorscheme 'tokyonight'
        end,
    },
}

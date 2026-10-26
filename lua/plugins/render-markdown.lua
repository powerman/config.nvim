--[[ Plugin to improve viewing Markdown files ]]

local function todo_item(sign, icon)
    return {
        raw = '[' .. sign .. ']',
        rendered = icon,
        highlight = 'RenderMarkdownTodo',
        scope_highlight = nil,
    }
end

---@module 'lazy'
---@type LazySpec
return {
    'MeanderingProgrammer/render-markdown.nvim',
    version = '*',
    enabled = vim.g.have_nerd_font,
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
    ft = 'markdown',
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {
        completions = { lsp = { enabled = true } },
        latex = { enabled = false }, -- Just to disable warnings in :checkhealth.
        code = {
            sign = false, -- Useless duplication of language_icon=true.
            width = 'block', -- Just looks better to me.
            border = 'thick', -- Avoid line shift on switching to INSERT mode.
        },
        dash = {
            width = 0.8, -- Looks better when it's in the middle.
            left_margin = 0.5,
        },
        heading = {
            icons = { '☰' },
            signs = { '󰬺', '󰬻', '󰬼', '󰬽', '󰬾', '󰬿' },
        },
        checkbox = {
            right_pad = 0, -- 4 also looks okay, but default 1 isn't really good.
            custom = {
                in_progress = todo_item('/', '󰥔'),
                cancelled = todo_item('-', '󰜺'),
            },
        },
        html = {
            comment = {
                conceal = false,
            },
        },
    },
    config = function(_, opts)
        local util = require 'custom.util'
        -- util.adapt_nerd_font_propo(require('render-markdown.settings').callout.default)
        util.adapt_nerd_font_propo(require('render-markdown.settings').checkbox.default)
        util.adapt_nerd_font_propo(require('render-markdown.settings').heading.default)
        util.adapt_nerd_font_propo(require('render-markdown.settings').link.default)
        -- Default checkbox config has a custom item "[-] todo", but I use "[-] cancelled".
        require('render-markdown.settings').checkbox.default.custom.todo = nil

        require('render-markdown').setup(opts)
    end,
}

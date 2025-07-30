--[[ Plugin to improve viewing Markdown files ]]

local function todo_item(sign, icon)
    return {
        raw = '[' .. sign .. ']',
        rendered = icon,
        highlight = 'RenderMarkdownTodo',
        scope_highlight = nil,
    }
end

local function cc_header(name, icon)
    return {
        pattern = '^## ' .. name .. '$',
        icon = icon .. '  ',
        background = 'CodeCompanionInputHeader',
    }
end

local function cc_html_tag(icon)
    return {
        icon = icon,
        highlight = 'Comment',
    }
end

---@module 'lazy'
---@type LazySpec
return {
    'MeanderingProgrammer/render-markdown.nvim',
    version = '*',
    enabled = vim.g.have_nerd_font,
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
    ft = { 'markdown', 'codecompanion' },
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
        overrides = {
            filetype = {
                codecompanion = {
                    heading = {
                        custom = {
                            codecompanion_me = cc_header('Me', ''),
                            codecompanion_llm = cc_header('CodeCompanion', '󰚩'),
                            codecompanion_llm_anthropic = cc_header('Anthropic', '󰚩'),
                            codecompanion_llm_azure_openai = cc_header('Azure OpenAI', '󰚩'),
                            codecompanion_llm_copilot = cc_header('Copilot', ''),
                            codecompanion_llm_deepseek = cc_header('DeepSeek', '󰚩'),
                            codecompanion_llm_gemini = cc_header('Gemini', ''),
                            codecompanion_llm_githubmodels = cc_header('GitHub Models', '󰊤'),
                            codecompanion_llm_huggingface = cc_header('Hugging Face', '󰚩'),
                            codecompanion_llm_mistral = cc_header('Mistral', '󰚩'),
                            codecompanion_llm_novita = cc_header('Novita', '󰚩'),
                            codecompanion_llm_ollama = cc_header('Ollama', ''),
                            codecompanion_llm_openai = cc_header('OpenAI', '󰚩'),
                            codecompanion_llm_xai = cc_header('xAI', '󰚩'),
                        },
                    },
                    html = {
                        tag = {
                            buf = cc_html_tag '',
                            file = cc_html_tag '󰨸',
                            help = cc_html_tag '',
                            image = cc_html_tag '󰥶',
                            symbols = cc_html_tag '',
                            tool = cc_html_tag '',
                            url = cc_html_tag '󰌹',
                        },
                    },
                },
            },
        },
    },
    config = function(_, opts)
        local util = require 'custom.util'
        util.adapt_nerd_font_propo(require('render-markdown.config.callout').default)
        util.adapt_nerd_font_propo(require('render-markdown.config.checkbox').default)
        util.adapt_nerd_font_propo(require('render-markdown.config.heading').default)
        util.adapt_nerd_font_propo(require('render-markdown.config.link').default)
        -- Default checkbox config has a custom item "[-] todo", but I use "[-] cancelled".
        require('render-markdown.config.checkbox').default.custom.todo = nil

        require('render-markdown').setup(opts)
    end,
}

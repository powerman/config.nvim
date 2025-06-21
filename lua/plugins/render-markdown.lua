--[[ Plugin to improve viewing Markdown files ]]

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

        -- Compensate for Nerd Font Propo with 2-cell wide icons (no needs in extra space).
        heading = {
            -- icons = { '󰲡', '󰲣', '󰲥', '󰲧', '󰲩', '󰲫' },
            -- icons = { '󰬺', '󰬻', '󰬼', '󰬽', '󰬾', '󰬿' },
            icons = { '☰' },
            -- signs = { '󰫎' }, -- Also fix "too wide" sign error (extra space in default cfg).
            signs = { '󰬺', '󰬻', '󰬼', '󰬽', '󰬾', '󰬿' },
        },
        checkbox = {
            right_pad = 0, -- 4 also looks okay, but default 1 isn't really good.
            unchecked = {
                icon = '󰄱',
            },
            checked = {
                icon = '󰱒',
            },
            custom = {
                in_progress = {
                    raw = '[/]',
                    rendered = '󰥔',
                    highlight = 'RenderMarkdownTodo',
                    scope_highlight = nil,
                },
                cancelled = {
                    raw = '[-]',
                    rendered = '󰜺',
                    highlight = 'RenderMarkdownTodo',
                    scope_highlight = nil,
                },
            },
        },
        link = {
            image = '󰥶',
            email = '󰀓',
            hyperlink = '󰌹',
            wiki = { icon = '󱗖' },
            custom = {
                web = { icon = '󰖟' },
                discord = { icon = '󰙯' },
                github = { icon = '󰊤' },
                gitlab = { icon = '󰮠' },
                google = { icon = '󰊭' },
                neovim = { icon = '' },
                reddit = { icon = '󰑍' },
                stackoverflow = { icon = '󰓌' },
                wikipedia = { icon = '󰖬' },
                youtube = { icon = '󰗃' },
            },
        },

        overrides = {
            filetype = {
                codecompanion = {
                    heading = {
                        custom = {
                            codecompanion_me = {
                                pattern = '^## Me$',
                                icon = '  ',
                                background = 'CodeCompanionInputHeader',
                            },
                            codecompanion_llm = {
                                pattern = '^## CodeCompanion',
                                icon = '󰚩  ',
                                background = 'CodeCompanionInputHeader',
                            },
                            codecompanion_llm_anthropic = {
                                pattern = '^## Anthropic',
                                icon = '󰚩  ',
                                background = 'CodeCompanionInputHeader',
                            },
                            codecompanion_llm_azure_openai = {
                                pattern = '^## Azure OpenAI',
                                icon = '󰚩  ',
                                background = 'CodeCompanionInputHeader',
                            },
                            codecompanion_llm_copilot = {
                                pattern = '^## Copilot',
                                icon = '  ',
                                background = 'CodeCompanionInputHeader',
                            },
                            codecompanion_llm_deepseek = {
                                pattern = '^## DeepSeek',
                                icon = '󰚩  ',
                                background = 'CodeCompanionInputHeader',
                            },
                            codecompanion_llm_gemini = {
                                pattern = '^## Gemini',
                                icon = '  ',
                                background = 'CodeCompanionInputHeader',
                            },
                            codecompanion_llm_githubmodels = {
                                pattern = '^## GitHub Models',
                                icon = '󰊤  ',
                                background = 'CodeCompanionInputHeader',
                            },
                            codecompanion_llm_huggingface = {
                                pattern = '^## Hugging Face',
                                icon = '󰚩  ',
                                background = 'CodeCompanionInputHeader',
                            },
                            codecompanion_llm_mistral = {
                                pattern = '^## Mistral',
                                icon = '󰚩  ',
                                background = 'CodeCompanionInputHeader',
                            },
                            codecompanion_llm_novita = {
                                pattern = '^## Novita',
                                icon = '󰚩  ',
                                background = 'CodeCompanionInputHeader',
                            },
                            codecompanion_llm_ollama = {
                                pattern = '^## Ollama',
                                icon = '  ',
                                background = 'CodeCompanionInputHeader',
                            },
                            codecompanion_llm_openai = {
                                pattern = '^## OpenAI',
                                icon = '󰚩  ',
                                background = 'CodeCompanionInputHeader',
                            },
                            codecompanion_llm_tavily = {
                                pattern = '^## Tavily',
                                icon = '󰚩  ',
                                background = 'CodeCompanionInputHeader',
                            },
                            codecompanion_llm_xai = {
                                pattern = '^## xAI',
                                icon = '󰚩  ',
                                background = 'CodeCompanionInputHeader',
                            },
                        },
                    },
                    html = {
                        tag = {
                            buf = {
                                icon = '',
                                highlight = 'Comment',
                            },
                            file = {
                                icon = '󰨸',
                                highlight = 'Comment',
                            },
                            help = {
                                icon = '',
                                highlight = 'Comment',
                            },
                            image = {
                                icon = '󰥶',
                                highlight = 'Comment',
                            },
                            symbols = {
                                icon = '',
                                highlight = 'Comment',
                            },
                            tool = {
                                icon = '',
                                highlight = 'Comment',
                            },
                            url = {
                                icon = '󰌹',
                                highlight = 'Comment',
                            },
                        },
                    },
                },
            },
        },
    },
    config = function(_, opts)
        require('render-markdown.config.checkbox').default.custom.todo = nil
        require('render-markdown').setup(opts)
    end,
}

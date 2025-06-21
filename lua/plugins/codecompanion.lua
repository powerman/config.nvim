--[[ CodeCompanion is a productivity tool which streamlines how you develop with LLMs ]]

-- NOTE:  :CodeCompanion […]       Prompt inline AI assistant.
-- NOTE:  :CodeCompanion /<name>   Library prompt inline AI assistant.
-- NOTE:  :PasteImage   Add image from clipboard into Markdown.
-- NOTE:  :MCPHub       AI chat: manage @mcp tool.
-- NOTE:  <M-a>         Open AI actions.
-- NOTE:  <F6>          AI chat: toggle.
-- NOTE:  <C-CR>        AI chat: send.
-- NOTE:  <Leader>cr    AI chat: regenerate.
-- NOTE:  <C-C>         AI chat: stop.
-- NOTE:  <Leader>cx    AI chat: clear.
-- NOTE:  <Leader>cc    AI chat: codeblock.
-- NOTE:  <Leader>cp    AI chat: pin.
-- NOTE:  <Leader>cw    AI chat: watch.
-- NOTE:  <Leader>ca    AI chat: change adapter.
-- NOTE:  <Leader>cz    AI chat: fold code.
-- NOTE:  <Leader>cd    AI chat: debug.
-- NOTE:  ga            AI diff: accept.
-- NOTE:  gr            AI diff: reject.
-- NOTE:  <Leader>ch    AI chat history: manage.
-- NOTE:  <M-r>         AI chat history: rename.
-- NOTE:  <M-d>         AI chat history: delete.
-- NOTE:  <C-Y>         AI chat history: duplicate.

---@module 'lazy'
---@type LazySpec
return {
    -- Use mini.diff for a cleaner diff when using the inline assistant or
    -- the @insert_edit_into_file tool.
    {
        'echasnovski/mini.diff',
        version = '*',
        lazy = true, -- Will be loaded as codecompanion dependency.
        config = function()
            local diff = require 'mini.diff'
            diff.setup {
                -- Disabled by default
                source = diff.gen_source.none(),
                -- I'm using gitsigns, so disable these mappings to avoid conflict.
                -- Wiil use codecompanion's mappings `ga` for accept, 'gr' for reject.
                mappings = {
                    apply = '',
                    reset = '',
                    textobject = '',
                    goto_first = '',
                    goto_prev = '',
                    goto_next = '',
                    goto_last = '',
                },
            }
        end,
    },
    -- Copy images from your system clipboard into a chat buffer via :PasteImage.
    {
        'HakonHarnes/img-clip.nvim',
        version = '*',
        cmd = 'PasteImage',
        opts = {
            default = {
                dir_path = '/tmp',
            },
            filetypes = {
                codecompanion = {
                    prompt_for_file_name = false,
                    template = '[Image]($FILE_PATH)',
                    use_absolute_path = true,
                },
            },
        },
    },
    {
        'ravitemer/codecompanion-history.nvim', -- Save and load conversation history.
        cmd = { 'CodeCompanionHistory' },
        config = true,
    },
    -- A centralized manager for Model Context Protocol (MCP) servers with dynamic server
    -- management and monitoring.
    {
        'ravitemer/mcphub.nvim',
        version = '*',
        cmd = 'MCPHub',
        dependencies = {
            'nvim-lua/plenary.nvim',
        },
        -- build = 'npm install -g mcp-hub@latest', -- Binary `mcp-hub` is installed by Mise.
        config = true,
    },
    {
        'olimorris/codecompanion.nvim',
        version = '*',
        cond = vim.g.allow_remote_llm,
        cmd = { 'CodeCompanion', 'CodeCompanionChat', 'CodeCompanionActions' },
        keys = {
            {
                '<F6>',
                '<Cmd>CodeCompanionChat Toggle<CR>',
                mode = { 'n', 'v', 'i' },
                desc = 'Toggle AI Chat',
            },
            {
                '<M-a>',
                '<Cmd>CodeCompanionActions<CR>',
                mode = { 'n', 'v', 'i' },
                desc = 'Open AI Actions',
            },
        },
        dependencies = {
            'nvim-lua/plenary.nvim',
            'nvim-treesitter/nvim-treesitter',
            -- Optional:
            'ravitemer/codecompanion-history.nvim', -- Save and load conversation history.
            'ravitemer/mcphub.nvim', -- Manage MCP servers.
            'j-hui/fidget.nvim', -- Display status.
        },
        init = function()
            require('custom.codecompanion.fidget-spinner'):init()

            -- XXX: There is a bug somewhere: after LLM response the final part of markdown might
            -- not be processed by render-markdown plugin. So, trigger extra re-rendering.
            vim.api.nvim_create_autocmd({ 'User' }, {
                pattern = 'CodeCompanionRequestFinished',
                group = vim.api.nvim_create_augroup('user.cc_rerender_md', { clear = true }),
                callback = function(request)
                    vim.defer_fn(function()
                        vim.api.nvim_exec_autocmds(
                            'TextChanged',
                            { buffer = request.data.bufnr }
                        )
                    end, 300) -- Still race, of course, but mostly works.
                end,
            })
        end,
        opts = {
            strategies = {
                inline = {
                    adapter = {
                        name = 'copilot',
                        model = 'gpt-4.1', -- Multiplier = 0 (free).
                    },
                },
                chat = {
                    adapter = {
                        name = 'copilot',
                        -- https://docs.github.com/en/copilot/managing-copilot/understanding-and-managing-copilot-usage/understanding-and-managing-requests-in-copilot
                        model = 'gpt-4.1', -- Multiplier = 0 (free).
                        -- model = 'gemini-2.0-flash-001', -- Multiplier = 0.25.
                        -- model = 'o3-mini', -- Multiplier = 0.33.
                        -- model = 'o4-mini', -- Multiplier = 0.33.
                        -- model = 'gemini-2.5-pro', -- Multiplier = 1.
                        -- model = 'claude-3.5-sonnet', -- Multiplier = 1.
                        -- model = 'claude-3.7-sonnet', -- Multiplier = 1.
                        -- model = 'claude-sonnet-4', -- Multiplier = 1.
                        -- model = 'claude-3.7-sonnet-thought', -- Multiplier = 1.25.
                        -- model = 'o1', -- Multiplier = 10.
                    },
                    roles = {
                        ---@type string|fun(adapter: CodeCompanion.Adapter): string
                        llm = function(adapter)
                            return (adapter.formatted_name or adapter.name)
                                .. (adapter.model and ' (' .. adapter.model.name .. ')' or '')
                        end,
                    },
                    tools = {
                        groups = {
                            dev = { -- full_stack_dev + mcp
                                description = 'Real Developer - Can do everything a real dev can do',
                                tools = {
                                    'cmd_runner',
                                    'create_file',
                                    'file_search',
                                    'grep_search',
                                    'insert_edit_into_file',
                                    -- 'read_file', -- Returned error confuses GPT-4.1.
                                    'web_search',
                                    -- 'mcp' -- This one will be added later, in config().
                                },
                                opts = {
                                    collapse_tools = true,
                                },
                            },
                        },
                    },
                    keymaps = {
                        send = {
                            modes = { n = '<C-CR>', i = '<C-CR>' },
                        },
                        regenerate = {
                            modes = { n = '<Leader>cr' },
                        },
                        close = {
                            modes = { n = 'q' },
                        },
                        stop = {
                            modes = { n = '<C-C>', i = '<C-C>' },
                        },
                        clear = {
                            modes = { n = '<Leader>cx' },
                        },
                        codeblock = {
                            modes = { n = '<Leader>cc' },
                        },
                        pin = {
                            modes = { n = '<Leader>cp' },
                        },
                        watch = {
                            modes = { n = '<Leader>cw' },
                        },
                        change_adapter = {
                            modes = { n = '<Leader>ca' },
                        },
                        fold_code = {
                            modes = { n = '<Leader>cz' },
                        },
                        debug = {
                            modes = { n = '<Leader>cd' },
                        },
                        system_prompt = {
                            modes = { n = '<Leader>cs' },
                        },
                        auto_tool_mode = {
                            modes = { n = '<Leader>ct' },
                        },
                        goto_file_under_cursor = {
                            modes = { n = 'gf' },
                        },
                    },
                },
            },
            display = {
                chat = {
                    icons = {
                        pinned_buffer = '',
                        watched_buffer = '󰂥',
                    },
                    window = {
                        width = 0.66,
                    },
                    -- start_in_insert_mode = true,
                },
                diff = {
                    provider = 'mini_diff',
                },
                icons = {
                    loading = '',
                    warning = '',
                },
            },
            extensions = {
                history = {
                    enabled = true,
                    opts = {
                        keymap = '<Leader>ch',
                        save_chat_keymap = nil,
                        expiration_days = 30,
                        auto_generate_title = true,
                        title_generation_opts = {
                            -- This one is free on my Copilot Pro plan.
                            adapter = 'copilot',
                            model = 'gpt-4.1',
                            refresh_every_n_prompts = 0, -- e.g., 3 to refresh after every 3rd user prompt
                        },
                        -- Show chats only from the current project.
                        chat_filter = function(chat_data)
                            return chat_data.cwd == vim.fn.getcwd()
                        end,
                    },
                },
                mcphub = {
                    callback = 'mcphub.extensions.codecompanion',
                    opts = {
                        show_result_in_chat = true, -- Show mcp tool results in chat.
                        make_vars = true, -- Convert resources to #variables.
                        make_slash_commands = true, -- Add prompts as /slash commands.
                    },
                },
            },
            adapters = {
                ollama = function()
                    return require('codecompanion.adapters').extend('ollama', {
                        schema = {
                            model = {
                                default = 'qwen3:8b',
                            },
                            num_ctx = {
                                default = 20000, -- Used by CodeCompanion author, no idea why.
                            },
                        },
                    })
                end,
                ollama_qwen_3 = function()
                    return require('codecompanion.adapters').extend('ollama', {
                        schema = {
                            model = {
                                default = 'qwen3:8b',
                                choices = {},
                            },
                            num_ctx = {
                                default = 40960,
                            },
                        },
                    })
                end,
                ollama_qwen_2_5_coder = function()
                    return require('codecompanion.adapters').extend('ollama', {
                        schema = {
                            model = {
                                default = 'qwen2.5-coder:7b',
                                choices = { 'qwen2.5-coder:7b', 'qwen2.5-coder:14b' },
                            },
                            num_ctx = {
                                default = 32768,
                            },
                        },
                    })
                end,
                ollama_llama_3_1 = function()
                    return require('codecompanion.adapters').extend('ollama', {
                        schema = {
                            model = {
                                default = 'llama3.1:8b',
                                choices = {},
                            },
                            num_ctx = {
                                default = 131072,
                            },
                        },
                    })
                end,
            },
            opts = {
                language = 'Russian', -- The language used for LLM responses.
                log_level = 'ERROR', -- TRACE|DEBUG|ERROR|INFO
            },
        },
        config = function(_, opts)
            require('codecompanion').setup(opts)
            require('custom.codecompanion.requires_approval').setup {
                allowed_cmds = vim.g.llm_allowed_cmds or {},
            }

            local config = require 'codecompanion.config'
            local tools = config.config.strategies.chat.tools

            -- Change this workflow to not touch vim.g.codecompanion_auto_tool_mode.
            local orig_mode = vim.g.codecompanion_auto_tool_mode
            ---@type function|string
            config.config.prompt_library['Edit<->Test workflow'].prompts[1][1].content =
                config.config.prompt_library['Edit<->Test workflow'].prompts[1][1].content()
            vim.g.codecompanion_auto_tool_mode = orig_mode

            -- To include @mcp in your own @dev group, it's not enough to just add a couple of
            -- tools from the @mcp group. You also need to set the system_prompt, which can't
            -- be done in opts — so we have to do it here.
            for _, tool in ipairs(tools.groups.mcp.tools) do
                table.insert(tools.groups.dev.tools, tool)
            end
            tools.groups.dev.system_prompt = tools.groups.mcp.system_prompt
        end,
    },
}

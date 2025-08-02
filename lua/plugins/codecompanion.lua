--[[ CodeCompanion is a productivity tool which streamlines how you develop with LLMs ]]

-- NOTE:  :CodeCompanion […]       Prompt inline AI assistant.
-- NOTE:  :CodeCompanion /<name>   Library prompt inline AI assistant.
-- NOTE:  :PasteImage   Add image from clipboard into Markdown.
-- NOTE:  :MCPHub       AI chat: manage @mcp tool.
-- NOTE:  <M-a>         AI Action Palette.
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
-- NOTE:  <Leader>da    AI diff: accept.
-- NOTE:  <Leader>dr    AI diff: reject.
-- NOTE:  <M-r>         AI chat history: rename.
-- NOTE:  <M-d>         AI chat history: delete.
-- NOTE:  <C-Y>         AI chat history: duplicate.

local prompt = require 'custom.codecompanion.prompt'

local function chat_filter(chat_data)
    return vim.g.project_root == chat_data.project_root or vim.g.project_root == chat_data.cwd
end

---@module 'lazy'
---@type LazySpec
return {
    {
        'custom.codecompanion.auto_approve',
        dir = '~/.config/nvim/lua',
        lazy = true, -- Will be loaded as a dependency of other plugins.
        main = 'custom.codecompanion.auto_approve',
        opts = {
            allowed_cmds = vim.g.llm_allowed_cmds or {},
            secret_files = vim.g.llm_secret_files,
            project_root = vim.g.project_root,
        },
    },
    -- Use mini.diff for a cleaner diff when using the inline assistant or
    -- the @insert_edit_into_file tool.
    {
        'echasnovski/mini.diff',
        version = '*',
        config = function()
            local diff = require 'mini.diff'
            diff.setup {
                -- Disabled by default
                source = diff.gen_source.none(),
                -- Use same signs as gitsigns.
                view = {
                    signs = { add = '┃', change = '┃', delete = '_' },
                },
                -- I'm using gitsigns, so disable these mappings to avoid conflict.
                -- Will use codecompanion's mappings for accept|reject.
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
            -- Use mini.diff overlay by default.
            vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
                desc = 'Enable mini.diff overlay by default',
                group = vim.api.nvim_create_augroup('user.mini_diff_overlay', { clear = true }),
                pattern = '*',
                callback = function(ev)
                    if
                        not vim.bo.readonly
                        and ev.file ~= 'quickfix'
                        and vim.bo.ft ~= 'qf'
                        and not vim.wo.diff
                        and vim.bo.ft ~= 'diff'
                    then
                        vim.schedule(function()
                            MiniDiff.enable(ev.buf)
                            MiniDiff.toggle_overlay(ev.buf)
                        end)
                    end
                end,
            })
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
        cmd = { 'CodeCompanionHistory', 'CodeCompanionSummaries' },
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
            'custom.codecompanion.auto_approve',
        },
        -- build = 'npm install -g mcp-hub@latest', -- Binary `mcp-hub` is installed by Mise.
        config = function()
            -- Try to avoid sharing mcp-hub instance between directories.
            local cwd_hash = string.sub(vim.fn.sha256(vim.fn.getcwd()), 1, 4)
            ---@diagnostic disable-next-line: missing-fields
            require('mcphub').setup {
                global_env = {
                    'XDG_CACHE_HOME',
                },
                workspace = {
                    enabled = false,
                    port_range = { min = 13000, max = 13999 },
                },
                port = 13000 + tonumber(cwd_hash, 16) % 1000, -- Use ports 13000-13999.
                auto_approve = require('custom.codecompanion.auto_approve').mcphub,
                auto_toggle_mcp_servers = false, -- I consider it a security risk.
            }
        end,
    },
    {
        'olimorris/codecompanion.nvim',
        version = '*',
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
            'custom.codecompanion.auto_approve',
            'ravitemer/codecompanion-history.nvim', -- Save and load conversation history.
            'ravitemer/mcphub.nvim', -- Manage MCP servers.
            'j-hui/fidget.nvim', -- Display status.
            'franco-ruggeri/codecompanion-spinner.nvim',
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
                        model = 'gpt-4o', -- Multiplier = 0 (free).
                        -- model = 'claude-3.5-sonnet', -- Multiplier = 1.
                    },
                    keymaps = {
                        accept_change = {
                            modes = { n = '<Leader>da' },
                        },
                        reject_change = {
                            modes = { n = '<Leader>dr' },
                        },
                    },
                },
                chat = {
                    adapter = {
                        name = 'copilot',
                        -- https://docs.github.com/en/copilot/managing-copilot/understanding-and-managing-copilot-usage/understanding-and-managing-requests-in-copilot
                        -- model = 'gpt-4.1', -- Multiplier = 0 (free).
                        -- model = 'gpt-4o', -- Multiplier = 0 (free).
                        -- model = 'gemini-2.0-flash-001', -- Multiplier = 0.25.
                        -- model = 'o4-mini', -- Multiplier = 0.33.
                        -- model = 'gemini-2.5-pro', -- Multiplier = 1.
                        model = 'claude-3.5-sonnet', -- Multiplier = 1.
                        -- model = 'claude-3.7-sonnet', -- Multiplier = 1.
                        -- model = 'claude-sonnet-4', -- Multiplier = 1.
                        -- model = 'claude-3.7-sonnet-thought', -- Multiplier = 1.25.
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
                            ['agent'] = {
                                description = 'Agent tools',
                                tools = {
                                    'context7__get-library-docs',
                                    'context7__resolve-library-id',
                                    'filesystem__create_directory',
                                    'filesystem__edit_file',
                                    'filesystem__get_file_info',
                                    'filesystem__list_allowed_directories',
                                    'filesystem__list_directory',
                                    'filesystem__list_directory_with_sizes',
                                    'filesystem__move_file',
                                    'filesystem__read_file',
                                    'filesystem__read_multiple_files',
                                    'filesystem__search_files',
                                    'filesystem__write_file',
                                    'git__git_branch',
                                    'git__git_diff',
                                    'git__git_diff_staged',
                                    'git__git_diff_unstaged',
                                    'git__git_init',
                                    'git__git_log',
                                    'git__git_show',
                                    'git__git_status',
                                    'shell__shell_exec',
                                    'tavily-mcp__tavily-crawl',
                                    'tavily-mcp__tavily-extract',
                                    'tavily-mcp__tavily-map',
                                    'tavily-mcp__tavily-search',
                                },
                                opts = {
                                    collapse_tools = true,
                                },
                            },
                        },
                        opts = {
                            --- This is needed when using CodeCompanion's internal tools
                            --- (e.g., when @cmd_runner runs tests and they fail),
                            --- but with external tools (e.g., @mcp) this might cause issues
                            --- because external tools do not return errors in such cases
                            --- but may return errors in case of real internal errors
                            --- that should be handled by a human, not an LLM.
                            auto_submit_errors = true,
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
                            modes = { n = '<Leader>cts' },
                        },
                        auto_tool_mode = {
                            modes = { n = '<Leader>cta' },
                        },
                        goto_file_under_cursor = {
                            modes = { n = 'gf' },
                        },
                        copilot_stats = {
                            modes = { n = '<Leader>cS' },
                        },
                    },
                },
            },
            display = {
                chat = {
                    window = {
                        width = 0.66,
                    },
                    start_in_insert_mode = true,
                },
                diff = {
                    provider = 'mini_diff',
                },
            },
            extensions = {
                spinner = {},
                history = {
                    enabled = true,
                    opts = {
                        keymap = {}, -- Use Action Palette to open.
                        save_chat_keymap = {}, -- Use autosave.
                        expiration_days = 30,
                        auto_generate_title = true,
                        title_generation_opts = vim.tbl_extend('force', {
                            refresh_every_n_prompts = 0, -- e.g., 3 to refresh after every 3rd user prompt
                        }, (vim.g.allow_remote_llm and {
                            -- This one is free on my Copilot Pro plan.
                            adapter = 'copilot',
                            model = 'gpt-4o',
                        } or {
                            -- Use current model for Ollama.
                        })),
                        -- Show chats only from the current project.
                        chat_filter = chat_filter,
                        summary = {
                            create_summary_keymap = '<Leader>csc',
                            browse_summaries_keymap = '<Leader>csb',
                        },
                    },
                },
                mcphub = {
                    callback = 'mcphub.extensions.codecompanion',
                    opts = {
                        make_tools = true, -- Make individual tools (@server__tool) and server groups (@server) from MCP servers.
                        show_server_tools_in_chat = false, -- Show individual tools in chat completion (when make_tools=true).
                        add_mcp_prefix_to_tool_names = false, -- Add mcp__ prefix (e.g `@mcp__github`, `@mcp__neovim__list_issues`).
                        show_result_in_chat = false, -- Show mcp tool results in chat.
                        make_vars = true, -- Convert resources to #variables.
                        make_slash_commands = true, -- Add prompts as /slash commands.
                        format_tool = function(name, tool)
                            local args = vim.deepcopy(tool.args)
                            if name == 'use_mcp_tool' then
                                name = string.format('%s__%s', args.server_name, args.tool_name)
                                args = args.tool_input
                            end

                            if name == 'filesystem__edit_file' then
                                if type(args.edits) == 'table' then
                                    args.edits = '󰩫'
                                end
                            elseif name == 'filesystem__write_file' then
                                if type(args.content) == 'string' then
                                    args.content = '󰩫'
                                end
                            end

                            return name .. ' ' .. vim.inspect(args):gsub('%s+', ' ')
                        end,
                    },
                },
            },
            adapters = {
                -- Set default model for Ollama.
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
            prompt_library = {
                --- Reserve index intervals:
                ---     - 1-9       System (Chat, Open chats, Custom Prompt, Saved Chats, etc.)
                ---     - 100-199   User Inline Prompts
                ---     - 200-299   User Chat Prompts
                ---     - 300-399   User Workflows
                ['Unit Tests'] = { opts = { index = 150 } },
                ['Fix code'] = { opts = { index = 250 } },
                ['Explain LSP Diagnostics'] = { opts = { index = 251 } },
                ['Explain'] = { opts = { index = 252 } },
                ['Generate a Commit Message'] = { opts = { index = 253 } },
                ['Workspace File'] = { opts = { index = 254 } },
                ['Code workflow'] = { opts = { index = 350 } },
                ['Edit<->Test workflow'] = { opts = { index = 351 } },

                ['Saved Project Chats ...'] = {
                    strategy = 'chat',
                    description = 'Browse saved project chats',
                    opts = {
                        index = 4,
                        stop_context_insertion = true,
                    },
                    condition = function()
                        local history = require('codecompanion').extensions.history
                        local have_chats = not vim.tbl_isempty(history.get_chats(chat_filter))
                        local mode = vim.api.nvim_get_mode()
                        return have_chats and (mode.mode == 'n' or mode.mode == 'i')
                    end,
                    prompts = {
                        n = function()
                            local history = require('codecompanion').extensions.history
                            history.browse_chats(chat_filter)
                        end,
                        i = function()
                            local history = require('codecompanion').extensions.history
                            history.browse_chats(chat_filter)
                        end,
                    },
                },
                ['Saved Chats ...'] = {
                    strategy = 'chat',
                    description = 'Browse all saved chats',
                    opts = {
                        index = 5,
                        stop_context_insertion = true,
                    },
                    condition = function()
                        local history = require('codecompanion').extensions.history
                        local have_chats = not vim.tbl_isempty(history.get_chats())
                        local mode = vim.api.nvim_get_mode()
                        return have_chats and (mode.mode == 'n' or mode.mode == 'i')
                    end,
                    prompts = {
                        n = function()
                            local history = require('codecompanion').extensions.history
                            history.browse_chats()
                        end,
                        i = function()
                            local history = require('codecompanion').extensions.history
                            history.browse_chats()
                        end,
                    },
                },
                ['Agent'] = {
                    strategy = 'chat',
                    description = 'Create a new chat buffer in Agent mode',
                    condition = function()
                        return vim.g.allow_remote_llm
                    end,
                    opts = {
                        index = 6,
                        stop_context_insertion = true,
                        adapter = {
                            name = 'copilot',
                            model = 'claude-sonnet-4', -- Multiplier = 1.
                        },
                    },
                    prompts = {
                        {
                            role = prompt.USER_ROLE,
                            content = '#{mcp:neovim://workspace} @{agent}',
                        },
                        {
                            role = prompt.USER_ROLE,
                            content = '',
                        },
                    },
                },
                ['Free Agent (GPT-4o)'] = {
                    strategy = 'chat',
                    description = 'Create a new chat buffer in Agent mode with GPT-4o',
                    condition = function()
                        return vim.g.allow_remote_llm
                    end,
                    opts = {
                        index = 7,
                        stop_context_insertion = true,
                        adapter = {
                            name = 'copilot',
                            model = 'gpt-4o', -- Multiplier = 0 (free).
                        },
                    },
                    prompts = {
                        {
                            role = prompt.USER_ROLE,
                            content = '#{mcp:neovim://workspace} @{agent}',
                        },
                        {
                            role = prompt.USER_ROLE,
                            content = '',
                        },
                    },
                },
                ['Improve grammar'] = {
                    strategy = 'inline',
                    description = 'Improve grammar in the selected text',
                    opts = {
                        index = 100,
                        adapter = {
                            name = 'ollama_qwen_3',
                        },
                        modes = { 'v' },
                        short_name = 'grammar',
                        user_prompt = false,
                        placement = 'replace',
                        stop_context_insertion = true,
                    },
                    prompts = {
                        {
                            role = prompt.SYSTEM_ROLE,
                            content = prompt.inline.improve_grammar,
                        },
                        {
                            role = prompt.USER_ROLE,
                            content = prompt.inline.selected_text,
                            opts = {
                                contains_code = true,
                            },
                        },
                    },
                },
                ['Translate [екфты]'] = {
                    strategy = 'chat',
                    description = 'Translate text into another language',
                    opts = {
                        index = 200,
                        adapter = {
                            name = 'ollama_qwen_3',
                        },
                        is_slash_cmd = false,
                        modes = { 'i', 'n', 'v' },
                        short_name = 'translate',
                        auto_submit = false,
                        ignore_system_prompt = true,
                        stop_context_insertion = false,
                        -- user_prompt = false,
                    },
                    prompts = {
                        {
                            role = prompt.SYSTEM_ROLE,
                            content = prompt.chat.translate,
                        },
                        {
                            role = prompt.USER_ROLE,
                            content = '',
                        },
                    },
                },
            },
            opts = {
                language = 'Russian', -- The language used for LLM responses.
                log_level = 'ERROR', -- TRACE|DEBUG|ERROR|INFO
                system_prompt = prompt.chat.copilot_instructions,
            },
        },
        config = function(_, opts)
            require('codecompanion').setup(opts)
            require('custom.codecompanion.auto_approve').setup_codecompanion()

            local config = require 'codecompanion.config'

            local util = require 'custom.util'
            util.adapt_nerd_font_propo(config.config)

            if not vim.g.allow_remote_llm then
                -- Forbid loading remote LLM adapters.
                local orig_require = require
                require = function(name)
                    if
                        name:match '^codecompanion.adapters.'
                        and not name:match '^codecompanion.adapters.ollama'
                        and name ~= 'codecompanion.adapters.jina' -- Non-LLM adapter.
                        and name ~= 'codecompanion.adapters.tavily' -- Non-LLM adapter.
                    then
                        local info = debug.getinfo(2, 'S')
                        if
                            not info
                            or not (
                                info.source:match 'ollama' -- ollama adapter loads openai.
                                or info.source:match 'plugins/codecompanion' -- this file.
                            )
                        then
                            vim.print('Loading remote LLM adapters is forbidden: ' .. name)
                            return nil
                        end
                    end
                    return orig_require(name)
                end

                -- Remove all non-ollama adapters.
                for key, adapter in pairs(config.config.adapters) do
                    if key == 'opts' or key == 'jina' or key == 'tavily' then -- Skip non-LLMs.
                        goto continue
                    end

                    if type(adapter) == 'function' then
                        adapter = adapter()
                    end
                    if type(adapter) == 'table' then
                        adapter = adapter.name
                    end
                    if type(adapter) ~= 'string' or adapter ~= 'ollama' then
                        config.config.adapters[key] = nil
                    end

                    ::continue::
                end

                -- Use ollama as the default adapter for all strategies.
                config.config.strategies.chat.adapter = 'ollama'
                config.config.strategies.inline.adapter = 'ollama'
                config.config.strategies.cmd.adapter = 'ollama'

                -- Use ollama as the default adapter for all prompts.
                for _, p in pairs(config.config.prompt_library) do
                    if type(p) == 'table' and p.opts and p.opts.adapter then
                        local adapter = p.opts.adapter
                        if
                            not (type(adapter) == 'string' and adapter:find 'ollama')
                            and not (type(adapter) == 'table' and adapter.name:find 'ollama')
                        then
                            p.opts.adapter = 'ollama'
                        end
                    end
                end
            end

            -- Change this workflow to not touch vim.g.codecompanion_auto_tool_mode.
            local orig_mode = vim.g.codecompanion_auto_tool_mode
            ---@type function|string
            config.config.prompt_library['Edit<->Test workflow'].prompts[1][1].content =
                config.config.prompt_library['Edit<->Test workflow'].prompts[1][1].content()
            vim.g.codecompanion_auto_tool_mode = orig_mode

            -- Fix default chat when opened from INSERT mode.
            local static_actions = require 'codecompanion.actions.static'
            static_actions[1].prompts.i = static_actions[1].prompts.n

            vim.api.nvim_create_autocmd('WinLeave', {
                desc = 'Reload buffers when leaving CodeCompanion Chat window',
                pattern = '*',
                group = vim.api.nvim_create_augroup('user.cc_checktime', { clear = true }),
                callback = function()
                    if vim.bo.filetype == 'codecompanion' then
                        vim.cmd 'checktime'
                    end
                end,
            })

            -- Use select_tab action in slash commands.
            local Telescope = require 'codecompanion.providers.slash_commands.telescope'
            local orig_display = Telescope.display
            function Telescope:display()
                local f = orig_display(self)
                return function()
                    local actions = require 'telescope.actions'
                    local orig_select_default = actions.select_default
                    actions.select_default = actions.select_tab
                    local res = f()
                    actions.select_default = orig_select_default
                    return res
                end
            end

            local notifier = require('custom.sound_notifier').new(vim.g.llm_message_sound)
            vim.api.nvim_create_autocmd('User', {
                group = notifier.augroup,
                pattern = { 'CodeCompanionChatDone', 'CodeCompanionInlineFinished' },
                callback = notifier:notify_callback(),
            })
        end,
    },
}

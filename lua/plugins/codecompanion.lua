--[[ CodeCompanion is a productivity tool which streamlines how you develop with LLMs ]]
-- Disabled in non-IDE mode (e.g. root user on servers).
if not vim.g.ide then
    return {}
end

-- NOTE:  :CodeCompanion […]       Prompt inline AI assistant.
-- NOTE:  :CodeCompanion /<name>   Library prompt inline AI assistant.
-- NOTE:  :PasteImage   Add image from clipboard into Markdown.
-- NOTE:  :MCPHub       AI chat: manage @mcp tool.
-- NOTE:  <M-a>         AI Action Palette.
-- NOTE:  <F6>          AI chat: toggle.
-- NOTE:  <C-CR>        AI chat: send.
-- NOTE:  <C-C>         AI chat/inline: stop.
-- NOTE:  <Leader>cr    AI chat: regenerate.
-- NOTE:  <Leader>cx    AI chat: clear.
-- NOTE:  <Leader>cc    AI chat: codeblock.
-- NOTE:  <Leader>ctf   AI chat: buffer sync all.
-- NOTE:  <Leader>ctd   AI chat: buffer sync diff.
-- NOTE:  <Leader>ca    AI chat: change adapter.
-- NOTE:  <Leader>cz    AI chat: fold code.
-- NOTE:  <Leader>cd    AI chat: debug.
-- NOTE:  <Leader>dA    AI diff: always accept.
-- NOTE:  <Leader>da    AI diff: accept.
-- NOTE:  <Leader>dr    AI diff: reject.
-- NOTE:  <M-r>         AI chat history: rename.
-- NOTE:  <M-d>         AI chat history: delete.
-- NOTE:  <C-Y>         AI chat history: duplicate.

local prompt = require 'custom.codecompanion.prompt'

---@module 'codecompanion._extensions.history.types'

---@param chat_data CodeCompanion.History.ChatIndexData
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
    {
        'powerman/copilot-prompt.nvim',
        version = '*',
        lazy = true,
    },
    {
        'powerman/sound-notifier.nvim',
        version = '*',
        lazy = true,
        opts = {},
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
        -- version = '*', -- TODO: Re-enable after next release.
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
        cmd = {
            'CodeCompanion',
            'CodeCompanionChat',
            'CodeCompanionActions',
            'CodeCompanionCmd',
        },
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
            'franco-ruggeri/codecompanion-spinner.nvim', -- Inline spinner in chat.
            'powerman/copilot-prompt.nvim',
            'powerman/sound-notifier.nvim',
        },
        opts = {
            interactions = {
                shared = {
                    keymaps = {
                        always_accept = {
                            modes = { n = '<Leader>dA' },
                        },
                        accept_change = {
                            modes = { n = '<Leader>da' },
                        },
                        reject_change = {
                            modes = { n = '<Leader>dr' },
                        },
                    },
                },
                background = {
                    adapter = {
                        name = 'copilot',
                        model = 'gpt-4.1', -- Multiplier = 0 (free).
                    },
                },
                cmd = {
                    adapter = {
                        name = 'copilot',
                        -- model = 'claude-sonnet-4.6', -- Multiplier = 1.
                        model = 'gpt-4.1', -- Multiplier = 0 (free).
                    },
                },
                inline = {
                    adapter = {
                        name = 'copilot',
                        -- model = 'claude-sonnet-4.6', -- Multiplier = 1.
                        model = 'gpt-4.1', -- Multiplier = 0 (free).
                    },
                    keymaps = {
                        stop = {
                            modes = { n = '<C-C>' },
                        },
                    },
                },
                chat = {
                    opts = {
                        completion_provider = 'cmp',
                        system_prompt = prompt.default_system_prompt,
                    },
                    adapter = {
                        name = 'copilot',
                        -- https://docs.github.com/ru/copilot/concepts/billing/copilot-requests#model-multipliers
                        -- model = 'claude-haiku-4.5', -- Multiplier = 0.33.
                        -- model = 'claude-opus-4.5', -- Multiplier = 3.
                        -- model = 'claude-opus-4.6', -- Multiplier = 3.
                        -- model = 'claude-sonnet-4', -- Multiplier = 1.
                        -- model = 'claude-sonnet-4.5',  -- Multiplier = 1.
                        -- model = 'claude-sonnet-4.6', -- Multiplier = 1.
                        -- model = 'gemini-2.5-pro', -- Multiplier = 1.
                        -- model = 'gemini-3-flash-preview', -- Multiplier = 0.33.
                        -- model = 'gemini-3-pro-preview', -- Multiplier = 1.
                        -- model = 'gemini-3.1-pro-preview', -- Multiplier = 1.
                        model = 'gpt-4.1', -- Multiplier = 0 (free).
                        -- model = 'gpt-4o', -- Multiplier = 0 (free).
                        -- model = 'gpt-5-mini', -- Multiplier = 0 (free).
                        -- model = 'gpt-5.1', -- Multiplier = 1.
                        -- model = 'gpt-5.1-codex', -- Multiplier = 1.
                        -- model = 'gpt-5.1-codex-max', -- Multiplier = 1.
                        -- model = 'gpt-5.1-codex-mini', -- Multiplier = 0.33.
                        -- model = 'gpt-5.2', -- Multiplier = 1.
                        -- model = 'gpt-5.2-codex', -- Multiplier = 1.
                        -- model = 'gpt-5.3-codex', -- Multiplier = 1.
                        -- model = 'grok-code-fast-1', -- Multiplier = 0.25.
                        -- model = 'oswe-vscode-prime', -- Multiplier = 0 (free). Raptor mini.
                    },
                    roles = {
                        ---The header name for the LLM's messages
                        ---@type string|fun(adapter: CodeCompanion.HTTPAdapter|CodeCompanion.ACPAdapter): string
                        llm = function(adapter)
                            return (adapter.formatted_name or adapter.name)
                                .. (adapter.model and ' (' .. adapter.model.name .. ')' or '')
                        end,
                    },
                    tools = {
                        opts = {
                            system_prompt = {
                                enabled = true,
                                replace_main_system_prompt = true,
                                prompt = prompt.tool_system_prompt,
                            },
                        },
                        ['grep_search'] = {
                            opts = {
                                require_approval_before = false,
                            },
                        },
                        ['memory'] = {
                            opts = {
                                require_approval_before = false,
                            },
                        },
                        groups = {
                            ['mcp_agent'] = {
                                description = 'Agent tools from MCP servers',
                                tools = {
                                    'memory',
                                    --- Editor tools.
                                    'get_diagnostics',
                                    --- Web search and browsing tools.
                                    'web_search',
                                    'fetch_webpage',
                                    'context7__get-library-docs',
                                    'context7__resolve-library-id',
                                    'tavily-mcp__tavily-crawl',
                                    'tavily-mcp__tavily-extract',
                                    'tavily-mcp__tavily-map',
                                    'tavily-mcp__tavily-search',
                                    --- File analysis tools.
                                    'grep_search',
                                    'filesystem__get_file_info',
                                    'filesystem__list_allowed_directories',
                                    'filesystem__list_directory',
                                    'filesystem__list_directory_with_sizes',
                                    'filesystem__read_file',
                                    'filesystem__read_multiple_files',
                                    'filesystem__search_files',
                                    --- File modification tools.
                                    'filesystem__create_directory',
                                    'filesystem__edit_file',
                                    'filesystem__move_file',
                                    'filesystem__write_file',
                                    --- Shell tools.
                                    'shell__shell_exec',
                                    --- Git tools.
                                    'git__git_branch',
                                    'git__git_diff',
                                    'git__git_diff_staged',
                                    'git__git_diff_unstaged',
                                    'git__git_init',
                                    'git__git_log',
                                    'git__git_show',
                                    'git__git_status',
                                },
                                opts = {
                                    collapse_tools = true,
                                    ignore_tool_system_prompt = false,
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
                            modes = { n = 'q', i = {} },
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
                        yank_code = {
                            modes = { n = '<Leader>cy' },
                        },
                        buffer_sync_all = {
                            modes = { n = '<Leader>ctf' },
                        },
                        buffer_sync_diff = {
                            modes = { n = '<Leader>ctd' },
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
                        rules = {
                            modes = { n = '<Leader>cX' },
                        },
                        clear_approvals = {
                            modes = { n = '<Leader>cA' },
                        },
                        yolo_mode = {
                            modes = { n = '<Leader>cty' },
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
                        width = 0.66, -- For layout = 'vertical'.
                        layout = 'tab',
                    },
                    start_in_insert_mode = true,
                },
                action_palette = {
                    opts = {
                        -- To use only a subset of preset prompts copy them to prompts/.
                        show_preset_prompts = false,
                    },
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
                            adapter = 'copilot',
                            model = 'gpt-4.1', -- Multiplier = 0 (free).
                        } or {
                            -- Use current model for Ollama.
                        })),
                        summary = {
                            create_summary_keymap = '<Leader>csc',
                            browse_summaries_keymap = '<Leader>csb',
                            generation_opts = vim.tbl_extend('force', {
                                --
                            }, (vim.g.allow_remote_llm and {
                                adapter = 'copilot',
                                model = 'gpt-4.1', -- Multiplier = 0 (free).
                            } or {
                                -- Use current model for Ollama.
                            })),
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
                http = {
                    -- Set default model for Ollama.
                    ollama = function()
                        return require('codecompanion.adapters').extend('ollama', {
                            schema = {
                                model = {
                                    default = 'qwen3:4b',
                                },
                                num_ctx = {
                                    --- qwen3 uses extra 1GB per 4k context.
                                    --- It's default is 4k (qwen3:4b=4.1GB, qwen3:8b=6.5GB).
                                    -- default = 16384,
                                },
                            },
                        })
                    end,
                },
            },
            prompt_library = {
                markdown = {
                    dirs = {
                        vim.fn.stdpath 'config' .. '/codecompanion/prompts',
                        '~/.config/codecompanion/prompts',
                        vim.g.project_root .. '/.codecompanion/prompts',
                    },
                },
                ['Saved Project Chats ...'] = prompt.library.saved_chats(chat_filter),
                ['Saved Chats ...'] = prompt.library.saved_chats(),
                ['Agent GPT-4.1 (free)'] = prompt.library.mcp_agent 'gpt-4.1', -- Multiplier = 0 (free).
                ['Agent Sonnet 4.6'] = prompt.library.mcp_agent 'claude-sonnet-4.6', -- Multiplier = 1.
                ['Agent Gemini 3.1 Pro'] = prompt.library.mcp_agent 'gemini-3.1-pro-preview', -- Multiplier = 1.
                ['Agent GPT-5.3 Codex'] = prompt.library.mcp_agent 'gpt-5.3-codex', -- Multiplier = 1.
            },
            opts = {
                log_level = 'ERROR', -- TRACE|DEBUG|ERROR|INFO
                language = 'Russian', -- The language used for LLM responses.
                per_project_config = { -- Needed for custom rule groups.
                    -- return {rules={['GROUP NAME']={files={'.codecompanion/rules/FILE.md'}}}}
                    files = {
                        '.codecompanion/config.lua',
                    },
                },
            },
        },
        config = function(_, opts)
            require('codecompanion').setup(opts)
            require('custom.codecompanion.auto_approve').setup_codecompanion()
            require('custom.codecompanion.fidget-spinner'):init()

            local config = require 'codecompanion.config'

            local util = require 'custom.util'
            util.adapt_nerd_font_propo(config.config)

            -- Patch default rules files config to support link to AGENTS.md in CLAUDE.md.
            do
                local rules = config.config.rules.default.files

                -- Remove CLAUDE- and AGENTS-related entries.
                for i = #rules, 1, -1 do
                    local entry = rules[i]
                    local path = type(entry) == 'string' and entry or entry.path
                    if path:find 'CLAUDE' or path:find 'AGENTS' then
                        table.remove(rules, i)
                    end
                end

                -- Add project-level: AGENTS.md or CLAUDE.md.
                if
                    vim.uv.fs_stat 'AGENTS.md'
                    or vim.uv.fs_stat 'AGENTS.local.md'
                    or not (vim.uv.fs_stat 'CLAUDE.md' or vim.uv.fs_stat 'CLAUDE.local.md')
                then
                    table.insert(rules, 'AGENTS.md')
                    table.insert(rules, 'AGENTS.local.md')
                else
                    table.insert(rules, { path = 'CLAUDE.md', parser = 'claude' })
                    table.insert(rules, { path = 'CLAUDE.local.md', parser = 'claude' })
                end

                -- Add global: ~/.agent/AGENTS.md or ~/.claude/CLAUDE.md.
                if
                    vim.uv.fs_stat(vim.fn.expand '~/.agent/AGENTS.md')
                    or not (vim.uv.fs_stat(vim.fn.expand '~/.claude/CLAUDE.md'))
                then
                    table.insert(rules, '~/.agent/AGENTS.md')
                else
                    table.insert(rules, { path = '~/.claude/CLAUDE.md', parser = 'claude' })
                end
            end

            -- Load project rule groups from `.agent/rules/*.md` files.
            -- This enables additional (beyond the default group, e.g., `AGENTS.md`)
            -- project-specific rule groups without altering the main configuration file.
            -- Each `.md` file in `.agent/rules/` defines a rule group named after the file.
            local files = require 'codecompanion.utils.files'
            local rule_dir = vim.g.project_root .. '/.agent/rules'
            do
                local rule_files = files.list_dir(rule_dir)
                if rule_files then
                    for _, file_name in ipairs(rule_files) do
                        if file_name:len() > 3 and file_name:sub(-3) == '.md' then
                            local rule_name = file_name:match '(.+)%.md$'
                            local file_path = rule_dir .. '/' .. file_name
                            config.config.rules[rule_name] = {
                                description = files.read(file_path) or '',
                                files = { file_path },
                            }
                        end
                    end
                end
            end

            -- Enforce using only local LLM adapters if remote adapters are forbidden,
            -- to avoid accidentally sending sensitive data to remote servers.
            -- Note that data can leak not only through LLM interactions, but also through tools,
            -- so avoid giving access to tools like web search even to local LLMs.
            if not vim.g.allow_remote_llm then
                -- Forbid loading remote LLM adapters.
                local orig_require = require
                require = function(name)
                    if
                        name:match '^codecompanion.adapters.acp.'
                        or name:match '^codecompanion.adapters.http.'
                            and not name:match '^codecompanion.adapters.http.ollama'
                            and name ~= 'codecompanion.adapters.http.jina' -- Needed for /fetch.
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
                for key in pairs(config.config.adapters.acp) do
                    if key ~= 'opts' then -- Skip non-LLMs.
                        config.config.adapters.acp[key] = nil
                    end
                end
                for key, adapter in pairs(config.config.adapters.http) do
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
                        config.config.adapters.http[key] = nil
                    end

                    ::continue::
                end

                -- Use ollama as the default adapter for all interactions.
                config.config.interactions.chat.adapter = 'ollama'
                config.config.interactions.inline.adapter = 'ollama'
                config.config.interactions.cmd.adapter = 'ollama'
                config.config.interactions.background.adapter = 'ollama'

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

            -- CodeCompanion executes 'checktime' only for the @insert_edit_into_file tool,
            -- but files may also be modified by other tools.
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

            -- Fix picker for slash commands to add selection to the prompt instead of
            -- opening the file in a new tab.
            local telescope = require 'codecompanion.providers.slash_commands.telescope'
            do
                local orig_display = telescope.display
                function telescope:display()
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
            end

            -- Play a sound when LLM response completes or awaits tool approval
            -- when Neovim is not focused, to prevent missing critical notifications.
            ---@module 'sound_notifier'
            local notifier = require('sound_notifier').new(vim.g.llm_message_sound)
            vim.api.nvim_create_autocmd('User', {
                group = vim.api.nvim_create_augroup('user.cc_sound_notifier', { clear = true }),
                pattern = {
                    'CodeCompanionChatDone',
                    'CodeCompanionInlineFinished',
                    'CodeCompanionToolApprovalRequested',
                    'MCPHubApprovalWindowOpened',
                },
                callback = notifier:notify_callback(),
            })

            -- Based on https://codecompanion.olimorris.dev/configuration/chat-buffer#truncating-tool-output
            vim.api.nvim_create_autocmd('User', {
                pattern = 'CodeCompanionChatCreated',
                callback = function(args)
                    local chat = require('codecompanion').buf_get_chat(args.data.bufnr)
                    chat:add_callback('on_tool_output', function(data)
                        ---@cast data table { tool: string, for_llm: string, for_user: string }
                        local tokens = require 'codecompanion.utils.tokens'
                        local max_tokens = 10000
                        local all_tokens = tokens.calculate(data.for_llm)

                        if data.for_llm and all_tokens > max_tokens then
                            -- Trim to roughly max_tokens worth of characters
                            local max_chars = max_tokens * 6
                            data.for_llm = data.for_llm:sub(1, max_chars)
                                .. '\n\n[Output truncated]'
                            data.for_user = data.for_llm
                            vim.notify(
                                string.format(
                                    "Tool output from '%s' truncated (%d to ~%d tokens)",
                                    data.tool,
                                    all_tokens,
                                    max_tokens
                                ),
                                vim.log.levels.WARN
                            )
                        end
                    end)
                end,
            })
        end,
    },
}

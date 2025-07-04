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

local const = {
    USER_ROLE = 'user',
    SYSTEM_ROLE = 'system',
}

local function chat_filter(chat_data)
    return vim.g.project_root == chat_data.project_root or vim.g.project_root == chat_data.cwd
end

local function send_code(context)
    local actions = require 'codecompanion.helpers.actions'
    local text = actions.get_code(context.start_line, context.end_line)

    return 'I have the following code:\n\n```'
        .. context.filetype
        .. '\n'
        .. text
        .. '\n```\n\n'
end

local function get_text(context)
    local buf = vim.api.nvim_get_current_buf()
    local lines =
        vim.api.nvim_buf_get_lines(buf, context.start_line - 1, context.end_line, false)
    if #lines == 0 then
        return ''
    end

    if context.start_line == context.end_line then
        return string.sub(lines[1], context.start_col, context.end_col)
    end

    lines[1] = string.sub(lines[1], context.start_col)
    lines[#lines] = string.sub(lines[#lines], 1, context.end_col)
    return table.concat(lines, '\n')
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
            'custom.codecompanion.auto_approve',
        },
        -- build = 'npm install -g mcp-hub@latest', -- Binary `mcp-hub` is installed by Mise.
        config = function()
            ---@diagnostic disable-next-line: missing-fields
            require('mcphub').setup {
                auto_approve = require('custom.codecompanion.auto_approve').mcphub,
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
                        -- model = 'gpt-4.1', -- Multiplier = 0 (free).
                        model = 'claude-3.5-sonnet', -- Multiplier = 1.
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
                        -- model = 'gemini-2.0-flash-001', -- Multiplier = 0.25.
                        -- model = 'o3-mini', -- Multiplier = 0.33.
                        -- model = 'o4-mini', -- Multiplier = 0.33.
                        -- model = 'gemini-2.5-pro', -- Multiplier = 1.
                        model = 'claude-3.5-sonnet', -- Multiplier = 1.
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
                            modes = { n = '<Leader>cs' },
                        },
                        auto_tool_mode = {
                            modes = { n = '<Leader>ct' },
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
                history = {
                    enabled = true,
                    opts = {
                        keymap = false, -- Use Action Palette to open.
                        save_chat_keymap = false, -- Use autosave.
                        expiration_days = 30,
                        --- Title generation is troublesome with Ollama models:
                        ---   - Ollama is slow, this will slow down the beginning of each chat.
                        ---   - Using a concrete model will slow down things even more
                        ---     because it will unload other model chosen by the user.
                        ---   - Using default model will not work with qwen3 without hiding
                        ---     thinking tags, but there is no way to ensure hiding.
                        --- So, use it only with remote LLMs.
                        auto_generate_title = vim.g.allow_remote_llm,
                        title_generation_opts = {
                            -- This one is free on my Copilot Pro plan.
                            adapter = 'copilot',
                            model = 'gpt-4.1',
                            refresh_every_n_prompts = 0, -- e.g., 3 to refresh after every 3rd user prompt
                        },
                        -- Show chats only from the current project.
                        chat_filter = chat_filter,
                    },
                },
                mcphub = {
                    callback = 'mcphub.extensions.codecompanion',
                    opts = {
                        show_result_in_chat = false, -- Show mcp tool results in chat.
                        make_vars = true, -- Convert resources to #variables.
                        make_slash_commands = true, -- Add prompts as /slash commands.
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
                -- Strip thinking tags from qwen3 responses.
                ollama_qwen_3_hide_thinking = function()
                    ---@alias thinkState ''|'thinking'|'done' Thinking state of streamed response.
                    ---@type thinkState
                    local think = ''
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
                        handlers = {
                            inline_output = function(self, data, context)
                                local openai = require 'codecompanion.adapters.openai'
                                local res = openai.handlers.inline_output(self, data, context)
                                if res and res.output then
                                    res.output = res.output:gsub('<think>.-</think>', '', 1)
                                end
                                return res
                            end,
                            chat_output = function(self, data, tools)
                                local openai = require 'codecompanion.adapters.openai'
                                local res = openai.handlers.chat_output(self, data, tools)
                                if res and res.output then
                                    if res.output.content:match '<think>' then
                                        think = 'thinking'
                                    end
                                    if res.output.content:match '</think>' then
                                        think = 'done'
                                        res.output.content =
                                            res.output.content:gsub('^.-</think>%s*', '', 1)
                                    end
                                    if think == 'done' and res.output.content:match '%S' then
                                        think = ''
                                    end
                                    if think ~= '' then
                                        return nil
                                    end
                                end
                                return res
                            end,
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
                ['Unit Tests'] = { opts = { index = 50 } },
                ['Fix code'] = { opts = { index = 150 } },
                ['Explain LSP Diagnostics'] = { opts = { index = 151 } },
                ['Explain'] = { opts = { index = 152 } },
                ['Generate a Commit Message'] = { opts = { index = 153 } },
                ['Workspace File'] = { opts = { index = 250 } },
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
                ['Free Chat (GPT-4.1)'] = {
                    strategy = 'chat',
                    description = 'Create a new chat buffer to converse with an LLM for free',
                    condition = function()
                        return vim.g.allow_remote_llm
                    end,
                    opts = {
                        index = 6,
                        stop_context_insertion = true,
                        adapter = {
                            name = 'copilot',
                            model = 'gpt-4.1', -- Multiplier = 0 (free).
                        },
                    },
                    prompts = {
                        n = { { role = const.USER_ROLE, content = '' } },
                        i = { { role = const.USER_ROLE, content = '' } },
                        v = { -- Same as in default "Chat" menu item.
                            {
                                role = const.SYSTEM_ROLE,
                                content = function(context)
                                    return 'I want you to act as a senior '
                                        .. context.filetype
                                        .. ' developer. I will give you specific code examples and ask you questions. I want you to advise me with explanations and code examples.'
                                end,
                            },
                            {
                                role = const.USER_ROLE,
                                content = function(context)
                                    return send_code(context)
                                end,
                                opts = {
                                    contains_code = true,
                                },
                            },
                        },
                    },
                },
                ['Improve grammar'] = {
                    strategy = 'inline',
                    description = 'Improve grammar in the selected text',
                    opts = {
                        index = 100,
                        adapter = {
                            name = 'ollama_qwen_3_hide_thinking',
                        },
                        modes = { 'v' },
                        short_name = 'grammar',
                        user_prompt = false,
                        placement = 'replace',
                        stop_context_insertion = true,
                    },
                    prompts = {
                        {
                            role = const.SYSTEM_ROLE,
                            content = [[
<prompt>
Your task is to take the text I have selected in the buffer
and rewrite it into a clear, grammatically correct version
while preserving the original language, meaning and tone as closely as possible.
Correct any spelling mistakes, punctuation errors, verb tense issues, word choice problems,
and other grammatical mistakes.

The selected text is a part of code documentation — either code comments or Markdown file.

If the selected text contains both code and comments, do not change the code.
Include code in your response as-is and make your changes only within comments.

If the selected text is in Markdown format:
- Do NOT add, change or delete the Markdown structure (headers, lists, tables, blockquotes).
- Do NOT change inline code blocks (e.g. `code`).
- You may improve inline formatting (e.g. bold/italic) only if relevant to your corrections.

**IMPORTANT CONSTRAINTS**:
- You must preserve the original formatting, indentation, line breaks, block/line comment markers.
- You must try hard to avoid too long (above 100 characters) lines:
  use more concise sentences or break them into multiple lines.
- You must return only a raw JSON object, strictly following this schema:

    {
      "code": "<corrected_text_here>",
      "language": "<filetype_here>"
    }

- Do NOT include triple backticks or any Markdown formatting unless it is a part of selected text.
- Do NOT include any explanations, justifications, or reasoning.
- If the selected text is already correct, return it **unchanged** in the "code" field.

Violation of these constraints will be treated as incorrect output.
</prompt>
/no_think
                            ]],
                        },
                        {
                            role = const.USER_ROLE,
                            content = function(context)
                                return '<selected_text>\n'
                                    .. get_text(context)
                                    .. '</selected_text>\n'
                                    .. '<filetype>\n'
                                    .. context.filetype
                                    .. '\n'
                                    .. '</filetype>\n'
                            end,
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
                            name = 'ollama_qwen_3_hide_thinking',
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
                            role = const.SYSTEM_ROLE,
                            content = [[
You are a highly skilled translator with expertise in many languages.
Your task is to identify the language of the text I provide and accurately translate it into
the specified target language while preserving the meaning, tone, and nuance of the original text.
Please maintain proper grammar, spelling, and punctuation in the translated version.

If text language is English, then translate it into Russian, otherwise translate it into English.

The text I provide may contain code snippets, Markdown formatting, or other special elements -
do not translate them but preserve them as-is in the translated text.

Respond with the translated text only, without any additional explanations or comments.
                            ]],
                        },
                        {
                            role = const.USER_ROLE,
                            content = '',
                        },
                    },
                },
            },
            opts = {
                language = 'Russian', -- The language used for LLM responses.
                log_level = 'ERROR', -- TRACE|DEBUG|ERROR|INFO
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
                for _, prompt in pairs(config.config.prompt_library) do
                    if type(prompt) == 'table' and prompt.opts and prompt.opts.adapter then
                        local adapter = prompt.opts.adapter
                        if
                            not (type(adapter) == 'string' and adapter:find 'ollama')
                            and not (type(adapter) == 'table' and adapter.name:find 'ollama')
                        then
                            prompt.opts.adapter = 'ollama'
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
        end,
    },
}

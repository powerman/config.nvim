---@module 'codecompanion'
---@module 'codecompanion._extensions.history.types'

local M = {
    constants = {
        USER_ROLE = 'user',
        SYSTEM_ROLE = 'system',
    },
    -- Entries for prompt_library.
    library = {},
    -- Extra instructions for specific tools to be included in the system prompt
    -- when those tools are available.
    -- Set at the end to allow referencing local variables and functions.
    ---@type table<string, string> A mapping of tool names to custom instructions.
    tool_instructions = {},
}

-- Utility function to create a simple counter for unique indices.
local function make_counter(start)
    local count = start or 0
    return function()
        local current = count
        count = count + 1
        return current
    end
end

-- Get the model name from the adapter context for dynamic system prompts.
---@param ctx CodeCompanion.SystemPrompt.Context
M.get_model = function(ctx)
    local adapter = ctx.adapter
    local model = ''
    if adapter and adapter.type == 'http' then
        model = adapter.model and adapter.model.name or ''
    elseif adapter and adapter.type == 'acp' then
        model = adapter.model
    end
    return model
end

-- A simple set implementation for O(1) lookups of tool availability in system prompts.
local ToolSet = {}

-- Create a new ToolSet from a list of available tool names.
---@param available string[] The list of available tools to include in the set.
function ToolSet.new(available)
    local set = {}
    for _, v in ipairs(available) do
        set[v] = true
    end
    return setmetatable({ _set = set }, { __index = ToolSet })
end

-- Find the first tool name from alternatives that is present in the set.
---@param alternatives string[] The list of alternative tool names to check for in the set, in order of preference.
---@return string? The first tool name from alternatives that is present in the set, or nil if none are found.
function ToolSet:find_first(alternatives)
    return vim.iter(alternatives):find(function(v)
        return self._set[v]
    end)
end

-- This is an experimental attempt to use the memory tool like a lightweight
-- Spec-Driven Development (SDD) system, to preserve important design decisions.
-- In theory, this should help maintain architectural coherence across sessions
-- for decisions not documented in AGENT.md, without the overhead of a full SDD system.
local tool_memory_as_SSD_instructions = [[
These instructions extend (not replace) the default memory tool behaviour.
They apply specifically to software development sessions within a project directory.

Memory files are stored in the `memories/` subdirectory of the current project.

## File structure

Use two files with fixed names:

`/memories/decisions.md` — architectural decisions for this project.
Create it the first time a decision worth preserving arises.

`/memories/tasks.md` — tasks for a multi-session effort.
Create it when a request produces 5 or more distinct subtasks.
Delete it when all tasks are complete.

For any other information worth saving, ask the user before creating new files.
If the user agrees, follow the default memory instructions for naming and structure.

## When to read

At the start of any session involving non-trivial work, check whether
`/memories/decisions.md` exists and read it if so.
Check `/memories/tasks.md` if the user's request seems to continue prior work.

## When to write

`decisions.md`: save a decision when it is:

- non-obvious (not self-evident from reading the code),
- not already captured in docs, comments, or AGENT.md,
- and likely to affect future work on this project.

Typical candidates: why X was chosen over Y, a rejected alternative,
a discovered constraint (API limitation, compatibility issue),
a deliberate trade-off.

Do NOT save routine implementation steps or anything already in the codebase.

`tasks.md`: create it as soon as the task list is formed, before starting work.
Mark each task complete with `[x]` immediately after finishing it, not at the end of the session.
Delete the file once all tasks are marked complete.

## Format

<example file='decisions.md'>
## {topic}

- **Decision:** {what was decided}
- **Rationale:** {why}
- **Rejected alternative:** {what and why} (omit if none)

</example>

<example file='tasks.md'>
## {effort name}

- [ ] {task}
- [x] {completed task}

</example>

## Hygiene

Prefer `str_replace` over rewriting the whole file.
Remove stale decisions if they no longer reflect the codebase.
Keep entries concise — one decision per section, no prose.
]]

-- Extracted from CodeCompanion's CONSTANTS.SYSTEM_PROMPT, with minor change.
local codecompanion_instructions = [[
<outputFormattingInstructions>
Use Markdown formatting in your answers.

DO NOT use H1 or H2 headers in your response.

When suggesting code changes or new content, use Markdown code blocks.

To start a code block, use 4 backticks.
After the backticks, add the programming language name as the language ID
and the file path within curly braces if available.
To close a code block, use 4 backticks on a new line.
If you want the user to decide where to place the code, do not add the file path.
In the code block, use a line comment with '...existing code...'
to indicate code that is already present in the file.
Ensure this comment is specific to the programming language.
Code block example:

````languageId {path/to/file}
// ...existing code...
{ changed code }
// ...existing code...
{ changed code }
// ...existing code...
````

Ensure line comments use the correct syntax for the programming language
(e.g. "#" for Python, "--" for Lua).

Avoid wrapping the whole response in triple backticks.

Do not include diff formatting unless explicitly asked.

Do not include line numbers in code blocks unless explicitly asked.
</outputFormattingInstructions>
]]

-- Same as in CodeCompanion's default system prompt, wrapped in <additionalContext> tags.
---@param ctx CodeCompanion.SystemPrompt.Context
---@return string
local function dynamic_context(ctx)
    return string.format(
        [[
<additionalContext>
All non-code text responses must be written in the %s language.
The user's current working directory is %s.
The current date is %s.
The user's Neovim version is %s.
The user is working on a %s machine. Please respond with system specific commands if applicable.
</additionalContext>
]],
        ctx.language,
        ctx.cwd,
        ctx.date,
        ctx.nvim_version,
        ctx.os
    )
end

---@param ctx CodeCompanion.SystemPrompt.Context
---@param available string[] The tools available
---@return string
local function system_prompt(ctx, available)
    local copilot_locale = {
        ['English'] = 'en',
        ['French'] = 'fr',
        ['Italian'] = 'it',
        ['German'] = 'de',
        ['Spanish'] = 'es',
        ['Russian'] = 'ru',
        ['Chinese (Simplified)'] = 'zh-CN',
        ['Chinese (Traditional)'] = 'zh-TW',
        ['Japanese'] = 'ja',
        ['Korean'] = 'ko',
        ['Czech'] = 'cs',
        ['Portuguese (Brazil)'] = 'pt-br',
        ['Turkish'] = 'tr',
        ['Polish'] = 'pl',
    }
    local tools = ToolSet.new(available)
    local copilot_prompt = require('copilot_prompt').system_prompt {
        identity = 'CodeCompanion',
        model = M.get_model(ctx),
        locale = copilot_locale[ctx.language] or 'auto',
        omitBaseAgentInstructions = false,
        enableAlternateGptPrompt = true, -- Just an experiment, not sure if it will be helpful.
        codesearchMode = false,
        mathEnabled = false,
        tools = {
            EditFile = tools:find_first {
                'filesystem__edit_file',
                'insert_edit_into_file',
                'neovim__edit_file',
            },
            ReplaceString = nil, -- No such tool in CodeCompanion.
            MultiReplaceString = nil, -- No such tool in CodeCompanion.
            ApplyPatch = nil, -- No such tool in CodeCompanion.
            ReadFile = tools:find_first {
                'filesystem__read_file',
                'read_file',
                'neovim__read_file',
                'filesystem__read_text_file',
                'filesystem__read_media_file',
                'filesystem__read_multiple_files',
                'neovim__read_multiple_files',
            },
            CreateFile = tools:find_first {
                'filesystem__write_file',
                'create_file',
                'neovim__write_file',
            },
            CoreRunInTerminal = tools:find_first {
                'shell__shell_exec',
                'run_command',
                'neovim__execute_command',
            },
            CoreRunTest = nil, -- No such tool in CodeCompanion.
            CoreRunTask = nil, -- No such tool in CodeCompanion.
            CoreManageTodoList = nil, -- No such tool in CodeCompanion.
            Codebase = nil, -- No such tool in CodeCompanion.
            FindTextInFiles = tools:find_first {
                'grep_search',
            },
            FindFiles = tools:find_first {
                'filesystem__search_files',
                'file_search',
                'neovim__find_files',
            },
            SearchSubagent = nil, -- No such tool in CodeCompanion.
            FetchWebPage = tools:find_first {
                'fetch_webpage',
                'tavily_mcp__tavily_extract',
            },
            GetErrors = tools:find_first {
                'get_diagnostics',
            },
        },
    }
    local tool_instructions = ''
    for tool, instruction in pairs(M.tool_instructions) do
        if vim.tbl_contains(available, tool) then
            tool_instructions = tool_instructions
                .. string.format(
                    '<toolInstructions tool="%s">\n%s\n</toolInstructions>\n',
                    tool,
                    vim.trim(instruction)
                )
        end
    end
    return vim.trim(copilot_prompt)
        .. '\n\n'
        .. vim.trim(tool_instructions)
        .. '\n\n'
        .. vim.trim(codecompanion_instructions)
        .. '\n\n'
        .. vim.trim(dynamic_context(ctx))
end

-- Default system prompt based on Copilot's system prompt.
---@param ctx CodeCompanion.SystemPrompt.Context
---@return string
M.default_system_prompt = function(ctx)
    return system_prompt(ctx, {})
end

-- The tool system prompt is used to replace the default system prompt when tools are present.
---@param args { ctx: CodeCompanion.SystemPrompt.Context, tools: string[]} The tools available
---@return string
M.tool_system_prompt = function(args)
    return system_prompt(args.ctx, args.tools)
end

M.tool_instructions = {
    ['memory'] = tool_memory_as_SSD_instructions,
}

-- Counter for assigning unique indices to prompt library entries.
-- Starts at 4 to skip over the built-in entries.
local next_index = make_counter(4)

---@param filter_fn? fun(chat_data: CodeCompanion.History.ChatIndexData): boolean Optional filter function
local function cb_have_chats(filter_fn)
    return function()
        local history = require('codecompanion').extensions.history
        local have_chats = not vim.tbl_isempty(history.get_chats(filter_fn))
        local mode = vim.api.nvim_get_mode()
        return have_chats and (mode.mode == 'n' or mode.mode == 'i')
    end
end

---@param filter_fn? fun(chat_data: CodeCompanion.History.ChatIndexData): boolean Optional filter function
local function cb_browse_chats(filter_fn)
    return function()
        local history = require('codecompanion').extensions.history
        history.browse_chats(filter_fn)
    end
end

---@param filter_fn? fun(chat_data: CodeCompanion.History.ChatIndexData): boolean Optional filter function
M.library.saved_chats = function(filter_fn)
    return {
        interaction = 'chat',
        description = 'Browse saved chats',
        opts = {
            index = next_index(),
            stop_context_insertion = true,
        },
        condition = cb_have_chats(filter_fn),
        prompts = {
            n = cb_browse_chats(filter_fn),
            i = cb_browse_chats(filter_fn),
        },
    }
end

-- Counter for assigning unique indices to agent entries in the prompt library.
-- Starts at 10 to skip over the built-in entries and the saved_chats entries.
local next_agent_index = make_counter(10)

M.library.mcp_agent = function(model)
    return {
        interaction = 'chat',
        description = 'Create a new chat with ' .. model .. ' in Agent mode using MCP tools',
        condition = function()
            return vim.g.allow_remote_llm
        end,
        opts = {
            index = next_agent_index(),
            stop_context_insertion = true,
            adapter = {
                name = 'copilot',
                model = model,
            },
        },
        rules = {
            'default',
        },
        tools = {
            'mcp_agent',
        },
        prompts = {
            {
                role = M.constants.USER_ROLE,
                content = '#{mcp:neovim://workspace}',
            },
        },
    }
end

return M

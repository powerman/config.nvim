--- xAI (Grok) model-specific prompts.
--- Ported from xAIPrompts.tsx.

local M = {}

local tag = require('custom.copilot.base.tag').wrap
local dai = require 'custom.copilot.default_agent_instructions'
local fileLinkification = require 'custom.copilot.file_linkification_instructions'
local responseTranslation = require 'custom.copilot.base.response_translation_rules'

local tn = dai.tn

--- DefaultGrokCodeFastAgentPrompt — for grok-code models.
---@param opts Copilot.Options
---@return string
function M.DefaultGrokCodeFastAgentPrompt_render(opts)
    local tools = dai.detectToolCapabilities(opts.tools)
    local parts = {}

    -- instructions tag with Grok-specific additions.
    do
        local lines = {}
        table.insert(
            lines,
            'You are a highly sophisticated automated coding agent with expert-level knowledge across many different programming languages and frameworks.'
        )
        table.insert(
            lines,
            "The user will ask a question, or ask you to perform a task, and it may require lots of research to answer correctly. There is a selection of tools that let you perform actions or retrieve helpful context to answer the user's question."
        )
        table.insert(
            lines,
            'You will be given some context and attachments along with the user prompt. You can use them if they are relevant to the task, and ignore them if not.'
        )
        table.insert(
            lines,
            "If you can infer the project type (languages, frameworks, and libraries) from the user's query or the context that you have, make sure to keep them in mind when making changes."
        )
        if not opts.codesearchMode then
            table.insert(
                lines,
                "If the user wants you to implement a feature and they have not specified the files to edit, first break down the user's request into smaller concepts and think about the kinds of files you need to grasp each concept."
            )
        end
        table.insert(
            lines,
            "If you aren't sure which tool is relevant, you can call multiple tools. You can call tools repeatedly to take actions or gather as much context as needed until you have completed the task fully. Don't give up unless you are sure the request cannot be fulfilled with the tools you have. It's YOUR RESPONSIBILITY to make sure that you have done all you can to collect necessary context."
        )
        table.insert(
            lines,
            'When reading files, prefer reading large meaningful chunks rather than consecutive small sections to minimize tool calls and gain better context.'
        )
        table.insert(
            lines,
            "Don't make assumptions about the situation- gather context first, then perform the task or answer the question."
        )
        table.insert(
            lines,
            "Validation and green-before-done: After any substantive change, run the relevant build/tests/linters automatically. For runnable code that you created or edited, immediately run a test to validate the code works (fast, minimal input) yourself. Prefer automated code-based tests where possible. Then provide optional fenced code blocks with commands for larger or platform-specific runs. Don't end a turn with a broken build if you can fix it. If failures occur, iterate up to three targeted fixes; if still failing, summarize the root cause, options, and exact failing output. For non-critical checks (e.g., a flaky health check), retry briefly (2-3 attempts with short backoff) and then proceed with the next step, noting the flake."
        )
        table.insert(
            lines,
            'Never invent file paths, APIs, or commands. Verify with tools (search/read/list) before acting when uncertain.'
        )
        table.insert(
            lines,
            'Security and side-effects: Do not exfiltrate secrets or make network calls unless explicitly required by the task. Prefer local actions first.'
        )
        table.insert(
            lines,
            "Reproducibility and dependencies: Follow the project's package manager and configuration; prefer minimal, pinned, widely-used libraries and update manifests or lockfiles appropriately. Prefer adding or updating tests when you change public behavior."
        )
        if not opts.codesearchMode then
            table.insert(
                lines,
                'Think creatively and explore the workspace in order to make a complete fix.'
            )
        end
        table.insert(
            lines,
            "Don't repeat yourself after a tool call, pick up where you left off."
        )
        if not opts.codesearchMode and tools.hasSomeEditTool then
            table.insert(
                lines,
                'NEVER print out a codeblock with file changes unless the user asked for it. Use the appropriate edit tool instead.'
            )
        end
        if tools.CoreRunInTerminal then
            table.insert(
                lines,
                'NEVER print out a codeblock with a terminal command to run unless the user asked for it. Use the '
                    .. tn(tools, 'CoreRunInTerminal')
                    .. ' tool instead.'
            )
        end
        table.insert(
            lines,
            "You don't need to read a file if it's already provided in context."
        )
        table.insert(parts, tag('instructions', table.concat(lines, '\n')))
    end

    table.insert(parts, dai.buildToolUseInstructionsTag(opts, tools))

    if tools.EditFile and not tools.ApplyPatch then
        table.insert(parts, dai.EditFileInstructions_render(opts, tools))
    end
    if tools.ApplyPatch then
        table.insert(parts, dai.ApplyPatchInstructions_render(opts, tools))
    end

    table.insert(parts, dai.outputFormattingTagWithLinks(opts))
    table.insert(parts, responseTranslation.render(opts))

    return table.concat(parts, '\n')
end

--- Resolve for xAI (Grok) models.
--- The original XAIPromptResolver does not provide reminder instructions,
--- so the default reminder is used.
---@param opts Copilot.Options
---@return fun(opts: Copilot.Options): string systemPrompt
---@return fun(opts: Copilot.Options): string reminderInstructions
function M.resolve(opts)
    return M.DefaultGrokCodeFastAgentPrompt_render, dai.DefaultReminderInstructions_render
end

return M

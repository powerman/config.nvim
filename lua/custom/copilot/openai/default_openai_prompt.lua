--- Default OpenAI agent prompt.
--- Ported from openai/defaultOpenAIPrompt.tsx.

local M = {}

local dai = require 'custom.copilot.default_agent_instructions'
local fileLinkification = require 'custom.copilot.file_linkification_instructions'
local responseTranslation = require 'custom.copilot.base.response_translation_rules'

local tn = dai.tn

--- Keep-going reminder used by OpenAI models.
---@return string
function M.DefaultOpenAIKeepGoingReminder_render()
    return "You are an agent - you must keep going until the user's query is completely resolved, before ending your turn and yielding back to the user. ONLY terminate your turn when you are sure that the problem is solved, or you absolutely cannot continue.\n"
        .. "You take action when possible- the user is expecting YOU to take action and go to work for them. Don't ask unnecessary questions about the details if you can simply DO something useful instead.\n"
end

--- DefaultOpenAIAgentPrompt — for GPT-4o, o3-mini, o4-mini, etc.
---@param opts Copilot.Options
---@return string
function M.DefaultOpenAIAgentPrompt_render(opts)
    local tools = dai.detectToolCapabilities(opts.tools)
    local parts = {}

    -- instructions tag — includes KeepGoingReminder
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
        table.insert(lines, M.DefaultOpenAIKeepGoingReminder_render())
        if tools.SearchSubagent then
            table.insert(
                lines,
                'For codebase exploration, prefer '
                    .. tn(tools, 'SearchSubagent')
                    .. ' to search and gather data instead of directly calling '
                    .. tn(tools, 'FindTextInFiles')
                    .. ', '
                    .. tn(tools, 'Codebase')
                    .. ' or '
                    .. tn(tools, 'FindFiles')
                    .. '.'
            )
        end
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
        table.insert(
            parts,
            require('custom.copilot.base.tag').wrap('instructions', table.concat(lines, '\n'))
        )
    end

    table.insert(parts, dai.buildToolUseInstructionsTag(opts, tools))

    if tools.EditFile and not tools.ApplyPatch then
        table.insert(parts, dai.EditFileInstructions_render(opts, tools))
    end
    if tools.ApplyPatch then
        table.insert(parts, dai.ApplyPatchInstructions_render(opts, tools))
    end

    -- outputFormatting with fileLinkification
    do
        local fmtLines = {}
        table.insert(
            fmtLines,
            '- Wrap symbol names (classes, methods, variables) in backticks: `MyClass`, `handleClick()`'
        )
        table.insert(
            fmtLines,
            '- When mentioning files or line numbers, always follow the rules in fileLinkification section below:'
        )
        table.insert(fmtLines, fileLinkification.render())
        table.insert(fmtLines, dai.MathIntegrationRules_render(opts))
        table.insert(
            parts,
            require('custom.copilot.base.tag').wrap(
                'outputFormatting',
                table.concat(fmtLines, '\n')
            )
        )
    end

    table.insert(parts, responseTranslation.render(opts))

    return table.concat(parts, '\n')
end

--- OpenAIReminderInstructions.
---@param opts Copilot.Options
---@return string
function M.OpenAIReminderInstructions_render(opts)
    local tools = dai.detectToolCapabilities(opts.tools)
    return M.DefaultOpenAIKeepGoingReminder_render()
        .. dai.getEditingReminder(
            tools.EditFile ~= nil,
            tools.ReplaceString ~= nil,
            false,
            tools.MultiReplaceString ~= nil,
            tools
        )
end

--- Resolve for default OpenAI models.
---@param opts Copilot.Options
---@return fun(opts: Copilot.Options): string systemPrompt
---@return fun(opts: Copilot.Options): string reminderInstructions
function M.resolve(opts)
    return M.DefaultOpenAIAgentPrompt_render, M.OpenAIReminderInstructions_render
end

return M

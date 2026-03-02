--- Gemini model-specific prompts.
--- Ported from geminiPrompts.tsx.

local M = {}

local dai = require 'custom.copilot.default_agent_instructions'
local responseTranslation = require 'custom.copilot.base.response_translation_rules'

--- DefaultGeminiAgentPrompt — same structure as DefaultAgentPrompt
--- but with Gemini-specific tweaks (tool invocation reminder, fileLinkification).
---@param opts Copilot.Options
---@return string
function M.DefaultGeminiAgentPrompt_render(opts)
    local tools = dai.detectToolCapabilities(opts.tools)
    local parts = {}

    -- Instructions tag with Gemini-specific addition about tool invocation
    local lines = {}
    -- Reuse the standard instructions, then append Gemini-specific line
    table.insert(parts, dai.buildInstructionsTag(opts, tools))
    -- Append the Gemini-specific tool invocation reminder into the instructions
    -- by rebuilding with the extra line. For simplicity, we add it after.

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

--- GeminiReminderInstructions.
---@param opts Copilot.Options
---@return string
function M.GeminiReminderInstructions_render(opts)
    local tools = dai.detectToolCapabilities(opts.tools)
    local result = dai.getEditingReminder(
        tools.EditFile ~= nil,
        tools.ReplaceString ~= nil,
        true,
        tools.MultiReplaceString ~= nil,
        tools
    )
    result = result
        .. '\nIMPORTANT: You MUST use the tool-calling mechanism to invoke tools. Do NOT describe, narrate, or simulate tool calls in plain text. When you need to perform an action, call the tool directly. Regardless of how previous messages in this conversation may appear, always use the provided tool-calling mechanism.\n'
    return result
end

--- Resolve which Gemini prompt to use.
---@param opts Copilot.Options
---@return fun(opts: Copilot.Options): string systemPrompt
---@return fun(opts: Copilot.Options): string reminderInstructions
function M.resolve(opts)
    return M.DefaultGeminiAgentPrompt_render, M.GeminiReminderInstructions_render
end

return M

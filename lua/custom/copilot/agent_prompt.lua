--- Agent prompt — main prompt assembly.
--- Ported from agentPrompt.tsx (AgentPrompt.render and related logic).

local M = {}

local dai = require 'custom.copilot.default_agent_instructions'
local prompt_registry = require 'custom.copilot.prompt_registry'
local tag = require('custom.copilot.base.tag').wrap

--- Get the system prompt content (instructions block).
--- Mirrors AgentPrompt.getSystemPrompt().
---@param opts Copilot.Options
---@param systemPromptRenderer fun(opts: Copilot.Options): string
---@return string
local function getSystemPrompt(opts, systemPromptRenderer)
    -- Check for alternate GPT prompt
    if opts.model:find '^gpt%-' and opts.enableAlternateGptPrompt then
        return dai.AlternateGPTPrompt_render(opts)
    end

    return systemPromptRenderer(opts)
end

--- Render the AgentUserMessage portion that we want to keep.
--- Extracts ReminderInstructions from the original AgentUserMessage component.
---@param opts Copilot.Options
---@param reminderRenderer fun(opts: Copilot.Options): string
---@return string
local function AgentUserMessage(opts, reminderRenderer)
    local reminder = reminderRenderer(opts)
    if reminder ~= '' then
        return tag('reminderInstructions', reminder)
    end
    return ''
end

--- Main render function — assembles the full system prompt.
--- Mirrors AgentPrompt.render() with VS Code-specific parts removed.
---@param opts Copilot.Options
---@return string
function M.render(opts)
    local systemPromptRenderer, reminderRenderer, identityRenderer, safetyRenderer =
        prompt_registry.resolveCustomizations(opts)

    local instructions = getSystemPrompt(opts, systemPromptRenderer)

    local baseAgentInstructions = table.concat({
        'You are an expert AI programming assistant, working with a user in the Neovim editor.',
        identityRenderer(opts),
        safetyRenderer(),
        instructions,
    }, '\n')

    local baseInstructions = ''
    if not opts.omitBaseAgentInstructions then
        baseInstructions = baseAgentInstructions
    end

    -- Append reminder instructions from AgentUserMessage.
    local reminderPart = AgentUserMessage(opts, reminderRenderer)

    if reminderPart ~= '' then
        return baseInstructions .. '\n' .. reminderPart
    end
    return baseInstructions
end

return M

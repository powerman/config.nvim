--- GPT-5.2 agent prompt.
--- Ported from openai/gpt52Prompt.tsx.
--- Uses the same structure as gpt51 with minor differences.

local M = {}

local gpt51 = require 'custom.copilot.openai.gpt51_prompt'

--- GPT-5.2 uses the same prompt as GPT-5.1.
---@param opts Copilot.Options
---@return string
function M.Gpt52Prompt_render(opts)
    return gpt51.Gpt51Prompt_render(opts)
end

--- GPT-5.2 uses the same reminder as GPT-5.1.
---@param opts Copilot.Options
---@return string
function M.Gpt52ReminderInstructions_render(opts)
    return gpt51.Gpt51ReminderInstructions_render(opts)
end

--- Resolve for GPT-5.2.
---@param opts Copilot.Options
---@return fun(opts: Copilot.Options): string systemPrompt
---@return fun(opts: Copilot.Options): string reminderInstructions
function M.resolve(opts)
    return M.Gpt52Prompt_render, M.Gpt52ReminderInstructions_render
end

return M

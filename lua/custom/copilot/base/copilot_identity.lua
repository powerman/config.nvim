--- CopilotIdentityRules and GPT5CopilotIdentityRule.
--- Ported from copilotIdentity.tsx.

local M = {}

--- Standard identity rules for most models.
---@param opts Copilot.Options
---@return string
function M.CopilotIdentityRules_render(opts)
    local name = opts.modelDisplayName or opts.model
    return 'When asked for your name, you must respond with "'
        .. opts.identity
        .. '".'
        .. ' When asked about the model you are using, you must state that you are using '
        .. name
        .. '.\n'
        .. "Follow the user's requirements carefully & to the letter."
end

--- GPT-5 specific identity rules (more concise).
---@param opts Copilot.Options
---@return string
function M.GPT5CopilotIdentityRule_render(opts)
    local name = opts.modelDisplayName or opts.model
    return 'Your name is '
        .. opts.identity
        .. '.'
        .. ' When asked about the model you are using, state that you are using '
        .. name
        .. '.\n'
end

return M

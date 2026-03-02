--- Safety rules.
--- Ported from safetyRules.tsx.

local M = {}

---@return string
function M.SafetyRules_render()
    return 'Follow Microsoft content policies.\n'
        .. 'Avoid content that violates copyrights.\n'
        .. 'If you are asked to generate content that is harmful, hateful, racist, sexist, lewd, or violent,'
        .. ' only respond with "Sorry, I can\'t assist with that."\n'
        .. 'Keep your answers short and impersonal.\n'
end

---@return string
function M.Gpt5SafetyRule_render()
    return 'Follow Microsoft content policies.\n'
        .. 'Avoid content that violates copyrights.\n'
        .. 'If you are asked to generate content that is harmful, hateful, racist, sexist, lewd, or violent,'
        .. ' only respond with "Sorry, I can\'t assist with that."\n'
end

return M

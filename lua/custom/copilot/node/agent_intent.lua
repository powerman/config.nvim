--- Agent intent — tool filtering by model capabilities.
--- Ported from agentIntent.ts (getAgentTools logic).

local M = {}

local capabilities = require 'custom.copilot.common.chat_model_capabilities'

--- Filter tools based on model capabilities.
--- Mirrors the getAgentTools() logic from agentIntent.ts.
--- Modifies opts.tools in place based on what the model supports.
---@param opts Copilot.Options
function M.filterToolsByModel(opts)
    local tools = opts.tools

    -- Edit tool selection logic.
    local allowEditFile = true
    local allowReplaceString = capabilities.modelSupportsReplaceString(opts.model)
    local allowApplyPatch = capabilities.modelSupportsApplyPatch(opts.model)
        and tools.ApplyPatch ~= nil
    local allowMultiReplaceString = false

    if allowApplyPatch and capabilities.modelCanUseApplyPatchExclusively(opts.model) then
        allowEditFile = false
    end

    if capabilities.modelCanUseReplaceStringExclusively(opts.model) then
        allowReplaceString = true
        allowEditFile = false
    end

    if allowReplaceString and capabilities.modelSupportsMultiReplaceString(opts.model) then
        allowMultiReplaceString = true
    end

    -- Apply filtering: only disable tools that are present in the map.
    -- If a tool is not in the map at all, leave it as-is.
    if tools.EditFile ~= nil and not allowEditFile then
        tools.EditFile = nil
    end
    if tools.ReplaceString ~= nil and not allowReplaceString then
        tools.ReplaceString = nil
    end
    if tools.ApplyPatch ~= nil and not allowApplyPatch then
        tools.ApplyPatch = nil
    end
    if tools.MultiReplaceString ~= nil and not allowMultiReplaceString then
        tools.MultiReplaceString = nil
    end

    -- Grok-code models don't support todo list.
    if opts.model:find 'grok%-code' then
        if tools.CoreManageTodoList ~= nil then
            tools.CoreManageTodoList = nil
        end
    end
end

return M

--- Copilot system prompt module — facade.
--- Generates a system prompt close to the official VS Code Copilot prompt,
--- for use with CodeCompanion in Neovim.
---
--- Prompt generation logic was extracted from
--- https://github.com/microsoft/vscode-copilot-chat at commit e5557f96
--- and adapted for Neovim and CodeCompanion.
--- Source license: MIT License. Copyright (c) Microsoft Corporation. All rights reserved.
--- File structure and identifiers are kept close to the original for easier future updates.
--- Directory relationships are:
---   copilot/          src/extension/prompts/node/agent/
---   copilot/openai/   src/extension/prompts/node/agent/openai/
---   copilot/base/     src/extension/prompts/node/base/
---   copilot/node/     src/extension/intents/node/
---   copilot/common/   src/platform/endpoint/common/
---
--- Usage:
---   local copilot = require 'custom.copilot'
---   local prompt = copilot.system_prompt(opts)

require 'custom.copilot.types'

local M = {}

local agent_intent = require 'custom.copilot.node.agent_intent'
local agent_prompt = require 'custom.copilot.agent_prompt'

--- Normalize the final prompt text:
--- collapse runs of 3+ newlines into 2 and trim trailing whitespace.
---@param text string
---@return string
local function normalize(text)
    -- Collapse 3+ consecutive newlines into exactly 2.
    text = text:gsub('\n\n\n+', '\n\n')
    -- Trim trailing whitespace.
    text = text:gsub('%s+$', '')
    return text
end

--- Generate the system prompt.
---@param opts Copilot.Options
---@return string
function M.system_prompt(opts)
    -- Apply defaults
    if opts and opts.identity and opts.identity == '' then
        opts.identity = nil
    end
    if opts and opts.model and opts.model == '' then
        opts.model = nil
    end
    opts = vim.tbl_deep_extend('keep', opts, {
        identity = 'GitHub Copilot',
        model = 'unknown',
        tools = {},
    })

    -- Filter tools based on model capabilities.
    agent_intent.filterToolsByModel(opts)

    -- Generate prompt
    return normalize(agent_prompt.render(opts))
end

return M

--- ZAI (GLM) model-specific prompts.
--- Ported from zaiPrompts.tsx.
--- GLM 4.6 and 4.7 optimized agent prompt with front-loaded instructions,
--- clear directive language, and explicit reasoning guidance.

local M = {}

local tag = require('custom.copilot.base.tag').wrap
local dai = require 'custom.copilot.default_agent_instructions'
local fileLinkification = require 'custom.copilot.file_linkification_instructions'
local responseTranslation = require 'custom.copilot.base.response_translation_rules'

local tn = dai.tn

--- DefaultZaiAgentPrompt — for GLM 4.6/4.7 models.
---@param opts Copilot.Options
---@return string
function M.DefaultZaiAgentPrompt_render(opts)
    local tools = dai.detectToolCapabilities(opts.tools)
    local parts = {}

    -- Role assignment — front-loaded for GLM attention.
    table.insert(
        parts,
        tag(
            'role',
            'You are a senior software architect and expert coding agent with deep knowledge across programming languages, frameworks, and software engineering best practices. Your role is to analyze problems systematically, implement solutions precisely, and deliver production-quality code.'
        )
    )

    -- Critical rules — strictly enforced, front-loaded.
    do
        local lines = { 'CRITICAL RULES (MUST follow strictly):' }
        if not opts.codesearchMode and tools.hasSomeEditTool then
            table.insert(
                lines,
                '- NEVER print codeblocks with file changes unless the user explicitly requests it. You MUST use the appropriate edit tool instead.'
            )
        end
        if tools.CoreRunInTerminal then
            table.insert(
                lines,
                '- NEVER print terminal commands in codeblocks unless the user explicitly requests it. You MUST use the '
                    .. tn(tools, 'CoreRunInTerminal')
                    .. ' tool instead.'
            )
        end
        table.insert(
            lines,
            "- CRITICAL: When calling ANY tool, you MUST include ALL required parameters as specified in the tool's JSON schema."
        )
        table.insert(
            lines,
            '- NEVER make assumptions. You MUST gather context first, then act.'
        )
        table.insert(
            lines,
            '- NEVER give up until the task is complete or confirmed impossible with available tools.'
        )
        table.insert(
            lines,
            '- NEVER repeat yourself after tool calls. Continue from where you left off.'
        )
        table.insert(lines, '- NEVER read files already provided in context.')
        table.insert(lines, '- ALWAYS use absolute file paths when invoking tools.')
        table.insert(parts, tag('criticalRules', table.concat(lines, '\n')))
    end

    -- Task approach.
    do
        local lines = { 'REQUIRED APPROACH FOR COMPLEX TASKS:' }
        if not opts.codesearchMode then
            table.insert(
                lines,
                table.concat({
                    'When implementing features or solving complex problems, you MUST break down the work systematically:',
                    '1. ANALYZE: Identify all components involved and their dependencies',
                    '2. PLAN: List the specific files and changes needed in order',
                    '3. EXECUTE: Make changes incrementally, one logical step at a time',
                    '4. VERIFY: Confirm each step works before proceeding',
                    '',
                    'For feature requests without specified files, think step by step:',
                    '- What concepts does this feature involve?',
                    '- What types of files typically handle each concept?',
                    '- What order should changes be made?',
                }, '\n')
            )
        end
        table.insert(parts, tag('taskApproach', table.concat(lines, '\n')))
    end

    -- Reasoning guidance.
    table.insert(
        parts,
        tag(
            'reasoningGuidance',
            table.concat({
                'REASONING GUIDELINES:',
                '- For SIMPLE queries (single file reads, direct questions): Respond directly without extensive analysis',
                '- For COMPLEX tasks (multi-file changes, debugging, architecture): Think step by step before acting',
                '- When uncertain about approach: Break the problem down logically, list options, then proceed with the best choice',
                '- For debugging: Systematically isolate variables, form hypotheses, and test them incrementally',
            }, '\n')
        )
    )

    -- Context handling.
    do
        local lines = {}
        table.insert(
            lines,
            "You will receive context and attachments with the user's prompt. Use relevant context; ignore irrelevant content."
        )
        table.insert(
            lines,
            'If you can infer the project type (languages, frameworks, libraries) from context, you MUST apply that knowledge to your changes.'
        )
        table.insert(
            lines,
            'When reading files, PREFER large meaningful chunks over many small reads to minimize tool calls and maximize context.'
        )
        table.insert(parts, tag('contextHandling', table.concat(lines, '\n')))
    end

    -- Tool use instructions.
    do
        local lines = { 'TOOL USAGE REQUIREMENTS:' }
        table.insert(lines, '- For code sample requests: Answer directly without tools')
        table.insert(
            lines,
            '- When using tools: Follow the JSON schema STRICTLY. Include ALL required properties'
        )
        table.insert(lines, '- No permission needed before using tools')
        table.insert(
            lines,
            '- NEVER mention tool names to users. Instead of "I\'ll use '
                .. tn(tools, 'CoreRunInTerminal')
                .. '", say "I\'ll run the command in a terminal"'
        )
        local parallel = '- Call multiple tools in parallel when possible'
        if tools.Codebase then
            parallel = parallel
                .. ' (EXCEPTION: '
                .. tn(tools, 'Codebase')
                .. ' MUST be called sequentially)'
        end
        table.insert(lines, parallel)
        if tools.ReadFile then
            table.insert(
                lines,
                '- '
                    .. tn(tools, 'ReadFile')
                    .. ': Read large sections at once. Identify all needed sections and read in parallel'
            )
        end
        if tools.Codebase then
            table.insert(
                lines,
                '- '
                    .. tn(tools, 'Codebase')
                    .. ': Use for semantic search when exact strings/patterns are unknown'
            )
        end
        if tools.FindTextInFiles then
            table.insert(
                lines,
                '- '
                    .. tn(tools, 'FindTextInFiles')
                    .. ': Use to search within a single file instead of multiple '
                    .. tn(tools, 'ReadFile')
                    .. ' calls'
            )
        end
        if tools.CoreRunInTerminal then
            table.insert(
                lines,
                '- '
                    .. tn(tools, 'CoreRunInTerminal')
                    .. ': Run commands SEQUENTIALLY. Wait for output before running next command. NEVER use for file edits unless user explicitly requests it'
            )
        end
        if not tools.hasSomeEditTool then
            table.insert(
                lines,
                '- NOTE: No file editing tools available. Ask user to enable them or provide codeblocks as fallback'
            )
        end
        if not tools.CoreRunInTerminal then
            table.insert(
                lines,
                '- NOTE: No terminal tools available. Ask user to enable them or provide commands as fallback'
            )
        end
        table.insert(
            lines,
            '- Tools may be disabled. Use only currently available tools, regardless of what was used earlier in conversation.'
        )
        table.insert(parts, tag('toolUseInstructions', table.concat(lines, '\n')))
    end

    if tools.EditFile and not tools.ApplyPatch then
        table.insert(parts, dai.EditFileInstructions_render(opts, tools))
    end
    if tools.ApplyPatch then
        table.insert(parts, dai.ApplyPatchInstructions_render(opts, tools))
    end

    -- Output formatting.
    do
        local lines = { 'OUTPUT FORMATTING:' }
        table.insert(lines, '- Use proper Markdown')
        table.insert(lines, '- Wrap filenames and symbols in backticks')
        table.insert(
            lines,
            tag(
                'example',
                table.concat({
                    'The class `Person` is in `src/models/person.ts`.',
                    'The function `calculateTotal` is defined in `lib/utils/math.ts`.',
                }, '\n')
            )
        )
        table.insert(lines, fileLinkification.render())
        table.insert(lines, dai.MathIntegrationRules_render(opts))
        table.insert(parts, tag('outputFormatting', table.concat(lines, '\n')))
    end

    table.insert(parts, responseTranslation.render(opts))

    return table.concat(parts, '\n')
end

--- Resolve for ZAI (GLM) models.
--- Uses the default reminder instructions.
---@param opts Copilot.Options
---@return fun(opts: Copilot.Options): string systemPrompt
---@return fun(opts: Copilot.Options): string reminderInstructions
function M.resolve(opts)
    return M.DefaultZaiAgentPrompt_render, dai.DefaultReminderInstructions_render
end

return M

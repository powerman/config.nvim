---@module 'luassert'

describe('copilot system prompt', function()
    local copilot = require 'custom.copilot'

    describe('basic rendering', function()
        it('renders a prompt for unknown model', function()
            local prompt = copilot.system_prompt {
                model = 'unknown',
                tools = {},
            }
            assert.is_string(prompt)
            assert.truthy(prompt:find 'GitHub Copilot')
            assert.truthy(prompt:find 'expert AI programming assistant')
        end)

        it('omits base instructions when omitBaseAgentInstructions is set', function()
            local prompt = copilot.system_prompt {
                model = 'unknown',
                tools = {},
                omitBaseAgentInstructions = true,
            }
            assert.is_string(prompt)
            assert.falsy(prompt:find 'expert AI programming assistant')
        end)
    end)

    describe('model-specific prompts', function()
        it('uses Anthropic prompt for claude models', function()
            local prompt = copilot.system_prompt {
                model = 'claude-sonnet-4',
                tools = {
                    ReadFile = 'read_file',
                    EditFile = 'insert_edit_into_file',
                },
            }
            assert.truthy(prompt:find 'GitHub Copilot')
            -- Anthropic prompts include fileLinkification
            assert.truthy(prompt:find 'fileLinkification')
        end)

        it('uses Claude 4.6 prompt for newer claude models', function()
            local prompt = copilot.system_prompt {
                model = 'claude-4.6-sonnet',
                tools = {
                    ReadFile = 'read_file',
                },
            }
            assert.truthy(prompt:find 'securityRequirements')
            assert.truthy(prompt:find 'operationalSafety')
            assert.truthy(prompt:find 'implementationDiscipline')
        end)

        it('uses Gemini prompt for gemini models', function()
            local prompt = copilot.system_prompt {
                model = 'gemini-2.5-pro',
                tools = {
                    ReadFile = 'read_file',
                    ReplaceString = 'replace_string_in_file',
                    EditFile = 'insert_edit_into_file',
                },
            }
            assert.truthy(prompt:find 'GitHub Copilot')
            assert.truthy(prompt:find 'fileLinkification')
        end)

        it('uses GPT-5 prompt for gpt-5', function()
            local prompt = copilot.system_prompt {
                model = 'gpt-5',
                tools = {
                    ApplyPatch = 'apply_patch',
                    ReadFile = 'read_file',
                },
            }
            assert.truthy(prompt:find 'coding_agent_instructions')
            assert.truthy(prompt:find 'coding agent running in Neovim')
        end)

        it('uses GPT-5.1 prompt for gpt-5.1', function()
            local prompt = copilot.system_prompt {
                model = 'gpt-5.1',
                tools = {
                    ApplyPatch = 'apply_patch',
                    ReadFile = 'read_file',
                },
            }
            assert.truthy(prompt:find 'autonomy_and_persistence')
            assert.truthy(prompt:find 'Persist until the task is fully handled')
        end)

        it('uses OpenAI prompt for gpt-4o', function()
            local prompt = copilot.system_prompt {
                model = 'gpt-4o',
                tools = {
                    ReadFile = 'read_file',
                    EditFile = 'insert_edit_into_file',
                },
            }
            assert.truthy(prompt:find 'keep going until')
            assert.truthy(prompt:find 'fileLinkification')
        end)

        it('uses AlternateGPTPrompt when enabled for gpt models', function()
            local prompt = copilot.system_prompt {
                model = 'gpt-4o',
                tools = {
                    ReadFile = 'read_file',
                },
                enableAlternateGptPrompt = true,
            }
            assert.truthy(prompt:find 'structuredWorkflow')
            assert.truthy(prompt:find 'communicationGuidelines')
        end)

        it('uses xAI prompt for grok-code models', function()
            local prompt = copilot.system_prompt {
                model = 'grok-code',
                tools = {
                    ReadFile = 'read_file',
                    EditFile = 'insert_edit_into_file',
                },
            }
            -- Grok prompt has unique validation/green-before-done instructions.
            assert.truthy(prompt:find 'Validation and green%-before%-done')
            assert.truthy(prompt:find 'Never invent file paths')
            assert.truthy(prompt:find 'fileLinkification')
        end)

        it('uses ZAI prompt for GLM models', function()
            local prompt = copilot.system_prompt {
                model = 'glm-4.7',
                tools = {
                    ReadFile = 'read_file',
                    EditFile = 'insert_edit_into_file',
                },
            }
            -- ZAI prompt has unique role and critical rules tags.
            assert.truthy(prompt:find '<role>')
            assert.truthy(prompt:find 'senior software architect')
            assert.truthy(prompt:find '<criticalRules>')
            assert.truthy(prompt:find '<reasoningGuidance>')
        end)

        it('uses GPT-5 Codex prompt for gpt-5-codex', function()
            local prompt = copilot.system_prompt {
                model = 'gpt-5-codex',
                tools = {
                    ReadFile = 'read_file',
                },
            }
            assert.truthy(prompt:find 'coding agent based on GPT%-5%-Codex')
            assert.truthy(prompt:find '<editingConstraints>')
        end)

        it('uses GPT-5.1 Codex prompt for gpt-5.1-codex', function()
            local prompt = copilot.system_prompt {
                model = 'gpt-5.1-codex',
                tools = {
                    ApplyPatch = 'apply_patch',
                    ReadFile = 'read_file',
                },
            }
            assert.truthy(prompt:find '<editing_constraints>')
            assert.truthy(prompt:find '<exploration_and_reading_files>')
            assert.truthy(prompt:find 'Batch everything')
        end)

        it('uses GPT-5.3 Codex prompt for gpt-5.3-codex', function()
            local prompt = copilot.system_prompt {
                model = 'gpt-5.3-codex',
                tools = {
                    ApplyPatch = 'apply_patch',
                    ReadFile = 'read_file',
                },
            }
            assert.truthy(prompt:find '<autonomy_and_persistence>')
            assert.truthy(prompt:find '<ambition_vs_precision>')
            assert.truthy(prompt:find 'surgical precision')
        end)
    end)

    describe('tool-dependent instructions', function()
        it('includes ApplyPatch instructions when tool is available', function()
            local prompt = copilot.system_prompt {
                model = 'gpt-4.1',
                tools = {
                    ApplyPatch = 'apply_patch',
                    ReadFile = 'read_file',
                },
            }
            assert.truthy(prompt:find 'applyPatchInstructions')
            assert.truthy(prompt:find 'apply_patch')
        end)

        it('includes EditFile instructions when ApplyPatch is not available', function()
            local prompt = copilot.system_prompt {
                model = 'unknown',
                tools = {
                    EditFile = 'insert_edit_into_file',
                    ReadFile = 'read_file',
                },
            }
            assert.truthy(prompt:find 'editFileInstructions')
            assert.truthy(prompt:find 'insert_edit_into_file')
        end)

        it('uses CodeCompanion tool names in instructions', function()
            local prompt = copilot.system_prompt {
                model = 'unknown',
                tools = {
                    CoreRunInTerminal = 'cmd',
                    ReadFile = 'read_file',
                },
            }
            -- Should use the CodeCompanion name "cmd" not the Copilot name "run_in_terminal"
            assert.truthy(prompt:find 'cmd')
        end)

        it('includes terminal instructions only when tool is available', function()
            local prompt_with = copilot.system_prompt {
                model = 'unknown',
                tools = { CoreRunInTerminal = 'cmd' },
            }
            local prompt_without = copilot.system_prompt {
                model = 'unknown',
                tools = {},
            }
            assert.truthy(
                prompt_with:find 'NEVER print out a codeblock with a terminal command'
            )
            assert.falsy(
                prompt_without:find 'NEVER print out a codeblock with a terminal command'
            )
        end)
    end)

    describe('tool filtering by model', function()
        it('disables EditFile for models that use ApplyPatch exclusively', function()
            local opts = {
                model = 'gpt-5',
                tools = {
                    EditFile = 'insert_edit_into_file',
                    ApplyPatch = 'apply_patch',
                    ReadFile = 'read_file',
                },
            }
            local prompt = copilot.system_prompt(opts)
            -- GPT-5 can use ApplyPatch exclusively, so EditFile should be disabled
            assert.truthy(prompt:find 'applyPatchInstructions')
            -- Should NOT contain editFileInstructions since EditFile is disabled
            assert.falsy(prompt:find 'editFileInstructions')
        end)

        it('enables ReplaceString for Anthropic models', function()
            local opts = {
                model = 'claude-sonnet-4',
                tools = {
                    EditFile = 'insert_edit_into_file',
                    ReplaceString = 'replace_string_in_file',
                    MultiReplaceString = 'multi_replace_string_in_file',
                    ReadFile = 'read_file',
                },
            }
            local prompt = copilot.system_prompt(opts)
            -- Anthropic supports multi replace string
            assert.truthy(prompt:find 'multi_replace_string_in_file')
        end)
    end)

    describe('locale support', function()
        it('adds response translation for non-English locale', function()
            local prompt = copilot.system_prompt {
                model = 'unknown',
                tools = {},
                locale = 'ru',
            }
            assert.truthy(prompt:find 'Respond in the following locale: ru')
        end)

        it('does not add translation for English locale', function()
            local prompt = copilot.system_prompt {
                model = 'unknown',
                tools = {},
                locale = 'en',
            }
            assert.falsy(prompt:find 'Respond in the following locale')
        end)
    end)

    describe('math support', function()
        it('includes KaTeX instructions when mathEnabled', function()
            local prompt = copilot.system_prompt {
                model = 'unknown',
                tools = {},
                mathEnabled = true,
            }
            assert.truthy(prompt:find 'LaTeX')
        end)

        it('excludes KaTeX instructions by default', function()
            local prompt = copilot.system_prompt {
                model = 'unknown',
                tools = {},
            }
            assert.falsy(prompt:find 'LaTeX')
        end)
    end)

    describe('reminder instructions', function()
        it('includes reminder instructions in the prompt', function()
            local prompt = copilot.system_prompt {
                model = 'gpt-4.1',
                tools = {
                    EditFile = 'insert_edit_into_file',
                    ReplaceString = 'replace_string_in_file',
                },
            }
            assert.truthy(prompt:find 'reminderInstructions')
        end)

        it('includes Gemini-specific reminder', function()
            local prompt = copilot.system_prompt {
                model = 'gemini-2.5-pro',
                tools = {
                    ReplaceString = 'replace_string_in_file',
                    EditFile = 'insert_edit_into_file',
                },
            }
            assert.truthy(prompt:find 'MUST use the tool%-calling mechanism')
        end)

        it('includes OpenAI keep-going reminder', function()
            local prompt = copilot.system_prompt {
                model = 'gpt-4o',
                tools = {},
            }
            assert.truthy(prompt:find 'keep going until')
        end)

        it('includes Anthropic-specific reminder', function()
            local prompt = copilot.system_prompt {
                model = 'claude-sonnet-4',
                tools = {
                    ReplaceString = 'replace_string_in_file',
                    MultiReplaceString = 'multi_replace_string_in_file',
                },
            }
            assert.truthy(prompt:find 'Do NOT create a new markdown file')
        end)

        it('includes GPT-5.3 Codex reminder', function()
            local prompt = copilot.system_prompt {
                model = 'gpt-5.3-codex',
                tools = {
                    ApplyPatch = 'apply_patch',
                },
            }
            assert.truthy(prompt:find 'Tool batches')
            assert.truthy(prompt:find 'Progress cadence')
        end)
    end)

    describe('output normalization', function()
        it('does not end with trailing whitespace', function()
            local prompt = copilot.system_prompt {
                model = 'unknown',
                tools = {},
            }
            assert.falsy(prompt:find '%s+$')
        end)

        it('does not contain more than 2 consecutive newlines', function()
            local prompt = copilot.system_prompt {
                model = 'gpt-5',
                tools = {
                    ApplyPatch = 'apply_patch',
                    ReadFile = 'read_file',
                    CoreRunInTerminal = 'cmd',
                    CoreManageTodoList = 'todo',
                },
            }
            assert.falsy(prompt:find '\n\n\n')
        end)
    end)
end)

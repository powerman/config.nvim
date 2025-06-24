---@module 'luassert'

describe('auto_approve', function()
    local auto_approve = require 'auto_approve'
    local project_root = vim.fn.tempname()
    vim.fn.mkdir(project_root, 'p')

    before_each(function()
        auto_approve.setup()
    end)

    describe('setup', function()
        it('uses default config when no options provided', function()
            assert.same({
                allowed_cmds = nil,
                project_root = nil,
                codecompanion = {
                    cmd_runner = true,
                    create_file = true,
                    insert_edit_into_file = true,
                    read_file = true,
                },
                mcphub_neovim = true,
            }, auto_approve.config)
        end)

        it('merges user config with defaults', function()
            auto_approve.setup {
                allowed_cmds = { 'ls' },
                project_root = '/tmp',
                codecompanion = {
                    cmd_runner = false,
                },
            }
            assert.same({
                allowed_cmds = { 'ls' },
                project_root = '/tmp',
                codecompanion = {
                    cmd_runner = false,
                    create_file = true,
                    insert_edit_into_file = true,
                    read_file = true,
                },
                mcphub_neovim = true,
            }, auto_approve.config)
        end)
    end)

    describe('cmd_runner', function()
        it('requires approval for non-allowed commands', function()
            auto_approve.setup { allowed_cmds = { 'ls' } }
            local requires_approval = auto_approve.cmd_runner { args = { cmd = 'rm' } }
            assert.is_true(requires_approval)
        end)

        it('auto-approves allowed commands', function()
            auto_approve.setup { allowed_cmds = { 'ls' } }
            local requires_approval = auto_approve.cmd_runner { args = { cmd = 'ls' } }
            assert.is_false(requires_approval)
        end)
    end)

    describe('filepath', function()
        it('requires approval for paths outside project root', function()
            auto_approve.setup { project_root = project_root }
            local requires_approval =
                auto_approve.filepath { args = { filepath = '/tmp/other/file.txt' } }
            assert.is_true(requires_approval)
        end)

        it('auto-approves paths inside project root', function()
            auto_approve.setup { project_root = project_root }
            local requires_approval =
                auto_approve.filepath { args = { filepath = project_root .. '/file.txt' } }
            assert.is_false(requires_approval)
        end)

        it('requires approval when project_root is not set', function()
            auto_approve.setup { project_root = nil }
            local requires_approval =
                auto_approve.filepath { args = { filepath = '/any/path' } }
            assert.is_true(requires_approval)
        end)
    end)

    describe('mcphub', function()
        it('auto-approves when CodeCompanion auto tool mode is on', function()
            vim.g.codecompanion_auto_tool_mode = true
            local approved = auto_approve.mcphub {}
            assert.is_true(approved)

            vim.g.codecompanion_auto_tool_mode = nil
            approved = auto_approve.mcphub {}
            assert.is_nil(approved)
        end)

        it('auto-approves when MCPHub auto tool mode is on', function()
            local approved = auto_approve.mcphub { is_auto_approved_in_server = true }
            assert.is_true(approved)

            approved = auto_approve.mcphub { is_auto_approved_in_server = false }
            assert.is_false(approved)
        end)

        it('auto-approves when enabled', function()
            local params = {
                server_name = 'neovim',
                tool_name = 'read_file',
                arguments = { path = project_root .. '/file.txt' },
            }

            auto_approve.setup { mcphub_neovim = true, project_root = project_root }
            local approved = auto_approve.mcphub(params)
            assert.is_true(approved)

            auto_approve.setup { mcphub_neovim = false, project_root = project_root }
            approved = auto_approve.mcphub(params)
            assert.is_nil(approved)
        end)

        it('checks project path for file operations', function()
            auto_approve.setup { project_root = project_root }

            local approved = auto_approve.mcphub {
                server_name = 'neovim',
                tool_name = 'read_file',
                arguments = { path = project_root .. '/file.txt' },
            }
            assert.is_true(approved)

            approved = auto_approve.mcphub {
                server_name = 'neovim',
                tool_name = 'read_file',
                arguments = { path = project_root .. '/../file.txt' },
            }
            assert.is_nil(approved)
        end)

        it('checks allowed commands for execute_command', function()
            auto_approve.setup {
                project_root = project_root,
                allowed_cmds = { 'ls' },
                mcphub_neovim = true,
            }

            local approved = auto_approve.mcphub {
                server_name = 'neovim',
                tool_name = 'execute_command',
                arguments = { cwd = project_root, command = 'ls' },
            }
            assert.is_true(approved)

            approved = auto_approve.mcphub {
                server_name = 'neovim',
                tool_name = 'execute_command',
                arguments = { cwd = project_root, command = 'pwd' },
            }
            assert.is_nil(approved)
        end)

        it('checks both paths for move_item operations', function()
            auto_approve.setup { project_root = project_root }

            local test_cases = {
                {
                    name = 'both paths in project root',
                    path = project_root .. '/source.txt',
                    new_path = project_root .. '/dest.txt',
                    expected = true,
                },
                {
                    name = 'source outside project root',
                    path = '/tmp/source.txt',
                    new_path = project_root .. '/dest.txt',
                    expected = nil,
                },
                {
                    name = 'destination outside project root',
                    path = project_root .. '/source.txt',
                    new_path = '/tmp/dest.txt',
                    expected = nil,
                },
                {
                    name = 'both paths outside project root',
                    path = '/tmp/source.txt',
                    new_path = '/var/dest.txt',
                    expected = nil,
                },
            }

            for _, tc in ipairs(test_cases) do
                local args = {
                    server_name = 'neovim',
                    tool_name = 'move_item',
                    arguments = {
                        path = tc.path,
                        new_path = tc.new_path,
                    },
                }
                local approved = auto_approve.mcphub(args)
                assert.equal(tc.expected, approved)
            end
        end)
    end)
end)

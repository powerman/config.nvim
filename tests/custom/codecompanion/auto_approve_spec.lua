---@module 'luassert'

describe('auto_approve', function()
    local auto_approve = require 'custom.codecompanion.auto_approve'
    local project_root = vim.fn.tempname()
    vim.fn.mkdir(project_root, 'p')

    before_each(function()
        auto_approve.setup()
    end)

    describe('setup', function()
        it('uses default config when no options provided', function()
            assert.same({
                allowed_cmds = nil,
                secret_files = {
                    '.env*',
                    'env*.sh',
                },
                project_root = nil,
                codecompanion = {
                    cmd_runner = true,
                    create_file = true,
                    insert_edit_into_file = true,
                    read_file = true,
                },
                mcphub_neovim = true,
                mcphub_filesystem = true,
                mcphub_git = true,
                mcphub_shell = true,
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
                secret_files = {
                    '.env*',
                    'env*.sh',
                },
                project_root = '/tmp',
                codecompanion = {
                    cmd_runner = false,
                    create_file = true,
                    insert_edit_into_file = true,
                    read_file = true,
                },
                mcphub_neovim = true,
                mcphub_filesystem = true,
                mcphub_git = true,
                mcphub_shell = true,
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

        describe('cd prefix handling', function()
            it('auto-approves allowed commands with cd prefix', function()
                auto_approve.setup {
                    allowed_cmds = { 'npm test' },
                    project_root = project_root,
                }
                local cmd = 'cd ' .. project_root .. ' && npm test'
                local requires_approval = auto_approve.cmd_runner { args = { cmd = cmd } }
                assert.is_false(requires_approval)
            end)

            it('requires approval for non-allowed commands with cd prefix', function()
                auto_approve.setup {
                    allowed_cmds = { 'npm test' },
                    project_root = project_root,
                }
                local cmd = 'cd ' .. project_root .. ' && npm build'
                local requires_approval = auto_approve.cmd_runner { args = { cmd = cmd } }
                assert.is_true(requires_approval)
            end)

            it('ignores cd prefix when project_root is not set', function()
                auto_approve.setup {
                    allowed_cmds = { 'npm test' },
                    project_root = nil,
                }
                local cmd = 'cd /some/path && npm test'
                local requires_approval = auto_approve.cmd_runner { args = { cmd = cmd } }
                assert.is_true(requires_approval)
            end)

            it('ignores cd prefix when project_root is empty', function()
                auto_approve.setup {
                    allowed_cmds = { 'npm test' },
                    project_root = '',
                }
                local cmd = 'cd /some/path && npm test'
                local requires_approval = auto_approve.cmd_runner { args = { cmd = cmd } }
                assert.is_true(requires_approval)
            end)

            it('handles multiple commands with different prefixes', function()
                auto_approve.setup {
                    allowed_cmds = { 'ls', 'pwd' },
                    project_root = project_root,
                }

                local test_cases = {
                    { cmd = 'cd ' .. project_root .. ' && ls', expected = false },
                    { cmd = 'cd ' .. project_root .. ' && pwd', expected = false },
                    { cmd = 'cd ' .. project_root .. ' && rm', expected = true },
                    { cmd = 'cd /other/path && ls', expected = true },
                    { cmd = 'ls', expected = false },
                    { cmd = 'rm', expected = true },
                }

                for _, tc in ipairs(test_cases) do
                    local requires_approval =
                        auto_approve.cmd_runner { args = { cmd = tc.cmd } }
                    assert.equal(
                        tc.expected,
                        requires_approval,
                        'Failed for command: ' .. tc.cmd
                    )
                end
            end)

            it('handles complex allowed commands with cd prefix', function()
                auto_approve.setup {
                    allowed_cmds = { 'npm run test:unit', 'docker compose up' },
                    project_root = project_root,
                }

                local test_cases = {
                    {
                        cmd = 'cd ' .. project_root .. ' && npm run test:unit',
                        expected = false,
                    },
                    {
                        cmd = 'cd ' .. project_root .. ' && docker compose up',
                        expected = false,
                    },
                    { cmd = 'cd ' .. project_root .. ' && npm run build', expected = true },
                    { cmd = 'npm run test:unit', expected = false },
                    { cmd = 'docker compose up', expected = false },
                }

                for _, tc in ipairs(test_cases) do
                    local requires_approval =
                        auto_approve.cmd_runner { args = { cmd = tc.cmd } }
                    assert.equal(
                        tc.expected,
                        requires_approval,
                        'Failed for command: ' .. tc.cmd
                    )
                end
            end)
        end)
    end)

    describe('filepath', function()
        describe('project root checks', function()
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

        describe('secret files checks', function()
            it('requires approval for secret files with default patterns', function()
                auto_approve.setup { project_root = project_root }
                local test_cases = {
                    { filepath = project_root .. '/.env', expected = true },
                    { filepath = project_root .. '/.env.local', expected = true },
                    { filepath = project_root .. '/env.sh', expected = true },
                    { filepath = project_root .. '/env-prod.sh', expected = true },
                    { filepath = project_root .. '/regular-file.txt', expected = false },
                }

                for _, tc in ipairs(test_cases) do
                    local requires_approval =
                        auto_approve.filepath { args = { filepath = tc.filepath } }
                    assert.equal(
                        tc.expected,
                        requires_approval,
                        'Failed for file: ' .. tc.filepath
                    )
                end
            end)

            it('respects custom secret_files patterns', function()
                auto_approve.setup {
                    project_root = project_root,
                    secret_files = {
                        '*.key',
                        'credentials.json',
                    },
                }

                local test_cases = {
                    { filepath = project_root .. '/config.key', expected = true },
                    { filepath = project_root .. '/credentials.json', expected = true },
                    { filepath = project_root .. '/.env', expected = false },
                    { filepath = project_root .. '/regular-file.txt', expected = false },
                }

                for _, tc in ipairs(test_cases) do
                    local requires_approval =
                        auto_approve.filepath { args = { filepath = tc.filepath } }
                    assert.equal(
                        tc.expected,
                        requires_approval,
                        'Failed for file: ' .. tc.filepath
                    )
                end
            end)

            it('works with empty secret_files list', function()
                auto_approve.setup {
                    project_root = project_root,
                    secret_files = {},
                }

                local requires_approval = auto_approve.filepath {
                    args = { filepath = project_root .. '/.env' },
                }
                assert.is_false(requires_approval)
            end)

            it('uses default secret_files when nil', function()
                auto_approve.setup {
                    project_root = project_root,
                    secret_files = nil,
                }

                local requires_approval = auto_approve.filepath {
                    args = { filepath = project_root .. '/.env' },
                }
                assert.is_true(
                    requires_approval,
                    'Should block .env file using default patterns'
                )
            end)
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

        it('checks allowed commands for execute_command with cd prefix', function()
            auto_approve.setup {
                project_root = project_root,
                allowed_cmds = { 'npm test' },
                mcphub_neovim = true,
            }

            local test_cases = {
                { command = 'cd ' .. project_root .. ' && npm test', expected = true },
                { command = 'cd ' .. project_root .. ' && npm build', expected = nil },
                { command = 'cd /other/path && npm test', expected = nil },
                { command = 'npm test', expected = true },
            }

            for _, tc in ipairs(test_cases) do
                local approved = auto_approve.mcphub {
                    server_name = 'neovim',
                    tool_name = 'execute_command',
                    arguments = { cwd = project_root, command = tc.command },
                }
                assert.equal(tc.expected, approved, 'Failed for command: ' .. tc.command)
            end
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

        describe('filesystem server', function()
            it('auto-approves when enabled', function()
                local params = {
                    server_name = 'filesystem',
                    tool_name = 'read_file',
                    arguments = { path = project_root .. '/file.txt' },
                }

                auto_approve.setup { mcphub_filesystem = true, project_root = project_root }
                local approved = auto_approve.mcphub(params)
                assert.is_true(approved)

                auto_approve.setup { mcphub_filesystem = false, project_root = project_root }
                approved = auto_approve.mcphub(params)
                assert.is_nil(approved)
            end)

            it('checks paths for read_multiple_files', function()
                auto_approve.setup { mcphub_filesystem = true, project_root = project_root }

                local params = {
                    server_name = 'filesystem',
                    tool_name = 'read_multiple_files',
                    arguments = {
                        paths = {
                            project_root .. '/file1.txt',
                            project_root .. '/file2.txt',
                        },
                    },
                }
                local approved = auto_approve.mcphub(params)
                assert.is_true(approved)

                params.arguments.paths[2] = '/tmp/file2.txt'
                approved = auto_approve.mcphub(params)
                assert.is_nil(approved)
            end)

            it('checks paths for move_file', function()
                auto_approve.setup { mcphub_filesystem = true, project_root = project_root }

                local test_cases = {
                    {
                        name = 'both paths in project root',
                        source = project_root .. '/source.txt',
                        destination = project_root .. '/dest.txt',
                        expected = true,
                    },
                    {
                        name = 'source outside project root',
                        source = '/tmp/source.txt',
                        destination = project_root .. '/dest.txt',
                        expected = nil,
                    },
                    {
                        name = 'destination outside project root',
                        source = project_root .. '/source.txt',
                        destination = '/tmp/dest.txt',
                        expected = nil,
                    },
                }

                for _, tc in ipairs(test_cases) do
                    local approved = auto_approve.mcphub {
                        server_name = 'filesystem',
                        tool_name = 'move_file',
                        arguments = {
                            source = tc.source,
                            destination = tc.destination,
                        },
                    }
                    assert.equal(tc.expected, approved, tc.name)
                end
            end)
        end)

        describe('git server', function()
            it('auto-approves when enabled', function()
                local params = {
                    server_name = 'git',
                    tool_name = 'git_status',
                    arguments = { repo_path = project_root },
                }

                auto_approve.setup { mcphub_git = true, project_root = project_root }
                local approved = auto_approve.mcphub(params)
                assert.is_true(approved)

                auto_approve.setup { mcphub_git = false, project_root = project_root }
                approved = auto_approve.mcphub(params)
                assert.is_nil(approved)
            end)

            it('checks repo_path for git operations', function()
                auto_approve.setup { mcphub_git = true, project_root = project_root }

                local test_cases = {
                    {
                        name = 'repo inside project root',
                        repo_path = project_root,
                        expected = true,
                    },
                    {
                        name = 'repo outside project root',
                        repo_path = '/tmp/repo',
                        expected = nil,
                    },
                }

                for _, tc in ipairs(test_cases) do
                    local approved = auto_approve.mcphub {
                        server_name = 'git',
                        tool_name = 'git_status',
                        arguments = { repo_path = tc.repo_path },
                    }
                    assert.equal(tc.expected, approved, tc.name)
                end
            end)

            it('checks repo_path for all git operations', function()
                auto_approve.setup { mcphub_git = true, project_root = project_root }

                local git_tools = {
                    'git_status',
                    'git_diff_unstaged',
                    'git_diff_staged',
                    'git_diff',
                    'git_log',
                    'git_show',
                }

                local params = {
                    server_name = 'git',
                    arguments = { repo_path = project_root },
                }
                for _, tool_name in ipairs(git_tools) do
                    params.tool_name = tool_name
                    local approved = auto_approve.mcphub(params)
                    assert.is_true(approved, 'Failed for ' .. tool_name)
                end
            end)
        end)

        describe('shell server', function()
            it('auto-approves when enabled', function()
                local params = {
                    server_name = 'shell',
                    tool_name = 'shell_exec',
                    arguments = { command = 'ls' },
                }

                auto_approve.setup { mcphub_shell = true, allowed_cmds = { 'ls' } }
                local approved = auto_approve.mcphub(params)
                assert.is_true(approved)

                auto_approve.setup { mcphub_shell = false, allowed_cmds = { 'ls' } }
                approved = auto_approve.mcphub(params)
                assert.is_nil(approved)
            end)

            it('checks allowed commands for shell operations', function()
                auto_approve.setup { mcphub_shell = true, allowed_cmds = { 'ls' } }

                local test_cases = {
                    {
                        name = 'allowed command',
                        command = 'ls',
                        expected = true,
                    },
                    {
                        name = 'not allowed command',
                        command = 'rm',
                        expected = nil,
                    },
                }

                for _, tc in ipairs(test_cases) do
                    local approved = auto_approve.mcphub {
                        server_name = 'shell',
                        tool_name = 'shell_exec',
                        arguments = { command = tc.command },
                    }
                    assert.equal(tc.expected, approved, tc.name)
                end
            end)

            describe('cd prefix handling', function()
                it('auto-approves allowed commands with cd prefix', function()
                    auto_approve.setup {
                        mcphub_shell = true,
                        allowed_cmds = { 'npm test' },
                        project_root = project_root,
                    }

                    local cmd = 'cd ' .. project_root .. ' && npm test'
                    local approved = auto_approve.mcphub {
                        server_name = 'shell',
                        tool_name = 'shell_exec',
                        arguments = { command = cmd },
                    }
                    assert.is_true(approved)
                end)

                it('requires approval for non-allowed commands with cd prefix', function()
                    auto_approve.setup {
                        mcphub_shell = true,
                        allowed_cmds = { 'npm test' },
                        project_root = project_root,
                    }

                    local cmd = 'cd ' .. project_root .. ' && npm build'
                    local approved = auto_approve.mcphub {
                        server_name = 'shell',
                        tool_name = 'shell_exec',
                        arguments = { command = cmd },
                    }
                    assert.is_nil(approved)
                end)

                it('handles mixed commands with and without cd prefix', function()
                    auto_approve.setup {
                        mcphub_shell = true,
                        allowed_cmds = { 'ls', 'pwd' },
                        project_root = project_root,
                    }

                    local test_cases = {
                        { command = 'cd ' .. project_root .. ' && ls', expected = true },
                        { command = 'cd ' .. project_root .. ' && pwd', expected = true },
                        { command = 'cd ' .. project_root .. ' && rm', expected = nil },
                        { command = 'cd /other/path && ls', expected = nil },
                        { command = 'ls', expected = true },
                        { command = 'rm', expected = nil },
                    }

                    for _, tc in ipairs(test_cases) do
                        local approved = auto_approve.mcphub {
                            server_name = 'shell',
                            tool_name = 'shell_exec',
                            arguments = { command = tc.command },
                        }
                        assert.equal(
                            tc.expected,
                            approved,
                            'Failed for command: ' .. tc.command
                        )
                    end
                end)
            end)
        end)
    end)
end)

---@module 'luassert'

describe('auto_approve', function()
    local auto_approve = require 'custom.codecompanion.auto_approve'
    local project_root = vim.fn.tempname()
    vim.fn.mkdir(project_root, 'p')

    before_each(function()
        auto_approve.setup()
        auto_approve.session_allowed_cmds = {} -- Reset session commands for each test
    end)

    describe('setup', function()
        it('uses default config when no options provided', function()
            assert.same({
                allowed_cmds = {},
                secret_files = {
                    '.env*',
                    'env*.sh',
                },
                project_root = nil,
                cmd_env = true,
                cmd_glob = false,
                cmd_redir = true,
                cmd_control = true,
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
                cmd_env = false,
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
                cmd_env = false,
                cmd_glob = false,
                cmd_redir = true,
                cmd_control = true,
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

            it('supports advanced quote handling in prefix patterns', function()
                auto_approve.setup {
                    allowed_cmds = {
                        'go test -run=*',
                        'docker -*',
                    },
                }

                local test_cases = {
                    -- Advanced quote combinations for -run=*
                    {
                        cmd = [[go test -"r"u'n'=Test]],
                        expected = true,
                        desc = 'Quoted middle part',
                    },
                    {
                        cmd = 'go test "-run"=Test',
                        expected = true,
                        desc = 'Quoted prefix part',
                    },
                    {
                        cmd = 'go test -run="Test"',
                        expected = true,
                        desc = 'Quoted value part',
                    },
                    {
                        cmd = 'go test -run=A "-run=B" -run=C',
                        expected = true,
                        desc = 'Multiple mixed arguments',
                    },
                    {
                        cmd = 'go test -run=A -run="B C" -run=D',
                        expected = true,
                        desc = 'Multiple with quoted space',
                    },
                    {
                        cmd = 'go test "-run=A" "-run=B" "-run=C"',
                        expected = true,
                        desc = 'Multiple all quoted',
                    },
                    { cmd = 'go test "-run="', expected = true, desc = 'Quoted empty value' },

                    -- Tests for docker -*
                    { cmd = 'docker -it', expected = true, desc = 'Simple flag' },
                    { cmd = 'docker --rm', expected = true, desc = 'Double dash flag' },
                    { cmd = 'docker "-it"', expected = true, desc = 'Quoted flag' },
                    { cmd = 'docker "--rm"', expected = true, desc = 'Quoted double dash' },
                    {
                        cmd = 'docker "-it" "--rm"',
                        expected = true,
                        desc = 'Multiple quoted flags',
                    },

                    -- Negative cases
                    { cmd = 'go test -debug=yes', expected = false, desc = 'Different prefix' },
                    {
                        cmd = 'go test "-debug=yes"',
                        expected = false,
                        desc = 'Different prefix quoted',
                    },
                    { cmd = 'docker run', expected = false, desc = 'No dash prefix' },
                }

                for _, tc in ipairs(test_cases) do
                    local requires_approval =
                        auto_approve.cmd_runner { args = { cmd = tc.cmd } }
                    assert.equal(
                        tc.expected,
                        not requires_approval,
                        'Failed for command: ' .. tc.cmd .. ' (' .. tc.desc .. ')'
                    )
                end
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

        describe('session commands', function()
            it('adds valid session commands', function()
                auto_approve.setup { allowed_cmds = { 'ls' } }

                -- Add session command
                vim.cmd 'AutoApproveAddAllowedCmd go test'

                -- Should auto-approve session command
                local requires_approval = auto_approve.cmd_runner { args = { cmd = 'go test' } }
                assert.is_false(requires_approval)

                -- Should still work with original commands
                requires_approval = auto_approve.cmd_runner { args = { cmd = 'ls' } }
                assert.is_false(requires_approval)

                -- Should require approval for non-allowed commands
                requires_approval = auto_approve.cmd_runner { args = { cmd = 'rm file' } }
                assert.is_true(requires_approval)
            end)

            it('validates session commands', function()
                -- Should reject empty command
                local ok = pcall(vim.cmd, 'AutoApproveAddAllowedCmd')
                assert.is_false(ok)

                -- Should reject command starting with *
                ok = pcall(vim.cmd, 'AutoApproveAddAllowedCmd *')
                assert.is_false(ok) -- Will error due to validation
            end)

            it('session commands have higher priority', function()
                auto_approve.setup { allowed_cmds = { 'go build' } }
                vim.cmd 'AutoApproveAddAllowedCmd go test'

                -- Session command should work
                local requires_approval = auto_approve.cmd_runner { args = { cmd = 'go test' } }
                assert.is_false(requires_approval)

                -- Config command should also work
                requires_approval = auto_approve.cmd_runner { args = { cmd = 'go build' } }
                assert.is_false(requires_approval)
            end)

            it('resets session commands', function()
                vim.cmd 'AutoApproveAddAllowedCmd go test'
                vim.cmd 'AutoApproveAddAllowedCmd npm install'

                -- Both should work
                local requires_approval = auto_approve.cmd_runner { args = { cmd = 'go test' } }
                assert.is_false(requires_approval)

                requires_approval = auto_approve.cmd_runner { args = { cmd = 'npm install' } }
                assert.is_false(requires_approval)

                -- Reset
                vim.cmd 'AutoApproveResetAllowedCmds'

                -- Both should now require approval
                requires_approval = auto_approve.cmd_runner { args = { cmd = 'go test' } }
                assert.is_true(requires_approval)

                requires_approval = auto_approve.cmd_runner { args = { cmd = 'npm install' } }
                assert.is_true(requires_approval)
            end)

            it('lists session commands', function()
                -- Empty list
                vim.cmd 'AutoApproveListAddedAllowedCmds' -- Should not error

                -- Add commands and list
                vim.cmd 'AutoApproveAddAllowedCmd go test'
                vim.cmd 'AutoApproveAddAllowedCmd npm build'
                vim.cmd 'AutoApproveListAddedAllowedCmds' -- Should not error
            end)
        end)

        describe('pattern support', function()
            it('supports wildcard patterns with *', function()
                auto_approve.setup {
                    allowed_cmds = {
                        'go test *',
                        'echo *',
                        'ls *',
                    },
                }

                local test_cases = {
                    { cmd = 'go test', expected = true },
                    { cmd = 'go test -v', expected = true },
                    { cmd = 'go test -v -run TestName', expected = true },
                    { cmd = 'echo hello world', expected = true },
                    { cmd = 'echo "hello world"', expected = true },
                    { cmd = 'ls -la', expected = true },
                    { cmd = 'ls', expected = true },
                    { cmd = 'go build', expected = false },
                    { cmd = 'rm file', expected = false },
                }

                for _, tc in ipairs(test_cases) do
                    local requires_approval =
                        auto_approve.cmd_runner { args = { cmd = tc.cmd } }
                    assert.equal(
                        tc.expected,
                        not requires_approval,
                        'Failed for command: ' .. tc.cmd
                    )
                end
            end)

            it('supports prefix patterns like -* and --*', function()
                auto_approve.setup {
                    allowed_cmds = {
                        'go -* test *',
                        'docker -* run *',
                        'git -* diff *',
                    },
                }

                local test_cases = {
                    { cmd = 'go test', expected = true },
                    { cmd = 'go -mod=vendor test', expected = true },
                    { cmd = 'go -mod=vendor -v test', expected = true },
                    { cmd = 'docker run nginx', expected = true },
                    { cmd = 'docker --rm run nginx', expected = true },
                    { cmd = 'git diff HEAD~1', expected = true },
                    { cmd = 'git --no-pager diff HEAD~1', expected = true },
                    { cmd = 'go build test', expected = false },
                    { cmd = 'docker build .', expected = false },
                }

                for _, tc in ipairs(test_cases) do
                    local requires_approval =
                        auto_approve.cmd_runner { args = { cmd = tc.cmd } }
                    assert.equal(
                        tc.expected,
                        not requires_approval,
                        'Failed for command: ' .. tc.cmd
                    )
                end
            end)

            it('supports specific prefix patterns like -run=*', function()
                auto_approve.setup {
                    allowed_cmds = {
                        'go test -run=*',
                        'sed -n *',
                        'grep -E *',
                    },
                }

                local test_cases = {
                    { cmd = 'go test -run=', expected = true },
                    { cmd = 'go test "-run="', expected = true },
                    { cmd = "go test '-run='", expected = true },
                    { cmd = 'go test -run=TestName', expected = true },
                    { cmd = 'go test -run="Test 1"', expected = true },
                    { cmd = "go test -run='Test 1'", expected = true },
                    { cmd = 'go test "-run=Test 1"', expected = true },
                    { cmd = "go test '-run=Test 1'", expected = true },
                    { cmd = 'sed -n 1p file.txt', expected = true },
                    { cmd = 'sed -n "1,5p" file.txt', expected = true },
                    { cmd = 'grep -E "some pattern" file.txt', expected = true },
                    { cmd = 'go test -v', expected = false },
                    { cmd = 'sed -i s/old/new/ file.txt', expected = false },
                }

                for _, tc in ipairs(test_cases) do
                    local requires_approval =
                        auto_approve.cmd_runner { args = { cmd = tc.cmd } }
                    assert.equal(
                        tc.expected,
                        not requires_approval,
                        'Failed for command: ' .. tc.cmd
                    )
                end
            end)
        end)

        describe('environment variables support', function()
            it('auto-approves safe environment variables', function()
                auto_approve.setup {
                    allowed_cmds = { 'go test' },
                }

                local test_cases = {
                    { cmd = 'go test', expected = true },
                    { cmd = 'GOOS=linux go test', expected = true },
                    { cmd = 'GOOS=linux GOARCH=amd64 go test', expected = true },
                    { cmd = 'CGO_ENABLED=0 go test', expected = true },
                    { cmd = 'DEBUG= go test', expected = true },
                    { cmd = 'MY_VAR="hello world" go test', expected = true },
                    { cmd = "MY_VAR='hello world' go test", expected = true },
                }

                for _, tc in ipairs(test_cases) do
                    local requires_approval =
                        auto_approve.cmd_runner { args = { cmd = tc.cmd } }
                    assert.equal(
                        tc.expected,
                        not requires_approval,
                        'Failed for command: ' .. tc.cmd
                    )
                end
            end)

            it('blocks unsafe environment variables', function()
                auto_approve.setup {
                    allowed_cmds = { 'ls' },
                }

                local test_cases = {
                    { cmd = 'PATH=/malicious ls', expected = false },
                    { cmd = 'LD_PRELOAD=./bad.so ls', expected = false },
                    { cmd = 'LD_LIBRARY_PATH=/bad ls', expected = false },
                    { cmd = 'LIBRARY_PATH=/bad ls', expected = false },
                }

                for _, tc in ipairs(test_cases) do
                    local requires_approval =
                        auto_approve.cmd_runner { args = { cmd = tc.cmd } }
                    assert.equal(
                        tc.expected,
                        not requires_approval,
                        'Failed for command: ' .. tc.cmd
                    )
                end
            end)

            it('can disable environment variables support', function()
                auto_approve.setup {
                    allowed_cmds = { 'go test' },
                    cmd_env = false,
                }

                local requires_approval =
                    auto_approve.cmd_runner { args = { cmd = 'GOOS=linux go test' } }
                assert.is_true(
                    requires_approval,
                    'Should require approval when env vars disabled'
                )
            end)
        end)

        describe('redirections support', function()
            it('auto-approves safe redirections', function()
                auto_approve.setup {
                    allowed_cmds = { 'go test', 'ls', 'nvim *' },
                }

                local test_cases = {
                    { cmd = 'go test > output.txt', expected = true },
                    { cmd = 'go test 2>&1', expected = true },
                    { cmd = 'go test > /dev/null', expected = true },
                    { cmd = 'go test 2> /dev/null', expected = true },
                    { cmd = 'ls > result.txt 2>&1', expected = true },
                    { cmd = 'go test > logs/test.log', expected = true },
                    { cmd = 'nvim -l tests/run.lua --minitest 2>&1', expected = true },
                }

                for _, tc in ipairs(test_cases) do
                    local requires_approval =
                        auto_approve.cmd_runner { args = { cmd = tc.cmd } }
                    assert.equal(
                        tc.expected,
                        not requires_approval,
                        'Failed for command: ' .. tc.cmd
                    )
                end
            end)

            it('can disable redirections support', function()
                auto_approve.setup {
                    allowed_cmds = { 'go test' },
                    cmd_redir = false,
                }

                local requires_approval =
                    auto_approve.cmd_runner { args = { cmd = 'go test > output.txt' } }
                assert.is_true(
                    requires_approval,
                    'Should require approval when redirections disabled'
                )
            end)
        end)

        describe('command chains support', function()
            it('auto-approves safe command chains', function()
                auto_approve.setup {
                    allowed_cmds = { 'go test', 'echo *', 'ls' },
                }

                local test_cases = {
                    { cmd = 'go test && echo "success"', expected = true },
                    { cmd = 'go test || echo "failed"', expected = true },
                    { cmd = 'ls; echo "done"', expected = true },
                    { cmd = 'go test | grep PASS', expected = false }, -- grep not allowed
                    { cmd = 'go test && rm file', expected = false }, -- rm not allowed
                }

                for _, tc in ipairs(test_cases) do
                    local requires_approval =
                        auto_approve.cmd_runner { args = { cmd = tc.cmd } }
                    assert.equal(
                        tc.expected,
                        not requires_approval,
                        'Failed for command: ' .. tc.cmd
                    )
                end
            end)

            it('can disable command chains support', function()
                auto_approve.setup {
                    allowed_cmds = { 'go test', 'echo *' },
                    cmd_control = false,
                }

                local requires_approval =
                    auto_approve.cmd_runner { args = { cmd = 'go test && echo success' } }
                assert.is_true(
                    requires_approval,
                    'Should require approval when command chains disabled'
                )
            end)
        end)

        describe('security checks', function()
            it('blocks unsafe substrings', function()
                auto_approve.setup {
                    allowed_cmds = { 'echo *' },
                }

                local test_cases = {
                    { cmd = 'echo ../../../etc/passwd', expected = false },
                    { cmd = 'echo `whoami`', expected = false },
                    { cmd = 'echo $(malicious)', expected = false },
                    { cmd = 'echo "../../../etc/passwd"', expected = false }, -- quoted but still unsafe
                }

                for _, tc in ipairs(test_cases) do
                    local requires_approval =
                        auto_approve.cmd_runner { args = { cmd = tc.cmd } }
                    assert.equal(
                        tc.expected,
                        not requires_approval,
                        'Failed for command: ' .. tc.cmd
                    )
                end
            end)
        end)

        describe('configuration validation', function()
            it('validates allowed_cmds configuration', function()
                -- Test will pass if no errors are thrown
                auto_approve.setup {
                    allowed_cmds = {
                        'go test',
                        'go test *',
                        'go -* test *',
                    },
                }

                -- Invalid configurations should log errors but not crash
                auto_approve.setup {
                    allowed_cmds = {
                        '', -- empty command
                        '*', -- starts with *
                        123, -- not a string
                        'valid command',
                    },
                }
            end)
        end)

        describe('complex scenarios', function()
            it('handles complex real-world commands', function()
                auto_approve.setup {
                    allowed_cmds = {
                        'go test *',
                        'go -* test *',
                        'npm *',
                        'docker *',
                        'echo *',
                        'grep *',
                    },
                }

                local test_cases = {
                    {
                        cmd = 'GOOS=linux go -mod=vendor test -v -run=TestIntegration > test.log 2>&1',
                        expected = true,
                    },
                    {
                        cmd = 'CGO_ENABLED=0 go test ./... && echo "Tests passed"',
                        expected = true,
                    },
                    {
                        cmd = 'npm run test:unit > output.txt || echo "Tests failed"',
                        expected = true,
                    },
                    { cmd = 'docker --rm --name test run nginx:latest', expected = true },
                    { cmd = 'DEBUG=1 npm install && npm test', expected = true }, -- both npm commands are allowed
                    {
                        cmd = 'go test | grep PASS',
                        expected = true,
                    },
                }

                for _, tc in ipairs(test_cases) do
                    local requires_approval =
                        auto_approve.cmd_runner { args = { cmd = tc.cmd } }
                    assert.equal(
                        tc.expected,
                        not requires_approval,
                        'Failed for command: ' .. tc.cmd
                    )
                end
            end)
        end)

        describe('performance', function()
            it('handles complex command checking efficiently', function()
                -- 100 allowed commands
                local many_commands = {}
                for i = 1, 100 do
                    table.insert(many_commands, 'cmd' .. i .. ' *')
                end

                auto_approve.setup { allowed_cmds = many_commands }

                -- Complex command (200+ characters), checks command near end of list
                local complex_cmd = 'ENV1=value1 ENV2="quoted value" cmd99 --flag1 --flag2=value '
                    .. 'arg1 arg2 > output.log 2>&1 && echo "success" || echo "failed" ; '
                    .. 'cmd100 -v --verbose | grep pattern > final.txt'

                local start = vim.loop.hrtime()
                auto_approve.cmd_runner { args = { cmd = complex_cmd } }
                local elapsed = (vim.loop.hrtime() - start) / 1e6 -- in milliseconds

                print(
                    'auto_approve: BENCHMARK: Complex command parsing took '
                        .. string.format('%.2f', elapsed)
                        .. 'ms'
                )
            end)
        end)

        describe('edge cases and special characters', function()
            it('handles special characters safely', function()
                auto_approve.setup { allowed_cmds = { 'echo *' } }

                local evil_inputs = {
                    'echo \0null',
                    'echo \n\r\t',
                    'echo "quote\\"escape"',
                    "echo 'single\\'quote'",
                    'echo $((1+1))',
                    'echo ${HOME}',
                    'echo ~user',
                    'echo file\\ with\\ spaces',
                    string.rep('a', 1000), -- very long command
                }

                for _, input in ipairs(evil_inputs) do
                    local ok, result =
                        pcall(auto_approve.cmd_runner, { args = { cmd = input } })
                    assert.is_true(ok, 'Should not crash on: ' .. input)
                    assert.is_boolean(result, 'Should return boolean for: ' .. input)
                end
            end)

            it('handles malformed patterns gracefully', function()
                auto_approve.setup {
                    allowed_cmds = {
                        '', -- empty command
                        '   ', -- only spaces
                        '*', -- only asterisk (should be blocked)
                        'cmd **', -- double asterisk
                        'cmd * * *', -- multiple asterisks
                    },
                }

                -- Should not crash during initialization
                assert.is_table(auto_approve.config)
            end)

            it('handles empty and whitespace commands', function()
                auto_approve.setup { allowed_cmds = { 'test' } }

                local edge_cases = {
                    '',
                    ' ',
                    '\t',
                    '\n',
                    '   \t  \n  ',
                }

                for _, cmd in ipairs(edge_cases) do
                    local ok, result = pcall(auto_approve.cmd_runner, { args = { cmd = cmd } })
                    assert.is_true(ok, 'Should not crash on empty/whitespace: "' .. cmd .. '"')
                    assert.is_boolean(result, 'Should return boolean for: "' .. cmd .. '"')
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
            vim.g.codecompanion_yolo_mode = true
            local approved = auto_approve.mcphub {}
            assert.is_true(approved)

            vim.g.codecompanion_yolo_mode = nil
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

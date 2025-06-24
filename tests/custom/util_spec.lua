---@module 'luassert'

local util = require 'custom.util'

describe('util', function()
    describe('project_path', function()
        local test_dir
        local notify_called

        before_each(function()
            -- Создаем временную директорию для тестов
            test_dir = vim.fn.getcwd() .. '/test_dir'
            vim.fn.mkdir(test_dir .. '/.buildcache/bin', 'p')
            notify_called = false
            -- Перехватываем вызовы vim.notify
            vim.notify = function(msg, level)
                notify_called = true
                assert.equals('vim.g.project_root is not set', msg)
                assert.equals(vim.log.levels.ERROR, level)
            end
        end)

        after_each(function()
            vim.fn.delete(test_dir, 'rf')
            vim.g.project_root = nil
        end)

        it('should return empty string when project_root not set', function()
            vim.g.project_root = nil
            local result = util.project_path { '.buildcache/bin' }
            assert.equals('', result)
            assert.is_true(notify_called)
        end)

        it('should add existing directory', function()
            vim.g.project_root = test_dir
            local result = util.project_path { '.buildcache/bin' }
            local expected = test_dir .. '/.buildcache/bin:'
            assert.equals(expected, result)
        end)

        it('should skip non-existing directories', function()
            vim.g.project_root = test_dir
            local result = util.project_path { 'non/existing/dir' }
            assert.equals('', result)
        end)

        it('should handle multiple directories', function()
            vim.g.project_root = test_dir
            vim.fn.mkdir(test_dir .. '/tools/bin', 'p')
            local result = util.project_path { '.buildcache/bin', 'tools/bin' }
            assert.truthy(result:find(test_dir .. '/.buildcache/bin:', 1, true))
            assert.truthy(result:find(test_dir .. '/tools/bin:', 1, true))
        end)

        it('should handle empty input', function()
            vim.g.project_root = test_dir
            local result = util.project_path {}
            assert.equals('', result)
        end)
    end)
end)

---@module 'luassert'

local util = require 'custom.util'

describe('util', function()
    describe('project_path', function()
        local test_dir
        local notify_called

        before_each(function()
            test_dir = vim.fn.getcwd() .. '/test_dir'
            vim.fn.mkdir(test_dir .. '/.buildcache/bin', 'p')
            notify_called = false
            ---@diagnostic disable-next-line: duplicate-set-field
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

    describe('adapt_nerd_font_propo', function()
        before_each(function()
            vim.g.nerd_font_propo = true
        end)

        after_each(function()
            vim.g.nerd_font_propo = nil
        end)

        it('does nothing if not nerd_font_propo', function()
            vim.g.nerd_font_propo = false
            local icon = vim.fn.nr2char(0xE000)
            local input = { icon .. ' Hello ' .. icon .. ' World' }
            util.adapt_nerd_font_propo(input)
            assert.same({ icon .. ' Hello ' .. icon .. ' World' }, input)
        end)

        it('removes space after wide icons in strings in arrays', function()
            local icon = vim.fn.nr2char(0xE000)
            local input = { icon .. ' Hello ' .. icon .. ' World' }
            util.adapt_nerd_font_propo(input)
            assert.same({ icon .. 'Hello ' .. icon .. 'World' }, input)
        end)

        it('modifies nested tables in-place', function()
            local icon1 = vim.fn.nr2char(0xE000)
            local icon2 = vim.fn.nr2char(0xE001)
            local icon3 = vim.fn.nr2char(0xE002)
            local icon4 = vim.fn.nr2char(0xE003)

            local input = {
                key = icon1 .. ' Value',
                nested = {
                    icon2 .. ' Text',
                    deep = { icon3 .. ' Deep', icon4 .. ' Value' },
                },
            }
            local expected = {
                key = icon1 .. 'Value',
                nested = {
                    icon2 .. 'Text',
                    deep = { icon3 .. 'Deep', icon4 .. 'Value' },
                },
            }
            util.adapt_nerd_font_propo(input)
            assert.same(expected, input)
        end)

        it('does not modify table keys', function()
            local icon1 = vim.fn.nr2char(0xE000)
            local icon2 = vim.fn.nr2char(0xE001)
            local input = {
                [icon1 .. ' Key'] = icon2 .. ' Value',
                [icon2 .. ' AnotherKey'] = 'text',
            }
            local expected = {
                [icon1 .. ' Key'] = icon2 .. 'Value',
                [icon2 .. ' AnotherKey'] = 'text',
            }
            util.adapt_nerd_font_propo(input)
            assert.same(expected, input)
        end)

        it('preserves non-string values', function()
            local icon = vim.fn.nr2char(0xE000)
            local input = {
                number = 42,
                boolean = true,
                text = icon .. ' text',
            }
            local expected = {
                number = 42,
                boolean = true,
                text = icon .. 'text',
            }
            util.adapt_nerd_font_propo(input)
            assert.same(expected, input)
        end)

        it('handles special icon ranges correctly', function()
            local function test_wide_icon(icon)
                local input = { text = icon .. ' text' }
                local expected = { text = icon .. 'text' }
                util.adapt_nerd_font_propo(input)
                assert.same(expected, input)
            end

            local function test_icon(icon)
                local input = { text = icon .. ' text' }
                local expected = { text = icon .. ' text' }
                util.adapt_nerd_font_propo(input)
                assert.same(expected, input)
            end

            -- Test representative icons from each range.
            test_wide_icon '⏻' -- 0x23FB
            test_wide_icon '⏾' -- 0x23FE
            test_wide_icon '♥' -- 0x2665
            test_wide_icon '⭘' -- 0x2B58
            test_wide_icon '' -- 0xE000
            test_wide_icon '' -- 0xE00A
            test_icon '' -- 0xE0A0
            test_icon '' -- 0xE0BF
            test_wide_icon '' -- 0xE0C0
            test_wide_icon '' -- 0xF533
            test_wide_icon '󰀁' -- 0xF0001
            test_wide_icon '󱫰' -- 0xF1AF0
        end)
    end)
end)

---@module 'luassert'

local jinja = require 'custom._jinja'

local default = {
    block = { '{%', '%}' },
    variable = { '{{', '}}' },
    comment = { '{#', '#}' },
}

local custom = {
    block = { '#{', '}#' },
    variable = { '#=', '=#' },
    comment = { '#%', '%#' },
}

-- Converts highlights to a list of "text:group" for readable assertions.
local function hl(text, delims)
    local lines = vim.split(text, '\n')
    local out = {}
    for row = 0, #lines - 1 do
        local line = lines[row + 1]
        for _, h in ipairs(jinja.highlights(lines, delims or default)[row] or {}) do
            out[#out + 1] = line:sub(h[2] + 1, h[3] or #line) .. ':' .. h[4]
        end
    end
    return out
end

describe('_jinja', function()
    describe('mask', function()
        it('should replace text outside of tags by spaces', function()
            local masked, tags = jinja.mask('a {{ x }}\nb ${{ y }}', default)
            assert.equals('  {{ x }}\n   {{ y }}', masked)
            assert.same({ { 3, 10, 'variable' }, { 14, 21, 'variable' } }, tags)
        end)

        it('should replace custom delimiters by default ones', function()
            local masked, tags = jinja.mask('k: ${{ x }} #= a -=#\n#{ if b }#', custom)
            assert.equals('            {{ a -}}\n{% if b %}', masked)
            assert.same({ { 13, 21, 'variable' }, { 22, 32, 'block' } }, tags)
        end)

        it('should replace custom comment delimiters by default ones', function()
            local masked, tags = jinja.mask('#% note %# #{ else }#', custom)
            assert.equals('{# note #} {% else %}', masked)
            assert.same({ { 1, 11, 'comment' }, { 12, 22, 'block' } }, tags)
        end)

        it('should support multiline tags', function()
            local masked = jinja.mask('a {#\nnote\n#} b', default)
            assert.equals('  {#\nnote\n#}  ', masked)
        end)

        it('should continue tag until the end delimiter on next lines', function()
            local masked, tags = jinja.mask('a {{ x\nb {{ y }}', default)
            assert.equals('  {{ x\nb {{ y }}', masked)
            assert.same({ { 3, 17, 'variable' } }, tags)
        end)

        it('should end tag without end delimiter at the end of line', function()
            local masked, tags = jinja.mask('a {{ x\nb', default)
            assert.equals('  {{ x\n ', masked)
            assert.same({ { 3, 7, 'variable' } }, tags)
        end)

        it('should mask text inside raw block', function()
            local masked, tags = jinja.mask('#{ raw }# #= x =# #{- endraw }# #= y =#', custom)
            assert.equals('{% raw %}         {%- endraw %} {{ y }}', masked)
            assert.same(
                { { 1, 10, 'block' }, { 19, 32, 'block' }, { 33, 40, 'variable' } },
                tags
            )
        end)

        it('should parse text after raw block without endraw', function()
            local masked, tags = jinja.mask('#{ raw }# #= x =#', custom)
            assert.equals('{% raw %} {{ x }}', masked)
            assert.same({ { 1, 10, 'block' }, { 11, 18, 'variable' } }, tags)
        end)
    end)

    describe('highlights', function()
        it('should ignore lines without tags', function()
            assert.same({}, hl 'key: [value] # comment')
            assert.same({}, hl('key: ${{ github.ref }} {% raw %}', custom))
        end)

        it('should highlight tag background', function()
            assert.same(
                { '#= a =#:@jinja.tag' },
                vim.tbl_filter(function(s)
                    return s:find('@jinja.tag', 1, true)
                end, hl('/bin/#= a =#', custom))
            )
            assert.same(
                { '{#:@jinja.tag', 'note:@jinja.tag', '#}:@jinja.tag' },
                vim.tbl_filter(function(s)
                    return s:find('@jinja.tag', 1, true)
                end, hl 'x {#\nnote\n#} y')
            )
        end)

        describe('with jinja parser', function()
            if not vim.treesitter.language.add 'jinja' then
                pending 'jinja treesitter parser is not installed'
                return
            end

            it('should highlight tag tokens using jinja parser', function()
                assert.same({
                    "#{ if not (type == 'go') }#:@jinja.tag",
                    '#{:@keyword.directive',
                    'if:@keyword.conditional',
                    '(:@punctuation.bracket',
                    'type:@variable',
                    '==:@operator',
                    "'go':@string",
                    '):@punctuation.bracket',
                    '}#:@keyword.directive',
                }, hl("#{ if not (type == 'go') }#", custom))
            end)

            it('should not highlight raw block body', function()
                assert.same({
                    '#{ raw }#:@jinja.tag',
                    '#{ raw }#:@keyword',
                    '#{ endraw }#:@jinja.tag',
                    '#{ endraw }#:@keyword',
                }, hl('#{ raw }#\nk: #= x =#\n#{ endraw }#', custom))
            end)

            it('should highlight comment with custom delimiters', function()
                assert.same({
                    '#% note %#:@jinja.tag',
                    '#% note %#:@comment',
                }, hl('#% note %#', custom))
            end)
        end)
    end)

    describe('delimiters', function()
        after_each(function()
            vim.g.jinja_delimiters = nil
        end)

        it('should return nil without config', function()
            assert.is_nil(jinja.delimiters '/tmp/a/x.yml.jinja')
        end)

        it('should return custom delimiters for files inside matching directories', function()
            vim.g.jinja_delimiters = { ['~/tpl-*'] = custom }
            local home = vim.fs.normalize '~'
            assert.same(custom, jinja.delimiters(home .. '/tpl-a/x.yml.jinja'))
            assert.same(custom, jinja.delimiters(home .. '/tpl-b/sub/x.yml.jinja'))
            assert.is_nil(jinja.delimiters(home .. '/tpl/x.yml.jinja'))
            assert.is_nil(jinja.delimiters(home .. '/x/tpl-a/x.yml.jinja'))
        end)

        it('should use default delimiters for not configured tags', function()
            vim.g.jinja_delimiters = { ['/tpl'] = { variable = custom.variable } }
            assert.same(
                { block = default.block, variable = custom.variable, comment = default.comment },
                jinja.delimiters '/tpl/x.yml.jinja'
            )
        end)
    end)
end)

---@module 'luassert'

describe('Path:normalize', function()
    local Path = require 'plenary.path'

    local function common()
        it('supports absolute path', function()
            local norm = Path:new('/x/y'):normalize '/a/b/c/d/e'
            assert.equal('/x/y', norm)
        end)
        it('supports relative DOWN path', function()
            local norm = Path:new('/a/b/c/d/e/f'):normalize '/a/b/c/d/e'
            assert.equal('f', norm)
        end)
    end

    describe('original', function()
        common()
        it('does not support relative UP path', function()
            local norm = Path:new('/a/b/c/d/f'):normalize '/a/b/c/d/e'
            assert.equal('/a/b/c/d/f', norm)
        end)
    end)

    describe('patched', function()
        require 'patch.plenary.path_normalize'
        common()
        it('supports relative UP path', function()
            local norm = Path:new('/a/b/c/d/f'):normalize '/a/b/c/d/e'
            assert.equal('../f', norm)
            norm = Path:new('/a/b/c/d/f/g'):normalize '/a/b/c/d/e'
            assert.equal('../f/g', norm)
        end)
        it('returns shortest of absolute and relative UP path', function()
            local norm = Path:new('/a/b/c/f'):normalize '/a/b/c/d/e'
            assert.equal('../../f', norm)
            norm = Path:new('/a/b/f'):normalize '/a/b/c/d/e'
            assert.equal('/a/b/f', norm)
        end)
    end)
end)

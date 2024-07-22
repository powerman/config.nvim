---@module 'luassert'

vim.opt.rtp:append '~/.local/share/nvim/lazy/nvim-lspconfig'
local Project = require 'project'

describe('setup', function()
    local old_PATH = vim.env.PATH
    local new_PATH
    it('should just add autocmd', function()
        Project.setup {
            root_patterns = { 'nosuch', '.gitignore', '.git', 'tests/project', 'nosuch2' },
        }
        assert.equal(old_PATH, vim.env.PATH)
    end)
    describe('autocmd', function()
        it('should change PATH', function()
            vim.cmd [[set ft=lua]] -- Trigger autocmd FileType.
            new_PATH = vim.env.PATH
            assert.not_equal(old_PATH, new_PATH)
        end)
        it('should not include in PATH non-existing paths', function()
            assert.not_match('nosuch', new_PATH)
        end)
        it('should not include in PATH existing non-dirs', function()
            assert.not_match('.gitignore', new_PATH)
        end)
        it('should include in PATH all existing dirs', function()
            assert.match('/.git:', new_PATH)
            assert.match('/tests/project:', new_PATH)
        end)
        it('should change PATH just once', function()
            vim.cmd [[set ft=markdown]] -- Trigger autocmd FileType.
            assert.equal(new_PATH, vim.env.PATH)
        end)
    end)
end)

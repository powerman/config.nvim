--[[ Highlight, list and search todo comments in your projects ]]
--
--  - Highlight your todo comments in different styles.
--  - Optionally only highlights todos in comments using TreeSitter.
--  - Open todos in a quickfix list.
--  - Search todos with Telescope.

-- NOTE: 󰋗 Known TODO keywords:
--  - FIX FIXME BUG FIXIT ISSUE
--  - TODO
--  - HACK
--  - WARN WARNING XXX
--  - PERF OPTIM PERFORMANCE OPTIMIZE
--  - NOTE INFO
--  - TEST TESTING PASSED FAILED

-- NOTE:  ]t [t                   Jump to next/prev TODO.
-- NOTE:  :TodoTelescope          Search all TODO in cwd.
-- NOTE:  :TodoTelescope cwd=..   Search all TODO in ../.
-- NOTE:  :TodoQuickFix           All TODO in a quickfix.

---@module 'lazy'
---@type LazySpec
return {
    {
        'folke/todo-comments.nvim',
        version = '*',
        dependencies = { 'nvim-lua/plenary.nvim' },
        event = 'VimEnter', -- VeryLazy breaks autocmd on BufEnter below, so use VimEnter.
        keys = {
            {
                ']t',
                function()
                    require('todo-comments').jump_next()
                end,
                desc = 'Next todo comment',
            },
            {
                '[t',
                function()
                    require('todo-comments').jump_prev()
                end,
                desc = 'Previous todo comment',
            },
        },
        ---@type TodoOptions
        opts = {
            signs = false,
            -- Removed space after doublewidth icons to fix "Vim:E239: Invalid sign text".
            -- Replaced TEST icon because original one is missing from my fonts.
            keywords = {
                FIX = { icon = '' },
                TODO = { icon = '' },
                HACK = { icon = '' },
                WARN = { icon = '' },
                PERF = { icon = '' },
                NOTE = { icon = '' },
                TEST = { icon = '󰝖' },
            },
            gui_style = {
                -- NOCOMBINE will cancel ITALIC and thus fix last letter's edge.
                bg = 'BOLD,NOCOMBINE',
            },
        },
        config = function(_, opts)
            require('todo-comments').setup(opts)

            vim.api.nvim_create_autocmd('BufEnter', {
                desc = 'Enable todo-comments for text',
                group = vim.api.nvim_create_augroup('user.todo.text', { clear = true }),
                callback = function(ev)
                    local config = require 'todo-comments.config'
                    local comments_only = string.match(ev.file, '%.md$') == nil
                        and string.match(ev.file, '%.txt$') == nil
                        and string.match(ev.file, '%.adoc$') == nil
                        and string.match(ev.file, '%.asciidoc$') == nil
                    config.options.highlight.comments_only = comments_only
                end,
            })
        end,
    },
}

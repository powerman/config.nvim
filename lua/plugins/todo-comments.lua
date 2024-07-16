--[[ Highlight, list and search todo comments in your projects ]]
--
--  - Highlight your todo comments in different styles.
--  - Optionally only highlights todos in comments using TreeSitter.
--  - Open todos in a quickfix list.
--  - Search todos with Telescope.
--
--  Default keywords:
--    - FIX FIXME BUG FIXIT ISSUE
--    - TODO
--    - HACK
--    - WARN WARNING XXX
--    - PERF OPTIM PERFORMANCE OPTIMIZE
--    - NOTE INFO
--    - TEST TESTING PASSED FAILED

-- NOTE:  ]t [t                  Jump to next/prev TODO.
-- NOTE:  :TodoTelescope         Search all TODO in cwd.
-- NOTE:  :TodoTelescope cwd=..  Search all TODO in ../.
-- NOTE:  :TodoQuickFix          All TODO in a quickfix.

---@module 'lazy'
---@type LazySpec
return {
    {
        'folke/todo-comments.nvim',
        version = '*',
        dependencies = { 'nvim-lua/plenary.nvim' },
        lazy = true, -- Must be loaded but not critical, so let's use event VeryLazy.
        event = 'VeryLazy',
        keys = {
            {
                ']t',
                function()
                    require('todo-comments').jump_next()
                end,
                desc = 'Next [t]odo comment',
            },
            {
                '[t',
                function()
                    require('todo-comments').jump_prev()
                end,
                desc = 'Previous [t]odo comment',
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
    },
}

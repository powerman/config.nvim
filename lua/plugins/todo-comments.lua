-- Highlight todo, notes, etc in comments
return {
    {
        'folke/todo-comments.nvim',
        event = 'VimEnter',
        dependencies = {
            'nvim-lua/plenary.nvim',
        },
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
        },
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
    },
}

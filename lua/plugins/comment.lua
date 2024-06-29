return {
    { -- "gc", "#", "<C-C>" to comment visual regions/lines.
        'numToStr/Comment.nvim',
        opts = {},
        config = function()
            vim.keymap.set('n', '#', function()
                return vim.v.count == 0 and '<Plug>(comment_toggle_linewise_current)<Down>'
                    or '<Plug>(comment_toggle_linewise_count)'
            end, { expr = true, desc = 'Comment toggle linewise' })

            vim.keymap.set(
                'v',
                '#',
                '<Plug>(comment_toggle_linewise_visual)`><Down>',
                { desc = 'Comment toggle linewise' }
            )

            local api = require 'Comment.api'

            -- Support for a count makes implementation a bit complicated.
            vim.keymap.set('n', '<C-C>', function()
                local count = vim.v.count1
                vim.api.nvim_feedkeys('V', 'n', false)
                if count > 1 then
                    vim.api.nvim_feedkeys((count - 1) .. 'j', 'n', false)
                end
                vim.api.nvim_feedkeys('yP', 'nx', false)
                api.comment.linewise.count(count)
                vim.api.nvim_feedkeys('`<^i', 'n', false)
            end, { desc = 'Backup (count) line(s) as a comment, then edit' })

            vim.keymap.set(
                'v',
                '<C-C>',
                'V<Esc>gvy`>pgv<Esc>`>:lua require"Comment.api".comment.linewise("V")<CR><Down>^i',
                { silent = true, desc = 'Backup selected lines as a comment, then edit' }
            )

            vim.keymap.set(
                'i',
                '<C-C>',
                '<C-O>yy<C-O>P<C-O>:lua require"Comment.api".comment.linewise.current()<CR><Down>',
                { silent = true, desc = 'Backup current line as a comment' }
            )
        end,
    },
}

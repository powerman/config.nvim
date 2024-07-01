---@type LazySpec
return {
    { -- "gc", "#", "<C-C>" to comment visual regions/lines.
        'numToStr/Comment.nvim',
        opts = {},
        keys = {
            {
                '#',
                function()
                    return vim.v.count == 0 and '<Plug>(comment_toggle_linewise_current)<Down>'
                        or '<Plug>(comment_toggle_linewise_count)'
                end,
                mode = 'n',
                expr = true,
                desc = 'Comment toggle linewise',
            },
            {
                '#',
                '<Plug>(comment_toggle_linewise_visual)`><Down>',
                mode = 'v',
                desc = 'Comment toggle linewise',
            },
            {
                '<C-C>',
                function() -- Support for a count makes implementation a bit complicated.
                    local count = vim.v.count1
                    local api = require 'Comment.api'
                    vim.api.nvim_feedkeys('V', 'n', false)
                    if count > 1 then
                        vim.api.nvim_feedkeys((count - 1) .. 'j', 'n', false)
                    end
                    vim.api.nvim_feedkeys('yP', 'nx', false)
                    api.comment.linewise.count(count)
                    vim.api.nvim_feedkeys('`<^i', 'n', false)
                end,
                mode = 'n',
                desc = 'Backup (count) line(s) as a comment, then edit',
            },
            {
                '<C-C>',
                'V<Esc>gvy`>pgv<Esc>`>:lua require"Comment.api".comment.linewise("V")<CR><Down>^i',
                mode = 'v',
                silent = true,
                desc = 'Backup selected lines as a comment, then edit',
            },
            {
                '<C-C>',
                '<C-O>yy<C-O>P<C-O>:lua require"Comment.api".comment.linewise.current()<CR><Down>',
                mode = 'i',
                silent = true,
                desc = 'Backup current line as a comment',
            },
        },
    },
}

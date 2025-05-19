--[[ Smart and powerful comment plugin for neovim ]]
--
--  Neovim out-of-box supports commenting and uncommenting of lines based on 'commentstring'
--  on `gc` keymapping and also provides text object `gc` for the largest contiguous block of
--  non-blank commented lines around the cursor.
--
--  This plugin extends that basic functionality:
--    - Support blockwise comments (using `gb` inplace of `gc`).
--    - Works for multiple (injected/embedded) languages like Vue or Markdown.
--      - Support for jsx/tsx requires 'JoosepAlviste/nvim-ts-context-commentstring' plugin.
--    - Optionally ignore lines (e.g. empty ones).
--    - Adds extra keymapping: `gco`, `gcO`, `gcA`.
--
-- BUG: `gc` and `#` in VISUAL with 1 line works blockwise instead of linewise.
-- https://github.com/numToStr/Comment.nvim/issues/476

-- NOTE:  #       (Un)Comments lines and move on.
-- NOTE:  <C-C>   Backup line(s) into comment and edit.
-- NOTE: 󰴑 gc      Match a whole comment around cursor.

---@module 'lazy'
---@type LazySpec
return {
    {
        'numToStr/Comment.nvim',
        branch = 'master', -- There a lot of filetype-related updates since last release.
        lazy = false, -- Needs setup() to define mappings.
        keys = {
            {
                '#',
                function()
                    return vim.v.count == 0 and '<Plug>(comment_toggle_linewise_current)<Down>'
                        or '<Plug>(comment_toggle_linewise_count)'
                            .. vim.v.count
                            .. '<Down>'
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
        ---@type CommentConfig
        ---@diagnostic disable-next-line: missing-fields
        opts = {
            -- ignore = '^$',
        },
        config = true,
    },
}

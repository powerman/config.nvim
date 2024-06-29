return {
  { -- "gc", "#", "<C-C>" to comment visual regions/lines.
    'numToStr/Comment.nvim',
    opts = {},
    config = function()
      -- Add alternative mapping '#'.
      vim.keymap.set('n', '#', function()
        return vim.v.count == 0 and '<Plug>(comment_toggle_linewise_current)<Down>' or '<Plug>(comment_toggle_linewise_count)'
      end, { expr = true, desc = 'Comment toggle linewise' })

      vim.keymap.set('v', '#', '<Plug>(comment_toggle_linewise_visual)`><Down>', { desc = 'Comment toggle linewise' })

      -- TODO: Add mappings for <C-C>.
    end,
  },
}

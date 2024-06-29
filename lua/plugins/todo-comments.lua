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
      -- Remove space after doublewidth icons to fix "Vim:E239: Invalid sign text".
      -- Replace TEST icon because original one is missing from my fonts.
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
  },
}

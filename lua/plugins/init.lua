-- [[ Install plugins without complicated configuration ]]
--
--  Use `opts = {}` to force a plugin to be loaded. This is equivalent to:
--    require('Comment').setup({})
return {
  'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically.

  -- "gc" to comment visual regions/lines.
  { 'numToStr/Comment.nvim', opts = {} },
}

-- vim: ts=2 sts=2 sw=2 et

-- [[ Install plugins without complicated configuration ]]
--
--  Use `opts = {}` to force a plugin to be loaded. This is equivalent to:
--    require('Comment').setup({})
---@type LazySpec
return {
    'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically.
}

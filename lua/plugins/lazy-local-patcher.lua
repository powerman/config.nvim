--[[ Apply local patches to plugins installed through lazy.nvim ]]

-- NOTE:  :lua require("lazy-local-patcher").apply_all()
-- NOTE:  :lua require("lazy-local-patcher").restore_all()

---@module 'lazy'
---@type LazySpec
return {
    {
        'powerman/lazy-local-patcher.nvim',
        ft = 'lazy',
        config = true,
    },
}

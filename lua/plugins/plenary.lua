--[[ A library used by other plugins ]]
--
--  See https://github.com/nvim-lua/plenary.nvim.

-- NOTE:  :PlenaryBustedFile %   Run Lua tests in current file.

---@module 'lazy'
---@type LazySpec
return {
    {
        'nvim-lua/plenary.nvim',
        lazy = true, -- Will be loaded only if some other plugin will depend on it.
        config = function()
            require 'patch.plenary.PlenaryBusted'
            require 'patch.plenary.path_normalize'
        end,
    },
}

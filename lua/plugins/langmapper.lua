---@module 'lazy'
---@type LazySpec
return {
    {
        'Wansmer/langmapper.nvim',
        lazy = false,
        priority = 1,
        config = function()
            require('langmapper').setup {}
            require('langmapper').hack_get_keymap()
            vim.api.nvim_create_autocmd('User', {
                pattern = 'LazyDone',
                once = true,
                callback = function()
                    require('langmapper').automapping { global = true, buffer = false }
                end,
            })
        end,
    },
}

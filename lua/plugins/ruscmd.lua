---@module 'lazy'
---@type LazySpec
return {
    {
        'powerman/ruscmd.nvim',
        ---@module 'ruscmd'
        ---@type ruscmd.Options
        opts = {
            -- Disable mappings because they'll be provided by 'langmapper' plugin.
            replace = true,
            map = { n = {}, x = {}, o = {} },
            cabbrev = {
                'bd',
                'bn',
                'q',
                'qa',
                'w',
                'wq',
                'wqa',
            },
        },
    },
}

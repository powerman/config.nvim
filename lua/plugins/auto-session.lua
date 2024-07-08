vim.opt.sessionoptions:append 'winpos'
vim.opt.sessionoptions:append 'localoptions'

---@type LazySpec
return {
    -- When starting nvim with no arguments, auto-session will try to restore an existing
    -- session for the current cwd if one exists.
    {
        'rmagatti/auto-session',
        version = '*',
        dependencies = {
            'nvim-telescope/telescope.nvim',
        },
        lazy = false,
        keys = {
            {
                '<Leader>sa',
                function()
                    require('auto-session.session-lens').search_session()
                end,
                desc = '[S]earch [A]uto-sessions',
            },
        },
        opts = {
            auto_session_suppress_dirs = { '/', '~/', '~/proj/' },
            session_lens = {
                load_on_setup = true,
                theme_conf = { border = true },
            },
        },
    },
}

--[[ Configure Lazy ]]
--
--  To check the current status of your plugins, run:
--    :Lazy
--
--  You can press `?` in this menu for help. Use `q` to close the window.
--
--  To update plugins you can run:
--    :Lazy update

-- NOTE:  :Lazy   Install/upgrade/clean plugins.

require('lazy').setup({ import = 'plugins' }, {
    checker = {
        enabled = true,
        notify = false,
    },
    change_detection = {
        notify = false,
    },
    dev = {
        path = '~/proj/vim',
    },
    ui = {
        border = vim.g.float_border,
        -- If you are using a Nerd Font: set icons to an empty table which will use the
        -- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table.
        icons = vim.g.have_nerd_font and {} or {
            cmd = '⌘ ',
            config = '⚙️ ',
            event = '📅 ',
            favorite = '★ ',
            ft = '🗋 ',
            init = '⚙ ',
            import = '🗋 ',
            keys = '⌨️ ',
            lazy = '💤 ',
            loaded = '●',
            not_loaded = '○',
            plugin = '🔌 ',
            runtime = '💻 ',
            require = '🌙 ',
            source = '📄 ',
            start = '🚀 ',
            task = '✔ ',
        },
    },
})

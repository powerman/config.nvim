-- [[ A small automated session manager for Neovim ]]
--
--  1. When starting `nvim` with no arguments, auto-session will try to restore an existing
--     session for the `cwd` (current working directory) if one exists.
--  2. When starting `nvim` with some argument, auto-session will do nothing.
--  3. Even after starting `nvim` with an argument, a session can still be manually restored
--     by running `:SessionRestore`.
--  4. Any session saving and restoration takes into consideration the `cwd`.
--  5. When piping to nvim, e.g: `cat myfile | nvim`, auto-session behaves like #2.
--
--  See https://github.com/rmagatti/auto-session.
--
-- NOTE: Cmd `:SessionSave` manually saves a session.
-- NOTE: Key `<Leader>sa` opens session manager (to view/open/delete sessions).
--
-- TODO: Automate `:SessionSave` if more than one tab/window open at VimExit.
-- https://github.com/rmagatti/auto-session/issues/316

---@type LazySpec
return {
    {
        'rmagatti/auto-session',
        version = '*',
        dependencies = {
            'nvim-telescope/telescope.nvim',
        },
        lazy = false, -- Needs to restore session on Neovim start.
        keys = {
            {
                '<Leader>sa',
                function()
                    require('auto-session.session-lens').search_session()
                end,
                desc = '[S]earch [A]uto-sessions',
            },
        },
        init = function()
            vim.opt.sessionoptions:append 'winpos'
            vim.opt.sessionoptions:append 'localoptions'
        end,
        opts = {
            auto_session_suppress_dirs = { '/', '~/', '~/proj/' },
            session_lens = {
                load_on_setup = true,
                theme_conf = { border = true },
            },
        },
    },
}

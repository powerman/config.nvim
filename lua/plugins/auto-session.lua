-- [[ A small automated session manager for Neovim ]]
--
--  1. When starting `nvim` with no arguments, auto-session will try to restore an existing
--     session for the `cwd` (current working directory) if one exists.
--  2. When starting `nvim dir`, auto-session will try to restore the
--     session for that directory.
--  3. When starting `nvim file …` auto-session won't try to restore an existing session and
--     will save (overwrite existing) session only if `args_allow_files_auto_save` option
--     is|returns true.
--  4. Even after starting nvim with a file argument, a session can still be manually restored
--     by running :SessionRestore or manually saved by running :SessionSave.
--  5. Any session saving and restoration takes into consideration the `cwd`.
--  6. When piping to nvim, e.g: `cat myfile | nvim`, auto-session won't do anything.
--
--  See https://github.com/rmagatti/auto-session.
--
-- NOTE: Key `<Leader>sa` opens session manager (to view/restore/delete sessions).

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
        ---@type defaultConf
        opts = {
            auto_session_suppress_dirs = { '/', '~/', '~/proj/' },
            ---@type session_lens_config
            ---@diagnostic disable-next-line: missing-fields
            session_lens = {
                load_on_setup = true,
                theme_conf = { border = true },
            },
            -- If `nvim` was started with file(s) arg(s) and previous session wasn't restored,
            -- then save the session if exiting with at least two tabs/windows with usual files.
            args_allow_files_auto_save = function()
                local valuable = 0
                for _, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
                    for _, window in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
                        local buffer = vim.api.nvim_win_get_buf(window)
                        local file_name = vim.api.nvim_buf_get_name(buffer)
                        if file_name ~= '' and vim.fn.filereadable(file_name) then
                            valuable = valuable + 1
                        end
                    end
                end
                return valuable > 1
            end,
        },
    },
}

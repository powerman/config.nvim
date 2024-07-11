--[[ Plugins without complicated configuration ]]

---@type LazySpec
return {
    -- This plugin automatically adjusts 'shiftwidth' and 'expandtab' heuristically based on
    -- the current file, or, in the case the current file is new, blank, or otherwise
    -- insufficient, by looking at other files of the same type in the current and parent
    -- directories. Modelines and EditorConfig are also consulted, adding 'tabstop',
    -- 'textwidth', 'endofline', 'fileformat', 'fileencoding', and 'bomb' to the list of
    -- supported options.
    --
    -- See `:help sleuth`.
    'tpope/vim-sleuth',
    -- Not a plugin but a library used by other plugins.
    -- Useful for getting pretty icons, but requires a Nerd Font.
    -- Setup it here for lazy loading and DO NOT include in other plugin's dependencies.
    { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font, lazy = true },
    -- Improve the default vim.ui interfaces.
    { 'stevearc/dressing.nvim', lazy = true, event = 'VeryLazy', config = true },
    -- TODO: Just an experiment, not sure is it used (by plugins)/useful (to me).
    {
        'rcarriga/nvim-notify',
        version = '*',
        init = function()
            vim.notify = require 'notify'
        end,
    },
}

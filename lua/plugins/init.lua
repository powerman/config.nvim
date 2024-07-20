--[[ Plugins without complicated configuration ]]

---@module 'lazy'
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
    -- Extensible UI for Neovim notifications and LSP progress messages.
    {
        'j-hui/fidget.nvim',
        version = '*',
        lazy = false,
        opts = {
            notification = {
                override_vim_notify = true,
                window = {
                    winblend = 0,
                },
            },
        },
        config = true,
    },
    -- Configures LuaLS for editing your Neovim config and provides completion source.
    { 'folke/lazydev.nvim', version = '*', lazy = true, ft = 'lua', config = true },
    -- Not a plugin, but a library used to setup LSP jsonls and yamlls.
    { 'b0o/schemastore.nvim', lazy = true },
    -- Not a plugin, but a library with configs for `efm` LSP.
    {
        'creativenull/efmls-configs-nvim',
        version = 'v1.*',
        lazy = true,
        dependencies = 'williamboman/mason.nvim',
    },
}

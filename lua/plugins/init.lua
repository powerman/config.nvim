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
    { 'stevearc/dressing.nvim', event = 'VeryLazy', config = true },
    -- Extensible UI for Neovim notifications and LSP progress messages.
    {
        'j-hui/fidget.nvim',
        version = '*',
        opts = {
            notification = {
                filter = vim.log.levels.INFO, -- Minimum notifications level.
                override_vim_notify = true,
                window = {
                    border = 'rounded',
                    winblend = 0,
                    align = 'top',
                },
            },
        },
        config = function(_, opts)
            require('fidget').setup(opts)

            local orig_notify = vim.notify
            ---@diagnostic disable-next-line: duplicate-set-field
            vim.notify = function(msg, ...)
                -- This one happens all the time because in firejail `nvim --embed` has pid 10.
                if msg == 'W325: Ignoring swapfile from Nvim process 10' then
                    return
                end
                orig_notify(msg, ...)
            end
        end,
    },
    -- Configures LuaLS for editing your Neovim config and provides completion source.
    {
        'folke/lazydev.nvim',
        version = '*',
        ft = 'lua',
        opts = {
            library = {
                -- Load luvit types when the `vim.uv` word is found
                { path = 'luvit-meta/library', words = { 'vim%.uv' } },
            },
        },
    },
    -- Not a plugin, but a collection of definition files for types in `vim.uv.*`.
    'Bilal2453/luvit-meta',
    -- Not a plugin, but a library used to setup LSP jsonls and yamlls.
    'b0o/schemastore.nvim',
    -- Not a plugin, but a library with configs for `efm` LSP.
    {
        'creativenull/efmls-configs-nvim',
        version = 'v1.*',
        dependencies = 'neovim/nvim-lspconfig',
    },
}

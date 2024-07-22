--[[ Install or upgrade all of your third-party tools ]]

-- NOTE:  :Mason   Install/upgrade/uninstall external tools.

-- https://github.com/termux/termux-language-server/issues/21
local function register_termux_ls()
    local server = require 'mason-lspconfig.mappings.server'
    server.lspconfig_to_package['termux_ls'] = 'termux-language-server'
    server.package_to_lspconfig['termux-language-server'] = 'termux_ls'
end

---@module 'lazy'
---@type LazySpec
return {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    dependencies = {
        -- Mason allows you to easily manage external editor tooling such as LSP servers, DAP
        -- servers, linters, and formatters through a single interface.
        {
            'williamboman/mason.nvim',
            version = '*',
            lazy = false, -- Lazy loading is not recommended by Mason author.
            opts = {
                PATH = 'skip', -- INFO: Add ~/.local/share/nvim/mason/bin manually to your PATH.
                ui = {
                    border = vim.g.float_border,
                    icons = {
                        package_installed = '●',
                        package_pending = '➜',
                        package_uninstalled = '○',
                    },
                },
            },
            config = true,
        },
        -- Mason-lspconfig is mostly useful for different use case: when user manually
        -- installs LSP servers when needed instead of pre-configuring them.
        -- We use it just to map between LSP server names and Mason tool names.
        {
            'williamboman/mason-lspconfig.nvim',
            version = '*',
            dependencies = 'neovim/nvim-lspconfig',
        },
    },
    lazy = false, -- Lazy breaks `opts.run_on_start = true`.
    config = function(_, opts)
        register_termux_ls()

        opts = opts or {}
        local ensure_installed = {}

        local tools_lsp = require 'tools.lsp'
        vim.list_extend(ensure_installed, vim.tbl_keys(tools_lsp))
        if tools_lsp.golangci_lint_ls then
            vim.list_extend(ensure_installed, { 'golangci-lint' })
        end
        if tools_lsp.efm then
            for _, tools in pairs(tools_lsp.efm.settings.languages) do
                for _, tool in ipairs(tools) do
                    local cmd = tool.lintCommand or tool.formatCommand or tool.hoverCommand
                    local bin = vim.fn.fnamemodify(vim.split(cmd, ' ')[1], ':t')
                    vim.list_extend(ensure_installed, { bin })
                end
            end
        end

        -- TODO: Add 'configs.conform'.

        vim.list_extend(ensure_installed, opts.ensure_installed or {})
        opts.ensure_installed = ensure_installed
        require('mason-tool-installer').setup(opts)
    end,
}

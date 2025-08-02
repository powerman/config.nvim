--[[ Install or upgrade all of your third-party tools ]]

-- NOTE:  :Mason   Install/upgrade/uninstall external tools.

---@module 'lazy'
---@type LazySpec
return {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    lazy = false, -- Lazy breaks `opts.run_on_start = true`.
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
    opts = {
        auto_update = true,
        ensure_installed = {
            'tree-sitter-cli', -- Needed for auto_install option in treesitter.lua.
        },
    },
    config = function(_, opts)
        -- HACK: Fix Mason registry for Prettierd to use fork with fixed Unicode issue.
        require('mason-registry').get_all_packages() -- Force Mason to load registry.
        require('mason-registry').sources.list[1].instance.buffer.prettierd.spec.source.id =
            'pkg:npm/%40powerman-asdf/prettierd@0.26.3'

        opts = opts or {}
        local ensure_installed = {
            'copilot-language-server', -- For copilot-lsp plugin.
        }

        local lsp = require 'tools.lsp'
        vim.list_extend(ensure_installed, vim.tbl_keys(lsp))
        -- Dependencies:
        if lsp.golangci_lint_ls then
            vim.list_extend(ensure_installed, { 'golangci-lint' })
        end
        if lsp.efm then
            local languages = lsp.efm.settings.languages --[[@as table<string, table<string, string>[]>]]
            for _, tools in pairs(languages) do
                for _, tool in ipairs(tools) do
                    local cmd = tool.lintCommand or tool.formatCommand or tool.hoverCommand
                    local bin = vim.fn.fnamemodify(vim.split(cmd, ' ')[1], ':t')
                    vim.list_extend(ensure_installed, { bin })
                end
            end
        end

        local formatters_by_ft = require 'tools.formatters'
        for _, formatters in pairs(formatters_by_ft) do
            local names = type(formatters) == 'function' and formatters(0) or formatters
            ---@type string[]
            names = type(names) == 'table' and names or { names }
            for _, name in ipairs(names) do
                if string.match(name, '^prettierd_') then
                    name = 'prettierd'
                elseif string.match(name, '^prettier_') then
                    name = 'prettier'
                elseif string.match(name, '^yq_') then
                    name = 'yq'
                elseif name == 'xmllint' then -- OS package libxml2, not in Mason.
                    name = ''
                elseif name == 'injected' then
                    name = ''
                end
                if name ~= '' then
                    vim.list_extend(ensure_installed, { name })
                end
                -- Dependencies:
                if name == 'prettierd' then
                    vim.list_extend(ensure_installed, { 'prettier' })
                end
            end
        end

        vim.list_extend(ensure_installed, opts.ensure_installed or {})
        opts.ensure_installed = ensure_installed
        require('mason-tool-installer').setup(opts)
    end,
}

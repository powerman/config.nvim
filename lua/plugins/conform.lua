-- [[ Lightweight yet powerful formatter plugin for Neovim ]]
--
--  - Format a lot of different file types using both LSP and 3rd-party tools.
--  - Format embedded code blocks in another language (e.g. in markdown, templates, etc.).
--  - Autoformat on save file.
--
-- INFO: You have to configure formatting for file types you're using! This includes not only
-- modifying this file, but also installing and configuring required 3rd-party tools.
-- List of supported formatters: https://github.com/stevearc/conform.nvim#formatters.
-- TODO: Find out is it possible to automate installation of these tools using mason.
--
-- NOTE: Key `<Leader>f` formats current buffer.
-- NOTE: Cmd `:FormatDisable` disables autoformat.
-- NOTE: Cmd `:FormatDisable!` disables autoformat for a current buffer.

-- Disable autoformat on certain filetypes.
local ignore_filetypes = {
    -- Languages without a well standardized coding style.
    'c',
    'cpp',
}
-- Disable autoformat for files in a certain path.
local ignore_paths = {
    -- Directories with 3rd-party code.
    vim.fn.stdpath 'data' .. '/lazy/',
    '/node_modules/',
    '/vendor/',
    '/go/pkg/mod/', -- Maybe run `go env GOMODCACHE` instead of hardcode?
}

---@type LazySpec
return {
    { -- Autoformat
        'stevearc/conform.nvim',
        version = '*',
        lazy = true,
        event = { 'BufWritePre' },
        cmd = { 'ConformInfo', 'FormatDisable', 'FormatEnable' },
        keys = {
            {
                '<Leader>f',
                function()
                    require('conform').format { async = true, lsp_format = 'fallback' }
                end,
                mode = 'n',
                desc = '[F]ormat buffer',
            },
        },
        opts = {
            notify_on_error = true,
            format_on_save = function(bufnr)
                if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
                    return
                end
                if vim.tbl_contains(ignore_filetypes, vim.bo[bufnr].filetype) then
                    return
                end
                local bufname = vim.api.nvim_buf_get_name(bufnr)
                for _, pattern in ipairs(ignore_paths) do
                    if bufname:match(pattern) then
                        return
                    end
                end
                return { timeout_ms = 500, lsp_format = 'fallback' }
            end,
            -- INFO: After installing these 3rd-party tools do not forget to setup them!
            -- - Globally:
            --   - ~/.editorconfig: setup your preferences for indent
            --   - ~/.prettierrc.yml: add installed plugins
            --   - ~/.stylelintrc.yml
            --   - ~/.config/yamlfmt/yamlfmt.yml
            -- - For some project:
            --   - ./.editorconfig: setup project preferences for indent
            --   - ./sgconfig.yml: use `sg new`
            --   - ./.stylua.toml
            --   - ./.dprint.jsonc: use `dprint init -c .dprint.jsonc`
            --   - ./.yamlfmt.yml
            formatters_by_ft = {
                -- Conform can also run multiple formatters sequentially
                -- python = { "isort", "black" },
                --
                -- You can use a sub-list to tell conform to run *until* a formatter is found.
                -- javascript = { { "prettierd", "prettier" } },
                --
                -- BUG: 'prettierd' does not show error
                -- https://github.com/stevearc/conform.nvim/issues/486

                ['*'] = { 'ast-grep' }, -- Linter/fixer for many treesitter-supported languages.
                asm = { 'asmfmt' }, -- Go Assembler.
                -- bash = { 'shellcheck' },
                bash = { 'shfmt' },
                css = { 'prettierd' },
                -- css = { 'stylelint' },
                csv = { 'yq_csv' },
                dockerfile = { 'dprint' }, -- Require `dprint config add dockerfile`.
                go = { 'gofumpt', 'gci' }, -- Also: 'gofmt', 'goimports', 'goimports-reviser'.
                graphql = { 'prettierd' },
                html = { 'djlint' },
                -- html = { 'prettierd' }, -- Fail on invalid HTML without error message.
                -- javascript = { 'dprint' }, -- Require `dprint config add dprint-plugin-typescript`.
                javascript = { 'prettierd' },
                -- javascript = { 'standardjs' }, -- Fail on invalid JS.
                -- javascriptreact = { 'dprint' }, -- Require `dprint config add dprint-plugin-typescript`.
                javascriptreact = { 'prettierd' },
                -- javascriptreact = { 'standardjs' }, -- Fail on invalid JS.
                -- json = { 'dprint' }, -- Fix some errors. Require `dprint config add dprint-plugin-json`.
                json = { 'fixjson' }, -- Convert relaxed JSON5 to JSON.
                -- json = { 'jq' }, -- Fail on invalid JSON.
                -- json = { 'prettierd' }, -- Fix few errors.
                -- json = { 'yq_json' }, -- Fix few errors.
                json5 = { 'prettierd' },
                jsonc = { 'prettierd' },
                less = { 'prettierd' },
                lua = { 'stylua' },
                -- markdown = { 'dprint', 'injected' }, -- Require `dprint config add markdown`.
                -- markdown = { 'markdownlint', 'injected' },
                -- markdown = { 'markdownlint-cli2', 'injected' },
                markdown = { 'mdformat', 'injected' }, -- With plugins almost as good as dprint.
                -- markdown = { 'prettierd', 'injected' },
                nginx = { 'prettierd_nginx' }, -- Require prettier plugin.
                proto = { 'buf' },
                scss = { 'prettierd' },
                solidity = { 'prettierd' }, -- Require prettier plugin.
                sql = { 'prettierd' }, -- Require prettier plugin.
                template = { 'djlint' }, -- Go/Django/Jinja/Twig/Handlebars/Angular.
                -- template = { 'prettierd' },
                -- toml = { 'dprint' }, -- Require `dprint config add toml`.
                toml = { 'prettierd' }, -- Require prettier plugin.
                tsv = { 'yq_tsv' },
                -- typescript = { 'dprint' }, -- Require `dprint config add dprint-plugin-typescript`.
                typescript = { 'prettierd' },
                -- typescript = { 'standardts' },
                -- typescriptreact = { 'dprint' }, -- Require `dprint config add dprint-plugin-typescript`.
                typescriptreact = { 'prettierd' },
                vue = { 'prettierd' },
                xml = { 'xmllint' },
                -- xml = { 'yq_xml' },
                yaml = { 'yamlfmt' },
                -- yaml = { 'yq' },
            },
        },
        config = function(_, opts)
            require('conform').setup(opts)

            vim.api.nvim_create_user_command('FormatDisable', function(args)
                if args.bang then
                    -- FormatDisable! will disable formatting just for this buffer
                    vim.b.disable_autoformat = true
                else
                    vim.g.disable_autoformat = true
                end
            end, {
                desc = 'Disable autoformat-on-save',
                bang = true,
            })
            vim.api.nvim_create_user_command('FormatEnable', function()
                vim.b.disable_autoformat = false
                vim.g.disable_autoformat = false
            end, {
                desc = 'Re-enable autoformat-on-save',
            })

            local util = require 'conform.util'
            local formatters = require 'conform.formatters'

            ---@return conform.FormatterConfigOverride
            local function yq_for(type)
                return vim.tbl_deep_extend('force', formatters.yq, {
                    args = { '-p', type, '-o', type, '-P', '-' },
                })
            end

            ---@return conform.FormatterConfigOverride
            local function prettierd_for(filename)
                return vim.tbl_deep_extend('force', formatters.prettierd, {
                    args = { filename },
                    range_args = function(self, ctx)
                        local args = formatters.prettierd.range_args(self, ctx)
                        args[1] = filename
                        return args
                    end,
                })
            end

            require('conform').formatters.injected = {
                options = {
                    -- lang_to_ext = {
                    --     lua = 'lua',
                    -- },
                    -- Map of treesitter language to formatters to use
                    -- (defaults to the value from formatters_by_ft)
                    lang_to_formatters = {
                        -- HACK: Work around https://github.com/stevearc/conform.nvim/issues/485
                        html = {},
                    },
                },
            }
            require('conform').formatters.gci = {
                cwd = util.root_file { 'go.mod' },
                append_args = { '-s', 'standard', '-s', 'default', '-s', 'localmodule' },
            }
            require('conform').formatters.standardts =
                vim.tbl_deep_extend('force', formatters.standardjs, {
                    command = util.from_node_modules 'ts-standard',
                })
            require('conform').formatters.prettierd_nginx = prettierd_for 'FAKE.nginx'
            require('conform').formatters.yq_csv = yq_for 'csv'
            require('conform').formatters.yq_json = yq_for 'json'
            require('conform').formatters.yq_tsv = yq_for 'tsv'
            require('conform').formatters.yq_xml = yq_for 'xml'
        end,
    },
}

--[[ Lightweight yet powerful formatter plugin for Neovim ]]
--
--  - Format a lot of different file types using both LSP and 3rd-party tools.
--  - Format embedded code blocks in another language (e.g. in markdown, templates, etc.).
--  - Autoformat on save file.
--
--  Formatter vs LSP:
--    - LSP may provide no/different/same formatting.
--    - LSP formatting is used as a fallback in case no formatting tool is supported/configured.
--    - Unlike Formatter, LSP is able to show errors (which result in skipped formatting).
--      - While you may see Formatter error using `:ConformInfo` it's very inconvenient.
--    - Unlike LSP, Formatter uses standalone tools, usualy used to validate formatting on CI.
--      - Thus if both Formatter and LSP are able to format then Formatter tool is used.
--
-- INFO: You have to configure formatting for file types you're using! This includes not only
-- modifying this file, but also configuring required 3rd-party tools.
-- List of supported formatters: https://github.com/stevearc/conform.nvim#formatters.

-- NOTE:  <Leader>f         Format current buffer.
-- NOTE:  :FormatDisable    Disables autoformat on save.
-- NOTE:  :FormatDisable!   Disables autoformat on save for the buffer.
-- NOTE:  :FormatEnable     Re-enable autoformat on save.
-- NOTE:  :ConformInfo      Show formatters info and log.

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
    '[.]golangci.*[.]yml', -- Follow formatting of original `.golangci.reference.yml` for ease diff.
}

---@module 'lazy'
---@type LazySpec
return {
    {
        'stevearc/conform.nvim',
        version = '*',
        event = { 'BufWritePre' },
        cmd = { 'ConformInfo', 'FormatDisable', 'FormatEnable' },
        keys = {
            {
                '<Leader>f',
                function()
                    require('conform').format { async = true, lsp_format = 'fallback' }
                end,
                mode = 'n',
                desc = 'Format buffer',
            },
        },
        init = function()
            vim.o.formatexpr = "v:lua.require('conform').formatexpr()"
        end,
        ---@type conform.setupOpts
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
            formatters_by_ft = require 'tools.formatters',
        },
        config = function(_, opts)
            require('conform').setup(opts)

            vim.api.nvim_create_user_command('FormatDisable', function(args)
                if args.bang then
                    -- FormatDisable! will disable formatting just for this buffer.
                    vim.b.disable_autoformat = true
                else
                    vim.g.disable_autoformat = true
                end
            end, {
                desc = 'Disable autoformat on save',
                bang = true,
            })
            vim.api.nvim_create_user_command('FormatEnable', function()
                vim.b.disable_autoformat = false
                vim.g.disable_autoformat = false
            end, {
                desc = 'Re-enable autoformat on save',
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

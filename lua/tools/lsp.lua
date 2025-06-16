local gopls_settings = {
    -- https://github.com/golang/tools/blob/master/gopls/doc/settings.md
    gopls = {
        --- Build:
        -- buildFlags = { '-tags=…' },
        -- env = { VAR = 'VALUE' },
        -- directoryFilters = { '-**/node_modules' },
        templateExtensions = { 'tmpl' },
        -- standaloneTags = { 'ignore' },

        --- Formatting:
        ---
        --- XXX: For now it's much easier and more flexible to use Formatter instead of LSP.
        --- - LSP won't update imports on formatting request, it's implemented as a separate
        ---   Code Action "Organize Imports". It should be either executed manually or we need
        ---   more hacks to somehow call it before each formatting request.
        --- - It's hard to provide `local` in case we need to separate local imports:
        ---   - To provide arg for `local` we need to parse `go.mod`.
        ---   - This should support using different `go.mod` in different buffers.
        ---   - This probably should support work with old packages without `go.mod`.
        --- See https://github.com/neovim/nvim-lspconfig/issues/115.
        ---
        -- ['local'] = 'github.com/company/project',
        gofumpt = true,

        --- UI:
        -- codelenses = {
        --     gc_details = false,
        --     generate = true,
        --     regenerate_cgo = true,
        --     test = false,
        --     run_govulncheck = false,
        --     tidy = true,
        --     upgrade_dependency = true,
        --     vendor = true,
        -- },
        -- semanticTokens = false,
        -- noSemanticString = false,
        -- noSemanticNumber = false,

        --- UI / Completion:
        -- matcher = 'Fuzzy', -- CaseInsensitive|CaseSensitive|Fuzzy
        -- TODO: Is this one better for my completion setup?
        matcher = 'CaseInsensitive',
        -- experimentalPostfixCompletions = true,
        -- completeFunctionCalls = true,

        --- UI / Diagnostic:
        -- https://github.com/golang/tools/blob/master/gopls/doc/analyzers.md
        -- TODO: Hard to say how these intersect with golangci-lint…
        analyses = {
            -- shadow = false,
            unusedvariable = true,
            useany = true,
        },
        -- TODO: Hard to say how these intersect with golangci-lint…
        staticcheck = true,
        -- annotations = {
        --     bounds = true,
        --     escape = true,
        --     inline = true,
        --     ['nil'] = true,
        -- },
        vulncheck = 'Imports', -- Off|Imports
        -- analysisProgressReporting = true,

        --- UI / Documentation:
        -- hoverKind = 'FullDocumentation', -- FullDocumentation|NoDocumentation|SingleLine|Structured|SynopsisDocumentation
        -- linksInHover = true, -- true|false|'gopls'

        --- UI / Inlayhint:
        --- https://github.com/golang/tools/blob/master/gopls/doc/inlayHints.md
        --- TODO: Test this (there is a hotkey to toggle inlay hints).
        hints = {
            -- assignVariableTypes = false,
            compositeLiteralFields = true,
            -- compositeLiteralTypes = false,
            constantValues = true,
            functionTypeParameters = true,
            parameterNames = true,
            -- rangeVariableTypes = false,
        },

        --- UI / Navigation:
        -- importShortcut = 'Both', -- Both|Definition|Link
        -- symbolMatcher = 'FastFuzzy', -- CaseInsensitive|CaseSensitive|FastFuzzy|Fuzzy
        -- symbolStyle = 'Dynamic', -- Dynamic|Full|Package
        -- symbolScope = 'all', -- all|workspace
    },
}

-- Configure 3rd-party tools to be executed by EFM.
local efm_languages = {
    dockerfile = { require 'efmls-configs.linters.hadolint' },
    -- BUG: Leave running processes in unknown curcumstances.
    html = { require 'efmls-configs.linters.djlint' },
    -- Configuration: https://github.com/igorshubovych/markdownlint-cli?tab=readme-ov-file#configuration
    markdown = { require 'efmls-configs.linters.markdownlint' },
    proto = { require 'efmls-configs.linters.buf' },
}

---@module 'lspconfig'
--- Change `cmd` field type to optional because this config is just extending full config.
---@class lspConfigExtender : lspconfig.Config
---@field cmd? string[]|fun(dispatchers: vim.lsp.rpc.Dispatchers): vim.lsp.rpc.PublicClient

-- Enable the following language servers.
--
--  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
--
--  Add any additional override configuration in the following tables. Available keys are:
--    - cmd (table): Override the default command used to start the server.
--    - filetypes (table): Override the default list of associated filetypes for the server.
--    - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
--    - settings (table): Override the default settings passed when initializing the server.
--      For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/.
---@type table<string,lspConfigExtender>
return {
    -- Linter/fixer for many treesitter-supported languages: https://ast-grep.github.io/reference/languages.html.
    -- Will be used only if configured (run `sg new` in project root dir to create sgconfig.yml).
    ast_grep = {},

    -- It actually uses `shellcheck` and `shfmt`.
    -- Configure it in file `.shellcheckrc` in project's root dir (check `:LspInfo`).
    bashls = {},

    -- Version 0.2.0 has just a few features but, still, it's a bit better than yamlls.
    docker_compose_language_service = {},

    -- Dockerfile.
    dockerls = {
        settings = {
            docker = {
                languageserver = {
                    diagnostics = {
                        -- Values must be equal to "ignore", "warning", or "error".
                        deprecatedMaintainer = 'warning',
                        directiveCasing = 'warning',
                        emptyContinuationLine = 'error',
                        instructionCasing = 'warning',
                        instructionCmdMultiple = 'warning',
                        instructionEntrypointMultiple = 'warning',
                        instructionHealthcheckMultiple = 'warning',
                        instructionJSONInSingleQuotes = 'warning',
                    },
                    formatter = {
                        ignoreMultilineInstructions = true,
                    },
                },
            },
        },
    },

    -- Graphviz.
    dotls = {},

    -- General purpose Language Server. It just runs any 3rd-party tools.
    -- Most of available tools are formatters and linters.
    -- Usually works after saving file.
    efm = {
        init_options = {
            documentFormatting = true,
            documentRangeFormatting = true,
            hover = true,
            documentSymbol = true,
            codeAction = true,
            completion = true,
        },
        settings = {
            rootMarkers = { '.git/' },
            languages = efm_languages,
            lintDebounce = 1000000000, -- 1 second, to lower CPU usage.
        },
        filetypes = vim.tbl_keys(efm_languages),
    },

    -- Works after saving file.
    golangci_lint_ls = {},

    gopls = {
        cmd = { 'gopls', '-remote=auto' }, -- Autostart daemon.
        settings = gopls_settings,
    },

    html = {
        -- init_options = {
        --     configurationSection = { 'html', 'css', 'javascript' },
        --     embeddedLanguages = {
        --         css = true,
        --         javascript = true,
        --     },
        --     provideFormatter = true,
        -- },
    },

    jqls = {},

    jsonls = {
        -- init_options = {
        --     provideFormatter = true,
        -- },
        settings = {
            json = {
                -- To add your own schemas see https://github.com/b0o/schemastore.nvim?tab=readme-ov-file#usage.
                schemas = require('schemastore').json.schemas(),
                -- https://github.com/b0o/SchemaStore.nvim/issues/8
                validate = { enable = true },
            },
        },
    },

    lua_ls = {
        settings = {
            Lua = {
                completion = {
                    callSnippet = 'Replace',
                },
                -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
                -- diagnostics = { disable = { 'missing-fields' } },
            },
        },
    },

    -- May need extra setup, see: https://github.com/Feel-ix-343/markdown-oxide.
    markdown_oxide = {}, -- Markdown with Obsidian support.

    -- marksman = {}, -- Markdown.

    -- Configure: https://github.com/joe-re/sql-language-server?tab=readme-ov-file#configuration
    -- sqlls = {},

    -- Configure: https://github.com/sqls-server/sqls?tab=readme-ov-file#db-configuration
    -- sqls = {},

    taplo = {},

    yamlls = {
        filetypes = {
            'yaml',
            -- 'yaml.docker-compose', -- Conflicts with docker_compose_language_service.
            'yaml.gitlab',
        },
        settings = {
            yaml = {
                schemaStore = {
                    -- You must disable built-in schemaStore support if you want to use
                    -- 'schemastore' plugin and its advanced options like `ignore`.
                    enable = false,
                    -- Avoid TypeError: Cannot read properties of undefined (reading 'length').
                    url = '',
                },
                -- To add your own schemas see https://github.com/b0o/schemastore.nvim?tab=readme-ov-file#usage.
                schemas = require('schemastore').yaml.schemas(),
            },
        },
    },
}

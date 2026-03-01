local gopls_settings = {
    -- https://github.com/golang/tools/blob/master/gopls/doc/settings.md
    -- Updated to commit 83aca55 (2026-02-27).
    gopls = {
        --- Build:
        ---
        -- buildFlags = {}, -- { '-tags=…' }
        -- env = {}, -- { VAR = 'VALUE' }
        -- directoryFilters = { '-**/node_modules' },
        templateExtensions = { 'gotmpl', 'tmpl' },
        -- expandWorkspaceToModule = true,
        --- standaloneTags specifies a set of build constraints that identify individual Go
        --- source files that make up the entire main package of an executable.
        --- A common example of standalone main files is the convention of using the directive
        --- //go:build ignore to denote files that are not intended to be included in any
        --- package, for example because they are invoked directly by the developer using go run.
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
        -- ['local'] = '', -- 'github.com/company/project',
        gofumpt = true,

        --- UI:
        ---
        codelenses = {
            --- This codelens source annotates any //go:generate comments with commands to run
            --- go generate in this directory, on all directories recursively beneath this one.
            -- generate = true,
            --- This codelens source annotates an import "C" declaration with a command to
            --- re-run the cgo command to regenerate the corresponding Go declarations.
            --- Use this after editing the C code in comments attached to the import, or in C
            --- header files included by it.
            -- regenerate_cgo = true,
            --- This codelens source annotates each Test and Benchmark function in a *_test.go
            --- file with a command to run it.
            --- This source is off by default because VS Code has a client-side custom UI for
            --- testing, and because progress notifications are not a great UX for streamed
            --- test output.
            -- test = false,
            --- This codelens source annotates the module directive in a go.mod file with a
            --- command to run Govulncheck asynchronously.
            -- run_govulncheck = true,
            --- This codelens source annotates the module directive in a go.mod file with a
            --- command to run go mod tidy, which ensures that the go.mod file matches the
            --- source code in the module.
            -- tidy = true,
            --- This codelens source annotates the module directive in a go.mod file with
            --- commands to:
            --- - check for available upgrades,
            --- - upgrade direct dependencies, and
            --- - upgrade all dependencies transitively.
            -- upgrade_dependency = true,
            --- This codelens source annotates the module directive in a go.mod file with a
            --- command to run go mod vendor, which creates or updates the directory named
            --- vendor in the module root so that it contains an up-to-date copy of all
            --- necessary package dependencies.
            -- vendor = true,
            --- This codelens source annotates the module directive in a go.mod file with a
            --- command to run govulncheck synchronously.
            vulncheck = true,
        },
        -- semanticTokens = false,
        -- semanticTokenTypes = {}, -- { string=false, number=false }
        -- semanticTokenModifiers = {},
        --- newGoFileHeader enables automatic insertion of the copyright comment and package
        --- declaration in a newly created Go file.
        -- newGoFileHeader = true,
        --- renameMovesSubpackages enables Rename operations on packages to move
        --- subdirectories of the target package.
        renameMovesSubpackages = true,

        --- Completion:
        ---
        --- placeholders enables placeholders for function parameters or struct fields in
        --- completion responses.
        -- usePlaceholders = false,
        -- matcher = 'Fuzzy', -- CaseInsensitive|CaseSensitive|Fuzzy
        -- experimentalPostfixCompletions = true,
        --- experimentalPostfixCompletions enables artificial method snippets such as
        --- "someSlice.sort!".
        -- completeFunctionCalls = true,

        --- Diagnostic:
        ---
        --- https://github.com/golang/tools/blob/master/gopls/doc/analyzers.md
        -- analyses = {},
        staticcheck = true,
        -- staticcheckProvided = false,
        --- annotations specifies the various kinds of compiler optimization details that
        --- should be reported as diagnostics when enabled for a package by the "Toggle
        --- compiler optimization details" (gopls.gc_details) command.
        -- annotations = {
        --     bounds = true,
        --     escape = true,
        --     inline = true,
        --     ['nil'] = true,
        -- },
        -- vulncheck = 'Prompt', -- Off|Imports|Prompt
        --- diagnosticsTrigger controls when to run diagnostics.
        --- - "Edit": Trigger diagnostics on file edit and save. (default)
        --- - "Save": Trigger diagnostics only on file save. Events like initial workspace
        ---           load or configuration change will still trigger diagnostics.
        -- diagnosticsTrigger = 'Edit',
        -- analysisProgressReporting = true,

        --- Documentation:
        ---
        --- hoverKind controls the information that appears in the hover text.
        --- SingleLine is intended for use only by authors of editor plugins.
        -- hoverKind = 'FullDocumentation', -- FullDocumentation|NoDocumentation|SingleLine|SynopsisDocumentation
        -- linkTarget = 'pkg.go.dev',
        --- linksInHover controls the presence of documentation links in hover markdown.
        --- - false: do not show links
        --- - true: show links to the linkTarget domain
        --- - "gopls": show links to gopls' internal documentation viewer
        -- linksInHover = true,

        --- Inlayhint:
        ---
        --- https://github.com/golang/tools/blob/master/gopls/doc/inlayHints.md
        hints = {
            --- controls inlay hints for variable types in assign statements:
            ---   i/* int*/, j/* int*/ := 0, len(r)-1
            -- assignVariableTypes = false,
            --- inlay hints for composite literal field names:
            ---   {/*in: */"Hello, world", /*want: */"dlrow ,olleH"}
            compositeLiteralFields = true,
            --- controls inlay hints for composite literal types:
            ---   for _, c := range []struct {
            ---     in, want string
            ---   }{
            ---     /*struct{ in string; want string }*/{"Hello, world", "dlrow ,olleH"},
            ---   }
            -- compositeLiteralTypes = false,
            --- controls inlay hints for constant values:
            ---   const (
            ---     KindNone   Kind = iota/* = 0*/
            ---     KindPrint/*  = 1*/
            ---     KindPrintf/* = 2*/
            ---     KindErrorf/* = 3*/
            ---   )
            constantValues = true,
            --- inlay hints for implicit type parameters on generic functions:
            ---   myFoo/*[int, string]*/(1, "hello")
            functionTypeParameters = true,
            --- inlay hints for implicitly discarded errors:
            ---   f.Close() // ignore error
            ignoredError = true,
            --- controls inlay hints for parameter names:
            ---   parseInt(/* str: */ "123", /* radix: */ 8)
            parameterNames = true,
            --- controls inlay hints for variable types in range statements:
            ---   for k/* int*/, v/* string*/ := range []string{} {
            ---     fmt.Println(k, v)
            ---   }
            -- rangeVariableTypes = false,
        },

        --- Navigation:
        ---
        --- importShortcut specifies whether import statements should link to documentation or
        --- go to definitions.
        -- importShortcut = 'Both', -- Both|Definition|Link
        -- symbolMatcher = 'FastFuzzy', -- CaseInsensitive|CaseSensitive|FastFuzzy|Fuzzy
        --- symbolScope controls which packages are searched for workspace/symbol requests.
        --- When the scope is "workspace", gopls searches only workspace packages. When the
        --- scope is "all", gopls searches all loaded packages, including dependencies and the
        --- standard library.
        -- symbolScope = 'all', -- all|workspace
        --- maxFileCacheBytes sets a soft limit on the file cache size in bytes.
        --- If zero, the default budget is used.
        -- maxFileCacheBytes = 0,
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
    -- Language server for GitHub Actions.
    gh_actions_ls = {},

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
            documentSymbol = false, -- Duplicates all symbols for markdown.
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
                workspace = {
                    -- Required to force Lua_LS to initialize workspace on Neovim start.
                    -- Without this there is a race condition and workspace may or may not be
                    -- initialized when you open a Lua file.
                    -- If workspace is not initialized, Lua_LS won't recognize Neovim API
                    -- and will throw errors for all `vim.*` calls.
                    library = {},
                },
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

    -- BUG: taplo 0.10.0 adds 1 second delay on exit from Neovim.
    -- taplo = {}, -- TOML.
    tombi = {}, -- TOML.

    ts_ls = {},

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

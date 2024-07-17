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
        -- TODO: Setup a function/hook to set it on attach from `go.mod`.
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
---@module 'lspconfig'
---@type table<string,lspconfig.Config>
return {
    -- Will be used only if configured (project has sgconfig.yml in a root dir).
    ast_grep = {},

    -- It actually uses `shellcheck` and `shfmt`. Configure it in file `.shellcheckrc` in
    -- project's root dir (check `:LspInfo`).
    bashls = {},

    gopls = {
        cmd = { 'gopls', '-remote=auto' }, -- Autostart daemon.
        settings = gopls_settings,
    },

    lua_ls = {
        -- cmd = {...},
        -- filetypes = { ...},
        -- capabilities = {},
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

    termux_ls = {},

    yamlls = {},
}

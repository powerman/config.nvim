---@type table<string, conform.FiletypeFormatter>
return {
    -- Conform can also run multiple formatters sequentially
    -- python = { "isort", "black" },
    --
    -- You can use a sub-list to tell conform to run *until* a formatter is found.
    -- javascript = { { "prettierd", "prettier" } },
    --
    -- BUG: 'prettierd' does not show error
    -- https://github.com/stevearc/conform.nvim/issues/486

    asm = { 'asmfmt' }, -- Go Assembler.
    sh = { 'shfmt' },
    css = { 'prettierd' },
    -- css = { 'stylelint' },
    csv = { 'yq_csv' },
    -- dockerfile = { 'dprint' }, -- Require `dprint config add dockerfile`.
    go = { 'goimports', 'gci', 'gofumpt' }, -- Also: 'gofmt', 'goimports-reviser'.
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
    -- markdown = { 'dprint', 'injected' }, -- Require `dprint config add markdown`. Almost as good as prettierd.
    -- markdown = { 'markdownlint', 'injected' },
    -- markdown = { 'markdownlint-cli2', 'injected' },
    -- markdown = { 'mdformat', 'injected' }, -- With plugins almost as good as dprint.
    markdown = { 'prettierd', 'injected' }, -- Best support for Obsidian!
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
}

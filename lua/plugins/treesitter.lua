--[[ Treesitter configurations and abstraction layer ]]
--
--  Provides a simple and easy way to use the interface for tree-sitter in Neovim and
--  modules for some basic functionality such as syntax highlighting. Available modules:
--      - highlight
--      - indent
--      - incremental_selection
--
-- There are additional nvim-treesitter modules that you can use to interact
-- with nvim-treesitter. You should go explore a few and see what interests you:
--
--    - Incremental selection: sustech-data/wildfire.nvim
--    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
--    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
--
--  There are other available modules: https://github.com/nvim-treesitter/nvim-treesitter/wiki/Extra-modules-and-plugins
--  For example, nvim-treesitter-refactor can provide you with LSP-like features (highlight
--  definitions/usages of a symbol, symbol rename within a scope, goto definitions) without an
--  LSP server - but this will work only within single file.
--
--  Other plugins may use this one for code editing (e.g. folding) and navivation (e.g. use
--  'function definition' or 'for loop' syntax node as Neovim text object to
--  jump/delete/replace/etc.) with full support of corresponding language's syntax tree.
--
--  INFO: To enable folding by syntax tree in current window:
--      vim.wo.foldmethod = 'expr'
--      vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

-- NOTE:  :TSModuleInfo   Show supported language/module matrix.
-- NOTE:  <M-v> <BS>      Increment/decrement selection by syntax tree.

-- Map of treesitter parser name -> Neovim filetype.
-- Use false as filetype for embedded/injected parsers that have no standalone filetype
-- (they are activated automatically via treesitter injections, not via FileType autocmd).
local languages = {
    bash = 'sh',
    c = 'c',
    css = 'css',
    diff = 'diff',
    dockerfile = 'dockerfile',
    editorconfig = 'editorconfig',
    git_config = 'gitconfig',
    git_rebase = 'gitrebase',
    gitattributes = 'gitattributes',
    gitcommit = 'gitcommit',
    gitignore = 'gitignore',
    go = 'go',
    gomod = 'gomod',
    gotmpl = 'gotmpl',
    gowork = 'gowork',
    html = 'html',
    http = 'http',
    ini = 'ini',
    javascript = 'javascript',
    jsdoc = false, -- embedded in javascript/typescript, no filetype
    kdl = 'kdl', -- embedded in bash via #USAGE comments (usage-cli tool)
    json = 'json',
    json5 = 'json5',
    jsonnet = 'jsonnet',
    lua = 'lua',
    luadoc = false, -- embedded in lua, no filetype
    make = 'make',
    markdown = 'markdown',
    markdown_inline = false, -- embedded in markdown, no filetype
    mermaid = 'mermaid',
    muttrc = 'muttrc',
    nginx = 'nginx',
    printf = false, -- embedded in c/bash/etc., no filetype
    promql = 'promql',
    proto = 'proto',
    query = 'query',
    sql = 'sql',
    ssh_config = 'sshconfig',
    strace = 'strace',
    tmux = 'tmux',
    toml = 'toml',
    udev = 'udevrules',
    vim = 'vim',
    vimdoc = 'help',
    xcompose = 'xcompose',
    yaml = 'yaml',
}

local function parsers()
    return vim.tbl_keys(languages)
end

local function filetypes()
    local ft = {}
    for _, filetype in pairs(languages) do
        if filetype then
            ft[#ft + 1] = filetype
        end
    end
    return ft
end

---@module 'lazy'
---@type LazySpec
return {
    {
        'nvim-treesitter/nvim-treesitter',
        lazy = false,
        build = ':TSUpdate',
        init = function()
            -- Source: https://mise.jdx.dev/mise-cookbook/neovim.html
            require('vim.treesitter.query').add_predicate('is-mise?', function(_, _, bufnr, _)
                local filepath = vim.api.nvim_buf_get_name(tonumber(bufnr) or 0)
                local filename = vim.fn.fnamemodify(filepath, ':t')
                return string.match(filename, '.*mise.*%.toml$') ~= nil
            end, { force = true, all = false })

            vim.api.nvim_create_autocmd('FileType', {
                pattern = filetypes(),
                callback = function()
                    -- syntax highlighting, provided by Neovim
                    vim.treesitter.start()
                    -- folds, provided by Neovim
                    vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
                    vim.wo.foldmethod = 'expr'
                    -- indentation, provided by nvim-treesitter
                    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                end,
            })
        end,
        config = function(_, _)
            require('nvim-treesitter').install(parsers())
        end,
    },
    {
        'nvim-treesitter/nvim-treesitter-textobjects',
        dependencies = { 'nvim-treesitter/nvim-treesitter' },
    },
    {
        -- Incremental selection by treesitter nodes (replacement for removed incremental_selection module).
        -- <M-v> in normal mode: start visual selection at current node.
        -- <M-v> in visual mode: expand selection to parent node.
        -- <BS> in visual mode: shrink selection to child node.
        'sustech-data/wildfire.nvim',
        dependencies = { 'nvim-treesitter/nvim-treesitter' },
        keys = { { '<M-v>', mode = { 'n', 'x' } }, { '<BS>', mode = 'x' } },
        opts = {
            keymaps = {
                init_selection = '<M-v>',
                node_incremental = '<M-v>',
                node_decremental = '<BS>',
            },
        },
    },
}

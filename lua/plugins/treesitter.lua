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
--    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
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

---@module 'lazy'
---@type LazySpec
return {
    {
        'nvim-treesitter/nvim-treesitter',
        lazy = false,
        -- TODO: Update to 'main' branch after
        -- https://github.com/nvim-treesitter/nvim-treesitter-textobjects/issues/772
        -- Also check for telescope errors on <F3> after upgrade.
        branch = 'master',
        build = ':TSUpdate',
        main = 'nvim-treesitter.configs', -- Sets main module to use for opts
        opts = {
            ensure_installed = {
                'bash',
                'c',
                'css',
                'diff',
                'dockerfile',
                'editorconfig',
                'git_config',
                'git_rebase',
                'gitattributes',
                'gitcommit',
                'gitignore',
                'go',
                'gomod',
                'gotmpl',
                'gowork',
                'html',
                'http',
                'ini',
                'javascript',
                'jsdoc',
                'json',
                'json5',
                'jsonc',
                'jsonnet',
                'lua',
                'luadoc',
                'make',
                'markdown',
                'markdown_inline',
                'mermaid',
                'muttrc',
                'nginx',
                'printf',
                'promql',
                'proto',
                'query',
                'sql',
                'ssh_config',
                'strace',
                'tmux',
                'toml',
                'udev',
                'vim',
                'vimdoc',
                'xcompose',
                'yaml',
            },
            -- Autoinstall languages that are not installed. Require `tree-sitter` CLI tool.
            auto_install = true,
            highlight = {
                enable = true,
                -- Setting this to a list of languages will run `:h syntax` and tree-sitter at
                -- the same time for these languages.
                -- This may be useful for some languages which depend on vim's regex
                -- highlighting system (such as Ruby) for indent rules.
                -- If you are experiencing weird indenting issues, add the language to the
                -- list of additional_vim_regex_highlighting and disabled languages for indent.
                additional_vim_regex_highlighting = { 'ruby' },
            },
            indent = {
                enable = true,
                disable = { 'ruby' },
            },
            incremental_selection = {
                enable = true,
                keymaps = {
                    init_selection = '<M-v>',
                    node_incremental = '<M-v>',
                    scope_incremental = false,
                    node_decremental = '<BS>',
                },
            },
        },
        init = function() -- Source: https://github.com/okuuva/mise/blob/main/docs/mise-cookbook/neovim.md
            require('vim.treesitter.query').add_predicate('is-mise?', function(_, _, bufnr, _)
                local filepath = vim.api.nvim_buf_get_name(tonumber(bufnr) or 0)
                local filename = vim.fn.fnamemodify(filepath, ':t')
                return string.match(filename, '.*mise.*%.toml$') ~= nil
            end, { force = true, all = false })
        end,
    },
    {
        'nvim-treesitter/nvim-treesitter-textobjects',
        dependencies = { 'nvim-treesitter/nvim-treesitter' },
    },
}

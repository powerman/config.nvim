--[[ Treesitter configurations and abstraction layer ]]
--
--  Provides a simple and easy way to use the interface for tree-sitter in Neovim and
--  modules for some basic functionality such as syntax highlighting. Available modules:
--      - highlight
--      - indent
--      - incremental_selection
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
        build = ':TSUpdate',
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
                'lua',
                'luadoc',
                'make',
                'markdown',
                'markdown_inline',
                'vim',
                'vimdoc',
                'yaml',
                'toml',
                'json5',
                'jsonc',
                'jsonnet',
                'mermaid',
                'muttrc',
                'nginx',
                'promql',
                'proto',
                'sql',
                'ssh_config',
                'strace',
                'tmux',
                'udev',
                'xcompose',
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
        config = function(_, opts)
            -- [[ Configure Treesitter ]] See `:help nvim-treesitter`

            -- Prefer git instead of curl in order to improve connectivity in some environments
            require('nvim-treesitter.install').prefer_git = true
            require('nvim-treesitter.configs').setup(opts)

            -- There are additional nvim-treesitter modules that you can use to interact
            -- with nvim-treesitter. You should go explore a few and see what interests you:
            --
            --    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
            --    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
            --    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
        end,
    },
    {
        'nvim-treesitter/nvim-treesitter-textobjects',
        dependencies = { 'nvim-treesitter/nvim-treesitter' },
    },
}

--[[ Highly extendable fuzzy finder over lists (files, LSP, etc.) ]]
--
-- INFO: The "Search" here means fuzzy search (unlike "Grep" which uses regexp) with syntax:
--    Token         Match type                  Description
--    sbtrkt        fuzzy-match                 Items that match sbtrkt
--    'wild         exact-match (quoted)        Items that include wild
--    ^music        prefix-exact-match          Items that start with music
--    .mp3$         suffix-exact-match          Items that end with .mp3
--    !fire         inverse-exact-match         Items that do not include fire
--    !^music       inverse-prefix-exact-match  Items that do not start with music
--    !.mp3$        inverse-suffix-exact-match  Items that do not end with .mp3
--    ^a b$ | c$    OR operator                 Items that start with a and end with b OR c
--
-- INFO: The "project" here means either current or some upper directory (detected by `.git/`)
-- and it subdirectories.

-- NOTE:  <C-?>              Telescope: Help on keys.
-- NOTE:  <C-\>              Telescope: Close window.
-- NOTE:  <Leader>sp <F3>    Telescope: Search project's files.
-- NOTE:  <Leader>sf         Telescope: Search dir's files.
-- NOTE:  <Leader>s.         Telescope: Search recent files.
-- NOTE:  <Leader>sn         Telescope: Search Neovim's config files.
-- NOTE:  <Leader>sT         Telescope: Search project's TODOs.
-- NOTE:  <Leader>st         Telescope: Search dir's TODOs.
-- NOTE:  <Leader>sd         Telescope: Search project's diagnostics.
-- NOTE:  <Leader>sh         Telescope: Search Neovim help.
-- NOTE:  <Leader>sk         Telescope: Search Neovim keymaps.
-- NOTE:  <Leader>s/         Telescope: Grep in open files.
-- NOTE:  <Leader>sg         Telescope: Grep in a project's files.
-- NOTE:  <Leader>sw         Telescope: Grep current word in a dir's files.
-- NOTE:  <Leader>/          Telescope: Search in a current buffer.
-- NOTE:  <Leader>ss         Telescope: Search available searches.
-- NOTE:  <Leader>sr         Telescope: Resume previous search.
-- NOTE:  <Leader><Leader>   Telescope: Search Neovim buffers.
-- NOTE:  <M-;>              Telescope: Insert :icon/emoji:.

---@module 'lazy'
---@type LazySpec
return {
    {
        'nvim-telescope/telescope.nvim',
        version = '*',
        dependencies = {
            'nvim-lua/plenary.nvim',
            -- Fastest FZF sorter for telescope written in C.
            { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
            -- Sets vim.ui.select to telescope. That means for example that neovim core stuff
            -- can fill the telescope picker. Example would be lua vim.lsp.buf.code_action().
            'nvim-telescope/telescope-ui-select.nvim',
        },
        event = 'VimEnter',
        keys = {
            {
                '<F3>',
                '<Leader>sp',
                mode = 'n',
                remap = true,
                desc = 'Search Project files',
            },
            {
                '<F3>',
                '<Esc><Leader>sp',
                mode = 'v',
                remap = true,
                desc = 'Search Project files',
            },
            {
                '<F3>',
                '<Esc><Leader>sp',
                mode = 'i',
                remap = true,
                desc = 'Search Project files',
            },
            {
                '<Leader>st',
                '<Cmd>TodoTelescope<CR>',
                desc = '[S]earch Directory [T]odo',
            },
        },
        config = function()
            require('telescope').setup {
                defaults = {
                    -- Tune layout for about 100 columns.
                    layout_strategy = 'vertical',
                    layout_config = {
                        horizontal = {
                            height = vim.g.float_max_height,
                            width = vim.g.float_max_width,
                            preview_cutoff = 30,
                            preview_width = math.floor(vim.fn.winwidth(0) * 0.4),
                        },
                        vertical = {
                            height = vim.g.float_max_height,
                            width = vim.g.float_max_width,
                            preview_cutoff = 8,
                            preview_height = math.floor(vim.fn.winheight(0) * 0.33),
                        },
                    },
                    mappings = {
                        i = {
                            -- Alternative to inconvenient <C-c>.
                            ['<C-Bslash>'] = 'close',
                            -- Unmap <C-L> to restore it default action (clear screen).
                            ['<C-l>'] = false,
                            ['<C-Tab>'] = 'complete_tag',
                            -- Use Alt instead of Ctrl (like in Midnight Commander).
                            ['<C-n>'] = false,
                            ['<C-p>'] = false,
                            ['<A-n>'] = require('telescope.actions').cycle_history_next,
                            ['<A-p>'] = require('telescope.actions').cycle_history_prev,
                            -- Use arrows instead.
                            ['<C-u>'] = false,
                            ['<C-Up>'] = 'preview_scrolling_up',
                            ['<C-d>'] = false,
                            ['<C-Down>'] = 'preview_scrolling_down',
                        },
                        n = {
                            -- Alternative to <Esc>, same as in Insert mode.
                            ['<C-Bslash>'] = 'close',
                        },
                    },
                },
                -- Pickers which usually opens another file should do this in a tab by default.
                pickers = {
                    -- Builtin previewer shows Telescope's source files - not interesting.
                    builtin = { previewer = false },
                    -- Colorscheme previewer should use less screen space for itself.
                    colorscheme = {
                        layout_strategy = 'center',
                        enable_preview = true,
                    },
                    find_files = {
                        mappings = {
                            i = {
                                -- <F3> both opens (Search Project files) and closes.
                                ['<F3>'] = 'close',
                                ['<CR>'] = 'select_tab',
                            },
                        },
                    },
                    grep_string = { mappings = { i = { ['<CR>'] = 'select_tab' } } },
                    help_tags = { mappings = { i = { ['<CR>'] = 'select_tab' } } },
                    live_grep = { mappings = { i = { ['<CR>'] = 'select_tab' } } },
                    lsp_dynamic_workspace_symbols = {
                        mappings = { i = { ['<CR>'] = 'select_tab' } },
                    },
                    oldfiles = { mappings = { i = { ['<CR>'] = 'select_tab' } } },
                },
                extensions = {
                    ['ui-select'] = {
                        require('telescope.themes').get_dropdown {},
                    },
                },
            }

            -- Enable Telescope extensions if they are installed
            pcall(require('telescope').load_extension, 'fzf')
            pcall(require('telescope').load_extension, 'ui-select')

            local builtin = require 'telescope.builtin'
            vim.keymap.set('n', '<Leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
            vim.keymap.set('n', '<Leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
            vim.keymap.set('n', '<Leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
            vim.keymap.set(
                'n',
                '<Leader>ss',
                builtin.builtin,
                { desc = '[S]earch [S]elect Telescope' }
            )
            vim.keymap.set(
                'n',
                '<Leader>sw',
                builtin.grep_string,
                { desc = '[S]earch current [W]ord' }
            )
            vim.keymap.set('n', '<Leader>sg', function()
                local buf_filename = vim.api.nvim_buf_get_name(0)
                local dir = require('lspconfig').util.find_git_ancestor(buf_filename)
                builtin.live_grep { cwd = dir or '.' }
            end, { desc = '[S]earch by [G]rep project' })
            vim.keymap.set(
                'n',
                '<Leader>sd',
                builtin.diagnostics,
                { desc = '[S]earch [D]iagnostics' }
            )
            vim.keymap.set('n', '<Leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
            vim.keymap.set(
                'n',
                '<Leader>s.',
                builtin.oldfiles,
                { desc = '[S]earch Recent Files ("." for repeat)' }
            )
            vim.keymap.set(
                'n',
                '<Leader><Leader>',
                builtin.buffers,
                { desc = '[ ] Find existing buffers' }
            )

            vim.keymap.set('n', '<Leader>/', function()
                builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
                    winblend = 10,
                    previewer = false,
                })
            end, { desc = '[/] Fuzzily search in current buffer' })

            vim.keymap.set('n', '<Leader>s/', function()
                builtin.live_grep {
                    grep_open_files = true,
                    prompt_title = 'Live Grep in Open Files',
                }
            end, { desc = '[S]earch [/] in Open Files' })

            -- Shortcut for searching your Neovim configuration files
            vim.keymap.set('n', '<Leader>sn', function()
                builtin.find_files { cwd = vim.fn.stdpath 'config' }
            end, { desc = '[S]earch [N]eovim files' })

            -- Shortcut for searching your project files
            vim.keymap.set('n', '<Leader>sp', function()
                local buf_filename = vim.api.nvim_buf_get_name(0)
                local dir = require('lspconfig').util.find_git_ancestor(buf_filename)
                builtin.find_files { cwd = dir }
            end, { desc = '[S]earch [P]roject files' })

            -- Shortcut for searching your project todos
            vim.keymap.set('n', '<Leader>sT', function()
                local buf_filename = vim.api.nvim_buf_get_name(0)
                local dir = require('lspconfig').util.find_git_ancestor(buf_filename)
                return '<Cmd>TodoTelescope cwd=' .. dir .. '<CR>'
            end, { expr = true, desc = '[S]earch Project [T]odo' })

            -- Shortcut for searching Nerd Font icons, gitmoji and emoji.
            vim.keymap.set('i', '<M-;>', builtin.symbols, { desc = 'Insert :icon|emoji:' })
        end,
    },
}

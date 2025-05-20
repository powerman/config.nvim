--[[ Highly extendable fuzzy finder over lists (files, LSP, etc.) ]]
--
-- INFO: The "Find" here means fuzzy search (unlike "Grep" which uses regexp) with syntax:
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
-- NOTE:  <Leader>sh         Telescope: Find help.
-- NOTE:  <Leader>sk         Telescope: Find keymap.
-- NOTE:  <Leader>sc         Telescope: Find user config cheatsheet.
-- NOTE:  <Leader>sC         Telescope: Find user config file.
-- NOTE:  <Leader><Leader>   Telescope: Find buffer.
-- NOTE:  <Leader>s.         Telescope: Find recent file.
-- NOTE:  <Leader>s/         Telescope: Grep open files.
-- NOTE:  <Leader>sd         Telescope: Find diagnostics.
-- NOTE:  <Leader>sF <F3>    Telescope: Find project's file.
-- NOTE:  <Leader>sf         Telescope: Find dir's file.
-- NOTE:  <Leader>sT         Telescope: Find project's TODO/BUG/….
-- NOTE:  <Leader>st         Telescope: Find dir's TODO/BUG/….
-- NOTE:  <Leader>sg         Telescope: Grep project.
-- NOTE:  <Leader>sw         Telescope: Find dir for a current word.
-- NOTE:  <Leader>/          Telescope: Find in a buffer.
-- NOTE:  <Leader>ss         Telescope: Find builtin search.
-- NOTE:  <Leader>sr         Telescope: Resume previous search.
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
                '<Leader>sF',
                mode = 'n',
                remap = true,
                desc = "Find project's file",
            },
            {
                '<F3>',
                '<Esc><Leader>sF',
                mode = 'v',
                remap = true,
                desc = "Find project's file",
            },
            {
                '<F3>',
                '<Esc><Leader>sF',
                mode = 'i',
                remap = true,
                desc = "Find project's file",
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
                            -- No idea how to use NORMAL mode in Telescope, so let's skip it.
                            ['<Esc>'] = 'close',
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
                            ['<C-PageUp>'] = 'preview_scrolling_up',
                            ['<C-d>'] = false,
                            ['<C-PageDown>'] = 'preview_scrolling_down',
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
                                -- <F3> both opens (Find project's file) and closes.
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
            vim.keymap.set('n', '<Leader>sh', builtin.help_tags, { desc = 'Find help' })
            vim.keymap.set('n', '<Leader>sk', builtin.keymaps, { desc = 'Find keymap' })
            vim.keymap.set('n', '<Leader>sc', function()
                local dir = vim.fn.stdpath 'config'
                return '<Cmd>TodoTelescope keywords=NOTE cwd=' .. dir .. '<CR>'
            end, { expr = true, desc = 'Find user config cheatsheet' })
            vim.keymap.set('n', '<Leader>sC', function()
                builtin.find_files { cwd = vim.fn.stdpath 'config' }
            end, { desc = 'Find user config file' })

            vim.keymap.set('n', '<Leader><Leader>', builtin.buffers, { desc = 'Find buffer' })
            vim.keymap.set('n', '<Leader>s.', builtin.oldfiles, { desc = 'Find recent file' })
            vim.keymap.set('n', '<Leader>s/', function()
                builtin.live_grep {
                    grep_open_files = true,
                    prompt_title = 'Live Grep in Open Files',
                }
            end, { desc = 'Grep open files' })

            vim.keymap.set(
                'n',
                '<Leader>sd',
                builtin.diagnostics,
                { desc = 'Find diagnostics' }
            )
            vim.keymap.set('n', '<Leader>sF', function()
                local buf_filename = vim.api.nvim_buf_get_name(0)
                local dir = require('lspconfig').util.find_git_ancestor(buf_filename)
                builtin.find_files { cwd = dir }
            end, { desc = "Find project's file" })
            vim.keymap.set('n', '<Leader>sf', builtin.find_files, { desc = "Find dir's file" })
            vim.keymap.set('n', '<Leader>sT', function()
                local buf_filename = vim.api.nvim_buf_get_name(0)
                local dir = require('lspconfig').util.find_git_ancestor(buf_filename)
                return '<Cmd>TodoTelescope cwd=' .. dir .. '<CR>'
            end, { expr = true, desc = "Find project's TODO/BUG/…" })
            vim.keymap.set('n', '<Leader>st', function()
                return '<Cmd>TodoTelescope<CR>'
            end, { expr = true, desc = "Find dir's TODO/BUG/…" })
            vim.keymap.set('n', '<Leader>sg', function()
                local buf_filename = vim.api.nvim_buf_get_name(0)
                local dir = require('lspconfig').util.find_git_ancestor(buf_filename)
                builtin.live_grep { cwd = dir or '.' }
            end, { desc = 'Grep project' })
            vim.keymap.set(
                'n',
                '<Leader>sw',
                builtin.grep_string,
                { desc = 'Find dir for a current word' }
            )
            vim.keymap.set('n', '<Leader>/', function()
                builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
                    winblend = 10,
                    previewer = false,
                })
            end, { desc = 'Find in a buffer' })

            vim.keymap.set('n', '<Leader>ss', builtin.builtin, { desc = 'Find builtin search' })
            vim.keymap.set(
                'n',
                '<Leader>sr',
                builtin.resume,
                { desc = 'Resume previous search' }
            )

            vim.keymap.set('i', '<M-;>', builtin.symbols, { desc = 'Insert :icon/emoji:' })
        end,
    },
}

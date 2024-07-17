---@module 'lazy'
---@type LazySpec
return {
    { -- Fuzzy Finder (files, lsp, etc)
        'nvim-telescope/telescope.nvim',
        version = '*',
        dependencies = {
            { -- If encountering errors, see telescope-fzf-native README for installation instructions
                'nvim-telescope/telescope-fzf-native.nvim',

                -- `build` is used to run some command when the plugin is installed/updated.
                -- This is only run then, not every time Neovim starts up.
                build = 'make',

                -- `cond` is a condition used to determine whether this plugin should be
                -- installed and loaded.
                cond = function()
                    return vim.fn.executable 'make' == 1
                end,
            },
            { 'nvim-telescope/telescope-ui-select.nvim' },
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
            -- Telescope is a fuzzy finder that comes with a lot of different things that
            -- it can fuzzy find! It's more than just a "file finder", it can search
            -- many different aspects of Neovim, your workspace, LSP, and more!
            --
            -- The easiest way to use Telescope, is to start by doing something like:
            --  :Telescope help_tags
            --
            -- After running this command, a window will open up and you're able to
            -- type in the prompt window. You'll see a list of `help_tags` options and
            -- a corresponding preview of the help.
            --
            -- Two important keymaps to use while in Telescope are:
            --  - Insert mode: <c-/>
            --  - Normal mode: ?
            --
            -- This opens a window that shows you all of the keymaps for the current
            -- Telescope picker. This is really useful to discover what Telescope can
            -- do as well as how to actually do it!

            -- [[ Configure Telescope ]]
            -- See `:help telescope` and `:help telescope.setup()`
            require('telescope').setup {
                -- You can put your default mappings / updates / etc. in here
                --  All the info you're looking for is in `:help telescope.setup()`
                defaults = {
                    -- Tune layout for about 100 columns.
                    layout_strategy = 'vertical',
                    layout_config = {
                        horizontal = {
                            height = 0.96,
                            width = 0.96,
                            preview_cutoff = 30,
                        },
                        vertical = {
                            height = 0.96,
                            width = 0.96,
                            preview_cutoff = 8,
                            preview_height = 8,
                        },
                    },
                    mappings = {
                        i = {
                            ['<C-Bslash>'] = 'close', -- Alternative to inconvenient <C-c>.
                            ['<C-u>'] = false,
                            ['<C-Up>'] = 'preview_scrolling_up',
                            ['<C-d>'] = false,
                            ['<C-Down>'] = 'preview_scrolling_down',
                        },
                    },
                },
                -- Pickers which usually opens another file should do this in a tab by default.
                pickers = {
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
                        require('telescope.themes').get_dropdown(),
                    },
                },
            }

            -- Enable Telescope extensions if they are installed
            pcall(require('telescope').load_extension, 'fzf')
            pcall(require('telescope').load_extension, 'ui-select')

            -- See `:help telescope.builtin`
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
            vim.keymap.set(
                'n',
                '<Leader>sg',
                builtin.live_grep,
                { desc = '[S]earch by [G]rep' }
            )
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

            -- Slightly advanced example of overriding default behavior and theme
            vim.keymap.set('n', '<Leader>/', function()
                -- You can pass additional configuration to Telescope to change the theme, layout, etc.
                builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
                    winblend = 10,
                    previewer = false,
                })
            end, { desc = '[/] Fuzzily search in current buffer' })

            -- It's also possible to pass additional configuration options.
            --  See `:help telescope.builtin.live_grep()` for information about particular keys
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
        end,
    },
}

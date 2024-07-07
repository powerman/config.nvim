-- Here is a more advanced example where we pass configuration
-- options to `gitsigns.nvim`. This is equivalent to the following Lua:
--    require('gitsigns').setup({ ... })
--
-- See `:help gitsigns` to understand what the configuration keys do
---@type LazySpec
return {
    { -- Adds git related signs to the gutter, as well as utilities for managing changes
        'lewis6991/gitsigns.nvim',
        opts = {
            signs = {
                changedelete = { text = '┻' },
            },
            signs_staged = {
                changedelete = { text = '┻' },
            },
            on_attach = function(bufnr)
                local gitsigns = require 'gitsigns'

                local function map(mode, l, r, opts)
                    opts = opts or {}
                    opts.buffer = bufnr
                    vim.keymap.set(mode, l, r, opts)
                end

                -- Navigation
                map('n', ']c', function()
                    if vim.wo.diff then
                        vim.cmd.normal { ']c', bang = true }
                    else
                        gitsigns.nav_hunk 'next'
                    end
                end, { desc = 'jump to next git/diff [c]hange' })

                map('n', '[c', function()
                    if vim.wo.diff then
                        vim.cmd.normal { '[c', bang = true }
                    else
                        gitsigns.nav_hunk 'prev'
                    end
                end, { desc = 'jump to previous git/diff [c]hange' })

                -- Views
                map(
                    'n',
                    '<Leader>hp',
                    gitsigns.preview_hunk_inline,
                    { desc = 'git [p]review hunk inline' }
                )
                map('n', '<Leader>hd', gitsigns.diffthis, { desc = 'git [d]iff against index' })
                map('n', '<Leader>hD', function()
                    gitsigns.diffthis '@'
                end, { desc = 'git [D]iff against last commit' })
                map(
                    'n',
                    '<Leader>tD',
                    gitsigns.toggle_deleted,
                    { desc = '[T]oggle git show [D]eleted' }
                )

                -- Actions
                map('n', '<Leader>hs', gitsigns.stage_hunk, { desc = 'git [s]tage hunk' })
                map('v', '<Leader>hs', function()
                    gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
                end, { desc = 'git [s]tage hunk' })
                map(
                    'n',
                    '<Leader>hu',
                    gitsigns.undo_stage_hunk,
                    { desc = 'git [u]ndo stage hunk' }
                )

                map('n', '<Leader>hr', gitsigns.reset_hunk, { desc = 'git [r]eset hunk' })
                map('v', '<Leader>hr', function()
                    gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
                end, { desc = 'git [r]eset hunk' })
                map('n', '<Leader>hR', gitsigns.reset_buffer, { desc = 'git [R]eset buffer' })
            end,
        },
    },
}

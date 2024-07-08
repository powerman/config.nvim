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
                end, { desc = 'Next git|diff [C]hange' })

                map('n', '[c', function()
                    if vim.wo.diff then
                        vim.cmd.normal { '[c', bang = true }
                    else
                        gitsigns.nav_hunk 'prev'
                    end
                end, { desc = 'Previous git|diff [C]hange' })

                -- Views
                map(
                    'n',
                    '<Leader>hp',
                    gitsigns.preview_hunk_inline,
                    { desc = 'Git: [H]unk [P]review Inline' }
                )
                map(
                    'n',
                    '<Leader>hd',
                    gitsigns.diffthis,
                    { desc = 'Git: [H]unk [D]iff against Index' }
                )
                map('n', '<Leader>hD', function()
                    gitsigns.diffthis '@'
                end, { desc = 'Git: [H]unk [D]iff against last Commit' })
                map(
                    'n',
                    '<Leader>tD',
                    gitsigns.toggle_deleted,
                    { desc = 'Git: [T]oggle show [D]eleted' }
                )

                -- Actions
                map('n', '<Leader>hs', gitsigns.stage_hunk, {
                    desc = 'Git: [H]unk [S]tage',
                })
                map('v', '<Leader>hs', function()
                    gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
                end, { desc = 'Git: [H]unk(s) [S]tage' })
                map(
                    'n',
                    '<Leader>hu',
                    gitsigns.undo_stage_hunk,
                    { desc = 'Git: [H]unk [U]ndo last Stage' }
                )

                map('n', '<Leader>hr', gitsigns.reset_hunk, {
                    desc = 'Git: [H]unk [R]eset',
                })
                map('v', '<Leader>hr', function()
                    gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
                end, { desc = 'Git: [H]unk(s) [R]eset' })
                map('n', '<Leader>hR', gitsigns.reset_buffer, {
                    desc = 'Git: [H]unks [R]eset all',
                })
            end,
        },
    },
}

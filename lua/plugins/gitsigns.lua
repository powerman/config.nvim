--[[ Super fast git decorations ]]
--
--  - Signs for added, removed, and changed (including staged) lines.
--  - Status bar integration.
--  - Git blame a whole buffer or a specific line.
--  - Manage git hunks:
--    - Stage hunks (with undo).
--    - Navigation between hunks.
--    - Preview diffs of hunks (with word diff).
--    - Ability to display deleted/changed lines via virtual lines.
--    - Hunk text object.
--
--  There are more features, see `:help gitsigns`.
--
-- INFO: To see git signs use `vim.opt.signcolumn = 'yes'`.
-- INFO: Git branch and diff status provided by this plugin is used by mini.statusline plugin.

-- NOTE:  ]c [c             Git: next/prev hunk.
-- NOTE:  <Leader>hp        Git: preview hunk inline.
-- NOTE:  <Leader>hd        Git: diff against index.
-- NOTE:  <Leader>hD        Git: diff against last commit.
-- NOTE:  <Leader>tD        Git: toggle show deleted.
-- NOTE:  <Leader>hs        Git: stage hunk.
-- NOTE:  <Leader>hu        Git: undo stage hunk.
-- NOTE:  <Leader>hr        Git: reset hunk (get from index).
-- NOTE:  :Gitsigns blame   Git: blame.
-- NOTE: 󰴑 ih                Git: match hunk around cursor.

---@module 'lazy'
---@type LazySpec
return {
    {
        'lewis6991/gitsigns.nvim',
        lazy = true, -- Must be loaded but not critical, so let's use event VeryLazy.
        event = 'VeryLazy',
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
                end, { desc = 'Next git|diff change' })

                map('n', '[c', function()
                    if vim.wo.diff then
                        vim.cmd.normal { '[c', bang = true }
                    else
                        gitsigns.nav_hunk 'prev'
                    end
                end, { desc = 'Previous git|diff change' })

                -- Views
                map(
                    'n',
                    '<Leader>hp',
                    gitsigns.preview_hunk_inline,
                    { desc = 'Git: Hunk preview inline' }
                )
                map(
                    'n',
                    '<Leader>hd',
                    gitsigns.diffthis,
                    { desc = 'Git: Hunk diff against index' }
                )
                map('n', '<Leader>hD', function()
                    gitsigns.diffthis '@'
                end, { desc = 'Git: Hunk diff against last commit' })
                map(
                    'n',
                    '<Leader>tD',
                    gitsigns.toggle_deleted,
                    { desc = 'Git: Toggle show deleted' }
                )

                -- Actions
                map('n', '<Leader>hs', gitsigns.stage_hunk, {
                    desc = 'Git: Hunk stage',
                })
                map('v', '<Leader>hs', function()
                    gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
                end, { desc = 'Git: Hunk(s) stage' })
                map(
                    'n',
                    '<Leader>hu',
                    gitsigns.undo_stage_hunk,
                    { desc = 'Git: Hunk undo last stage' }
                )

                map('n', '<Leader>hr', gitsigns.reset_hunk, {
                    desc = 'Git: Hunk reset',
                })
                map('v', '<Leader>hr', function()
                    gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
                end, { desc = 'Git: Hunk(s) reset' })
                map('n', '<Leader>hR', gitsigns.reset_buffer, {
                    desc = 'Git: Hunks reset all',
                })

                -- Text object
                map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>')
            end,
        },
    },
}

--[[ Setting basic autocommands ]]
--
--  See `:help lua-guide-autocommands`.

-- NOTE:  <CR>   Begin a new line below the cursor and insert text.

-- Highlight when yanking (copying) text.
vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking (copying) text',
    group = vim.api.nvim_create_augroup('user.highlight_yank', { clear = true }),
    callback = function()
        vim.hl.on_yank()
    end,
})

-- Starting `nvim` with multiple files will open them in tabs, so you can use
-- `nvim file1 file2` instead of `nvim -p file1 file2`.
vim.api.nvim_create_autocmd('VimEnter', {
    desc = 'On start open multiple files in own tabs instead of hidden buffers',
    group = vim.api.nvim_create_augroup('user.start_in_tabs', { clear = true }),
    nested = true,
    command = 'if argc() > 1 && !&diff | tab sball | tabfirst | endif',
})

-- For usual files <Enter> begins a new line below the cursor and insert text.
vim.api.nvim_create_autocmd('BufWinEnter', {
    desc = 'Enter begins a new line below the cursor and insert text',
    group = vim.api.nvim_create_augroup('user.map_enter_to_o', { clear = true }),
    callback = function(ev)
        if
            not vim.bo.readonly
            and ev.file ~= 'quickfix'
            and vim.bo.ft ~= 'qf'
            and not vim.wo.diff
            and vim.bo.ft ~= 'diff'
        then
            vim.keymap.set('n', '<CR>', 'o', {
                buffer = ev.buf,
                desc = 'Begin a new line below the cursor and insert text',
            })
        end
    end,
})

-- Setup folding per filetype.
-- NOTE: This autocmd runs after treesitter's FileType autocmd (which sets foldmethod=expr with
-- vim.treesitter.foldexpr()), so it overrides treesitter folding for markdown.
-- Treesitter markdown folding folds individual code blocks, lists, blockquotes etc. as separate
-- nodes inside sections - which is noisy when working with markdown as a document.
-- Our custom expr folds only by headings (^#), giving clean section-level folds matching
-- the visible heading hierarchy: # -> level 1, ## -> level 2, etc.
vim.api.nvim_create_autocmd('BufWinEnter', {
    desc = 'Setup folding per filetype',
    group = vim.api.nvim_create_augroup('user.folding', { clear = true }),
    callback = function(ev)
        if vim.bo.filetype == 'markdown' then
            vim.wo.foldmethod = 'expr'
            vim.wo.foldexpr =
                [[getline(v:lnum) =~# '^#' ? '>' . matchend(getline(v:lnum), '^#*') : '=']]
            -- Remove fold-related info from a folded line (markdown sections already include level).
            vim.wo.foldtext = [[getline(v:foldstart)]]
        else
            -- Workaround for `tab sball` (used in other autocmd above) which will result in
            -- copying window-local options to new windows/tabs and thus apply them to other
            -- files even if they have another filetypes. Reset foldmethod/foldexpr to defaults
            -- for filetypes not handled by treesitter's FileType autocmd.
            if
                vim.wo.foldmethod == 'expr'
                and vim.wo.foldexpr ~= 'v:lua.vim.treesitter.foldexpr()'
            then
                vim.wo.foldmethod = 'manual'
                vim.wo.foldexpr = '0'
            end
            vim.wo.foldtext = [[foldtext()]]
        end

        -- Do not modify folds restored by loading session.
        if vim.g.SessionLoad then
            return
        end
    end,
})

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

-- Enable manual convenient folding for markdown sections.
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
            -- files even if they have another filetypes. So, reset these options to defaults.
            vim.wo.foldmethod = 'manual'
            vim.wo.foldexpr = '0'
            vim.wo.foldtext = [[foldtext()]]
        end

        -- Do not modify folds restored by loading session.
        if vim.g.SessionLoad then
            return
        end
        -- Auto-open all folds on first open.
        -- Use defer_fn for compatibility with opening files with Telescope
        -- (which opens files using async file loading and file contents may not be loaded
        -- at the moment BufWinEnter - or other events like FileReadPost - fires).
        local win = vim.api.nvim_get_current_win()
        vim.defer_fn(function()
            if
                vim.api.nvim_win_is_valid(win)
                and vim.api.nvim_win_get_buf(win) == ev.buf
                and not vim.wo[win].diff
            then
                vim.api.nvim_win_call(win, function()
                    if vim.bo[ev.buf].filetype == 'markdown' then
                        vim.cmd 'normal! zR'
                    else
                        vim.cmd 'normal! zE'
                        vim.cmd 'normal! zx'
                    end
                end)
            end
        end, 30) -- It's a race, of course. Increase in case of issues.
    end,
})

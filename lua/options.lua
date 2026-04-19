--[[ Setting options ]]
--
--  See `:help vim.o`.
--  For more options, you can see `:help option-list`.

-- Support Russian keyboard. Also required for langmapper plugin.
vim.o.langmap = 'ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯ;ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    .. ',фисвуапршолдьтщзйкыегмцчня;abcdefghijklmnopqrstuvwxyz'
    .. ',ё`,Ё~,х[,Х{,ъ],Ъ},ж\\;,Ж:,э\',Э",б\\,,Б<,ю.,Ю>'

-- Enable mouse mode, can be useful for resizing splits for example!
vim.o.mouse = 'a'

-- Don't show the mode, since it's already in the status line.
vim.o.showmode = false

-- Sync clipboard between OS and Neovim.
-- Schedule the setting after `UiEnter` because it can increase startup-time.
vim.schedule(function()
    vim.o.clipboard = 'unnamedplus'
    if (vim.env.WAYLAND_DISPLAY or '') ~= '' and vim.fn.executable 'wl-copy' == 1 then
        -- BUG: https://github.com/neovim/neovim/issues/11804: clipboard=unnamedplus
        -- spawns wl-copy on every yank/delete, which blocks Wayland key auto-repeat.
        --
        -- One possible workaround is https://github.com/bkoropoff/clipipe.
        -- Another is to use OSC 52, if supported by the terminal emulator.
        vim.g.clipboard = 'wl-copy'
        -- If supported, upgrade to OSC 52 to avoid subprocess spawning on every yank/paste.
        local group = vim.api.nvim_create_augroup('clipboard_osc52_upgrade', { clear = true })
        vim.api.nvim_create_autocmd('TermResponse', {
            group = group,
            callback = function()
                if (vim.g.termfeatures or {}).osc52 then
                    vim.g.clipboard = 'osc52'
                    vim.api.nvim_del_augroup_by_id(group)
                end
            end,
        })
    elseif (vim.env.DISPLAY or '') ~= '' and vim.fn.executable 'xclip' == 1 then
        vim.g.clipboard = 'xclip' -- `xsel` conflicts with KDE Plasma Klipper syncronization.
    else
        -- Over SSH or without X11: use OSC 52 escape sequences to access
        -- the local (host) clipboard through the terminal emulator.
        vim.g.clipboard = 'osc52'
    end
end)

-- Set highlight on search.
vim.opt.hlsearch = true

-- Enable break indent.
vim.o.breakindent = true

-- Save undo history.
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term.
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default.
vim.o.signcolumn = 'yes'

-- Decrease update time.
vim.o.updatetime = 250

-- Decrease mapped sequence wait time.
vim.o.timeoutlen = 500

-- Configure how new splits should be opened.
vim.o.splitright = true
vim.o.splitbelow = true

-- Sets how neovim will display certain whitespace/separator characters in the editor.
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.opt.fillchars:append { fold = '┄' }

-- Preview substitutions live, as you type!
vim.o.inccommand = 'split'

-- Show which line your cursor is on.
vim.o.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.o.scrolloff = 6

-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
vim.o.confirm = true

-- Shift + cursor|Home|End starts visual mode selection.
vim.o.keymodel = 'startsel'

-- Disable wrapping.
vim.o.wrap = false

-- When formatting text (e.g. using `gq` or `gw`), recognize numbered lists.
vim.opt.formatoptions:append 'n'

-- Automatically continue current comment when adding new line inside a comment.
vim.opt.formatoptions:append 'ro'

-- After closing a tab switch to a previous tab instead of a next tab.
vim.opt.tabclose:append 'left'
vim.opt.tabclose:append 'uselast'

vim.opt.diffopt:append 'algorithm:histogram'

-- Border for floating windows.
vim.opt.winborder = 'rounded'

-- Don't fold by default, but allow folding based on syntax or indentation.
vim.o.foldlevelstart = 99
vim.o.foldlevel = 99

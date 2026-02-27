--[[ Install `lazy.nvim` plugin manager ]]
--
--  See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info.

local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
    local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
    -- Try to read pinned commit from lazy-lock.json
    local lock_commit
    local lock_file = vim.fn.stdpath 'config' .. '/lazy-lock.json'
    local f = io.open(lock_file, 'r')
    if f then
        local content = f:read '*a'
        f:close()
        local lock = vim.json.decode(content)
        lock_commit = lock and lock['lazy.nvim'] and lock['lazy.nvim'].commit
    end
    local clone_args = {
        'git',
        'clone',
        '--filter=blob:none',
    }
    if lock_commit then
        -- Clone without branch restriction to allow checkout of arbitrary commit
        vim.list_extend(clone_args, { '--no-checkout', lazyrepo, lazypath })
    else
        vim.list_extend(clone_args, { '--branch=stable', lazyrepo, lazypath })
    end
    local out = vim.fn.system(clone_args)
    if vim.v.shell_error ~= 0 then
        error('Error cloning lazy.nvim:\n' .. out)
    end
    if lock_commit then
        out = vim.fn.system { 'git', '-C', lazypath, 'checkout', lock_commit }
        if vim.v.shell_error ~= 0 then
            error('Error checking out lazy.nvim commit ' .. lock_commit .. ':\n' .. out)
        end
    end
end
vim.opt.rtp:prepend(lazypath)

-- Patch :PlenaryBustedFile and :PlenaryBustedDirectory commands to
-- use tests/minimal_init.lua by default.

local cfg_dir = vim.fn.stdpath 'config'
local def_opts = { minimal_init = cfg_dir .. '/tests/minimal_init.lua' }

vim.api.nvim_create_user_command('PlenaryBustedFile', function(opts)
    require('plenary.test_harness').test_directory(opts.fargs[1], def_opts)
end, { nargs = 1, complete = 'file' })

vim.api.nvim_create_user_command('PlenaryBustedDirectory', function(opts)
    if #opts.fargs == 1 then
        table.insert(opts.fargs, '{minimal_init="' .. def_opts.minimal_init .. '"}')
    end
    local args = table.concat(opts.fargs, ' ')
    require('plenary.test_harness').test_directory_command(args)
end, { nargs = '+', complete = 'file' })

vim.keymap.set('n', '<Plug>PlenaryTestFile', '<Cmd>PlenaryBustedFile %<CR>')

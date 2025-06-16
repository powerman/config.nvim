set rtp+=~/.local/share/nvim/lazy/plenary.nvim
runtime plugin/plenary.vim

let test_dir = len(v:argv) > 0 ? v:argv[-1] : 'tests'
try
    execute 'PlenaryBustedDirectory' test_dir "{ minimal_init = 'tests/minimal_init.lua' }"
catch
    echo v:exception
    cquit 1
endtry

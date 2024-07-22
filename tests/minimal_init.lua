-- Documentation:
--  - https://github.com/nvim-lua/plenary.nvim/blob/master/TESTS_README.md
--  - https://github.com/lunarmodules/luassert (plenary vendors some version of it)
--  - https://lunarmodules.github.io/busted/ (plenary mimics part of it)

vim.opt.rtp:append '~/.local/share/nvim/lazy/plenary.nvim'

require 'patch.plenary.busted_format_results'

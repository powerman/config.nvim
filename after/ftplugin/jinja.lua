-- Set inner language for Jinja template files (detected by file name without `.jinja`).
-- Treesitter jinja parser highlights Jinja tags,
-- inner language is highlighted via treesitter injection (after/queries/jinja/injections.scm).

local name = vim.api.nvim_buf_get_name(0):match '^(.+)%.jinja$'
vim.b.jinja_lang = name and vim.filetype.match { filename = name, buf = 0 }

vim.bo.commentstring = '{# %s #}'

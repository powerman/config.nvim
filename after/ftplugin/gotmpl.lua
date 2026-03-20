-- Set inner language for Go template files.
-- Treesitter gotmpl parser highlights {{ }} directives (priority 110).
-- Inner language is highlighted via:
--   - treesitter injection for languages with TS parsers (caddy, ini)
--   - vim syntax for languages without TS parsers (nftables, pfmain)

local filename = vim.fn.expand '%:t'

-- Determine inner language based on filename pattern.
if filename:match '%.nft%.tmpl$' then
    vim.b.gotmpl_lang = 'nftables'
elseif filename == 'main.cf.tmpl' then
    vim.b.gotmpl_lang = 'pfmain'
elseif filename:match '^Caddyfile' then
    vim.b.gotmpl_lang = 'caddy'
elseif filename:match '%.conf%.tmpl$' then
    vim.b.gotmpl_lang = 'ini'
end

-- For languages without treesitter parsers, re-enable vim syntax
-- after treesitter.start() clears it (syntax = '').
local vim_syntax_langs = {
    nftables = true,
    pfmain = true,
}
if vim_syntax_langs[vim.b.gotmpl_lang] then
    vim.schedule(function()
        vim.bo.syntax = vim.b.gotmpl_lang
    end)
end

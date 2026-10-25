-- Jinja templates with custom delimiters (see `vim.g.jinja_delimiters` in init.lua).
vim.filetype.add {
    pattern = {
        ['.*%.jinja'] = function(path)
            if require('custom._jinja').delimiters(path) then
                return '_jinja'
            end
        end,
    },
}

--[[ Treesitter highlighting for Jinja templates, including custom delimiters ]]

---@module 'lazy'
---@type LazySpec
return {
    'powerman/jinja.nvim',
    dev = true,
    ---@module 'jinja'
    ---@type JinjaConfig
    opts = {
        delimiters = {
            -- Copier templates with custom `_envops`.
            {
                dir = '~/Templates/copier-*',
                block = { '#{', '}#' },
                variable = { '#=', '=#' },
                comment = { '#%', '%#' },
            },
        },
    },
}

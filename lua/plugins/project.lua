--[[ Setup project-specific $PATH to use required version of a tool (Formatter|Linter|LSP|…) ]]

---@module 'lazy'
---@type LazySpec
return {
    {
        'project',
        dir = '~/.config/nvim',

        ---@type Config
        opts = {
            root_patterns = {
                '.buildcache/bin',
            },
        },
    },
}

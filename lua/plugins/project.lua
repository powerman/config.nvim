--[[ Support project-specific versions of tools (Formatters, Linters, LSP, …) ]]
--
-- INFO: This is very basic and limited implementation:
-- - Project root directory is detected based on directory where Neovim was started.
-- - That project's tools will be used even if you'll later open file from another project.

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

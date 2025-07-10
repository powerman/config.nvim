local patches_dir = vim.fn.stdpath 'config' .. '/patches'

local function collect_patches(patch_root)
    local plugins = {}
    local ok, entries = pcall(vim.fs.dir, patch_root, { depth = 2 })

    if not ok then
        return plugins
    end

    for name, type in entries do
        if type == 'file' and name:match '^[^/]+/[^/]+%.patch$' then
            local plugin_name = name:match '^([^/]+)'
            plugins[plugin_name] = plugins[plugin_name] or {}
            table.insert(plugins[plugin_name], patch_root .. '/' .. name)
        end
    end

    return plugins
end

---@module 'lazy'
---@type LazySpec
return {
    {
        'powerman/patchr.nvim',
        ---@module 'patchr'
        ---@type patchr.config
        opts = {
            plugins = collect_patches(patches_dir),
        },
    },
}

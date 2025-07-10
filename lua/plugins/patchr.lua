local patch_dir = vim.fn.stdpath 'config' .. '/patch'

local function collect_patches(patch_root)
    local plugins = {}
    -- TODO: If vim.fs.dir does not order entries then we need to sort them.
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
        'nhu/patchr.nvim',
        ---@module 'patchr'
        ---@type patchr.config
        opts = {
            plugins = collect_patches(patch_dir),
        },
    },
}

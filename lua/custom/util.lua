local M = {}

-- Returns project-specific paths to prepend to PATH.
---@param bin_dirs string[] List of project-relative paths to add to PATH.
---@return string path_prefix String to prepend to PATH (empty or ending with ':').
function M.project_path(bin_dirs)
    if not vim.g.project_root then
        vim.notify('vim.g.project_root is not set', vim.log.levels.ERROR)
        return ''
    end

    local result = ''
    for _, bin_dir in ipairs(bin_dirs) do
        bin_dir = vim.fs.joinpath(vim.g.project_root, bin_dir)
        if vim.fn.isdirectory(bin_dir) ~= 0 then
            result = bin_dir .. ':' .. result
        end
    end

    return result
end

return M

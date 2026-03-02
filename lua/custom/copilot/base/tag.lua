--- Tag helper — wraps content in XML-like tags.
--- Ported from tag.tsx.

local M = {}

--- Wrap content in a named tag with optional attributes.
---@param name string
---@param content string
---@param attrs? table<string, string|number|boolean>
---@return string
function M.wrap(name, content, attrs)
    local attr_str = ''
    if attrs then
        for key, value in pairs(attrs) do
            if value ~= nil then
                attr_str = attr_str .. ' ' .. key .. '=' .. vim.json.encode(value)
            end
        end
    end

    if content == '' then
        if attr_str ~= '' then
            return '<' .. name .. attr_str .. ' />\n'
        end
        return ''
    end

    return '<' .. name .. attr_str .. '>\n' .. content .. '\n</' .. name .. '>\n'
end

return M

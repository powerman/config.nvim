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

-- Checks if a codepoint represents a wide Nerd Font icon.
---@param char string Unicode character to check.
---@return boolean is_wide True if char is a wide Nerd Font icon.
local function is_nerd_font_wide_icon(char)
    local codepoint = vim.fn.char2nr(char)
    return (codepoint >= 0x23fb and codepoint <= 0x23fe)
        or codepoint == 0x2665
        or codepoint == 0x2b58
        or (codepoint >= 0xe000 and codepoint <= 0xe09f)
        or (codepoint >= 0xe0c0 and codepoint <= 0xf8ff)
        or (codepoint >= 0xf0001 and codepoint <= 0xfffff)
end

-- Convert string to array of UTF-8 chars.
---@param str string String to convert.
---@return string[] chars Array of UTF-8 characters.
local function utf8_chars(str)
    local chars = {}
    for i = 1, vim.fn.strcharlen(str) do
        table.insert(chars, vim.fn.strcharpart(str, i - 1, 1, true))
    end
    return chars
end

-- Removes spaces after wide Nerd Font icons in a string.
-- Required when using Nerd Fonts Propo variant where wide icons take 2 cells.
--
-- INFO: Use this command to find wide icons in plugin's config:
--  rg -t lua '[\x{23FB}-\x{23FE}\x{2665}\x{2B58}\x{E000}-\x{E09F}\x{E0C0}-\x{F8FF}\x{F0001}-\x{FFFFF}]' lua
--
---@param str string String to process.
---@return string processed String with spaces after wide icons removed.
local function remove_space_after_nerd_icons(str)
    local result = {}
    local chars = utf8_chars(str)
    local i = 1

    while i <= #chars do
        table.insert(result, chars[i])

        if is_nerd_font_wide_icon(chars[i]) and i < #chars and chars[i + 1] == ' ' then
            i = i + 1
        end
        i = i + 1
    end

    return table.concat(result, '')
end

-- Recursively removes spaces after wide icons in any data structure.
-- Only needed when using Nerd Fonts Propo variant where wide icons take 2 cells.
---@param tbl table Table to process in-place.
function M.adapt_nerd_font_propo(tbl)
    if not vim.g.nerd_font_propo then
        return
    end

    if type(tbl) ~= 'table' then
        return
    end

    for k, v in pairs(tbl) do
        if type(v) == 'string' then
            tbl[k] = remove_space_after_nerd_icons(v)
        elseif type(v) == 'table' then
            M.adapt_nerd_font_propo(v)
        end
    end
end

return M

--[[ Highlighting of Jinja templates with custom delimiters ]]
--
--  Treesitter jinja parser supports only default delimiters,
--  so for templates with custom delimiters (e.g. Copier templates with custom `_envops`)
--  the inner language is highlighted by its own treesitter parser,
--  and Jinja tags are highlighted on top of it.
--
--  To highlight tags the buffer text is masked before parsing it with the jinja parser:
--  text outside of tags is replaced by spaces
--  and custom delimiters are replaced by default ones.
--  So custom delimiters must have the same length as default ones
--  to keep positions in the masked text same as in the buffer.

local M = {}

---@class custom.jinja.Delimiters
---@field block string[] Start and end strings of block tags.
---@field variable string[] Start and end strings of variable tags.
---@field comment string[] Start and end strings of comment tags.

---@type custom.jinja.Delimiters
local default_delimiters = {
    block = { '{%', '%}' },
    variable = { '{{', '}}' },
    comment = { '{#', '#}' },
}

-- Higher than treesitter (100) to override highlighting of the inner language.
local priority = vim.hl.priorities.treesitter + 10

local ns = vim.api.nvim_create_namespace 'custom._jinja'

---@type table<integer, custom.jinja.Delimiters>
local attached = {}

---@class custom.jinja.Highlight
---@field [1] integer Row (0-based).
---@field [2] integer Start column (0-based, inclusive).
---@field [3] integer|nil End column (0-based, exclusive), nil means end of line.
---@field [4] string Highlight group.

---@type table<integer, { tick: integer, rows: table<integer, custom.jinja.Highlight[]> }>
local cache = {}

---@class custom.jinja.Tag
---@field [1] integer Start offset (1-based, inclusive).
---@field [2] integer End offset (1-based, exclusive).
---@field [3] string Kind: block, variable or comment.

-- Returns text with everything outside of Jinja tags replaced by spaces (except newlines)
-- and tag delimiters replaced by default ones, and a list of found tags.
-- Tag without end delimiter in the rest of text ends at the end of line.
---@param text string
---@param delims custom.jinja.Delimiters
---@return string masked
---@return custom.jinja.Tag[] tags
function M.mask(text, delims)
    local parts, tags = {}, {}
    local pos = 1
    while true do
        local kind, start
        for k, d in pairs(delims) do
            local s = text:find(d[1], pos, true)
            if s and (not start or s < start) then
                kind, start = k, s
            end
        end
        parts[#parts + 1] = text:sub(pos, (start or 0) - 1):gsub('[^\n]', ' ')
        if not start then
            return table.concat(parts), tags
        end

        local open, close = default_delimiters[kind][1], default_delimiters[kind][2]
        local from = start + #open
        local s = text:find(delims[kind][2], from, true)
        local to = s or text:find('\n', from, true) or #text + 1
        local stop = s and s + #close or to
        tags[#tags + 1] = { start, stop, kind }
        local body = text:sub(from, to - 1)
        parts[#parts + 1] = open .. body .. (s and close or '')
        pos = stop

        -- Jinja does not parse text inside raw block, so skip it up to the endraw tag.
        if kind == 'block' and s and body:match '^[-+]?%s*raw%s*[-+]?$' then
            local endraw = vim.pesc(delims.block[1])
                .. '[-+]?%s*endraw%s*[-+]?'
                .. vim.pesc(delims.block[2])
            local e = text:find(endraw, pos)
            if e then
                parts[#parts + 1] = text:sub(pos, e - 1):gsub('[^\n]', ' ')
                pos = e
            end
        end
    end
end

-- Returns highlights for Jinja tags in lines, grouped by row.
-- Without jinja treesitter parser only tag background is highlighted.
---@param lines string[]
---@param delims custom.jinja.Delimiters
---@return table<integer, custom.jinja.Highlight[]>
function M.highlights(lines, delims)
    local rows = {}
    local function add(sr, sc, er, ec, hl)
        local added = {}
        for row = sr, er do
            added[#added + 1] = { row, row == sr and sc or 0, row == er and ec or nil, hl }
            rows[row] = rows[row] or {}
            table.insert(rows[row], added[#added])
        end
        return added
    end

    local text = table.concat(lines, '\n')
    local masked, tags = M.mask(text, delims)

    -- Tags are sorted, so offsets can be converted to positions in a single pass.
    local row, row_start = 0, 1
    local function position(offset)
        local nl = text:find('\n', row_start, true)
        while nl and nl < offset do
            row, row_start = row + 1, nl + 1
            nl = text:find('\n', row_start, true)
        end
        return row, offset - row_start
    end
    for _, tag in ipairs(tags) do
        local sr, sc = position(tag[1])
        local er, ec = position(tag[2])
        add(sr, sc, er, ec, '@jinja.tag')
    end

    if #tags > 0 and vim.treesitter.language.add 'jinja' then
        local parser = vim.treesitter.get_string_parser(masked, 'jinja')
        local root = parser:parse()[1]:root()
        local query = vim.treesitter.query.get('jinja', 'highlights')
        -- Like treesitter highlighter, the last capture of the same node wins.
        local seen = {}
        -- Tag background is already added above, so skip it if jinja highlights query has it.
        -- Raw block body is masked, so it must keep highlighting of the inner language.
        local skip = {
            spell = true,
            nospell = true,
            ['jinja.tag'] = true,
            ['markup.raw.block'] = true,
        }
        for id, node in query:iter_captures(root, masked) do
            local name = query.captures[id]
            if not name:find '^_' and not skip[name] then
                local sr, sc, er, ec = node:range()
                local key = ('%d:%d:%d:%d'):format(sr, sc, er, ec)
                if seen[key] then
                    for _, hl in ipairs(seen[key]) do
                        hl[4] = '@' .. name
                    end
                else
                    seen[key] = add(sr, sc, er, ec, '@' .. name)
                end
            end
        end
    end
    return rows
end

-- Returns delimiters configured in `vim.g.jinja_delimiters`
-- for a directory containing the file, if any.
---@param path string Absolute path to the file.
---@return custom.jinja.Delimiters|nil
function M.delimiters(path)
    for dir, delims in pairs(vim.g.jinja_delimiters or {}) do
        if vim.glob.to_lpeg(vim.fs.normalize(dir) .. '/**'):match(path) then
            -- Like Jinja environment options, delimiters not set explicitly keep defaults.
            return vim.tbl_extend('force', default_delimiters, delims)
        end
    end
end

vim.api.nvim_set_decoration_provider(ns, {
    on_win = function(_, _, buf)
        if not attached[buf] or vim.bo[buf].filetype ~= '_jinja' then
            return false
        end
        local tick = vim.api.nvim_buf_get_changedtick(buf)
        if not cache[buf] or cache[buf].tick ~= tick then
            local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
            cache[buf] = { tick = tick, rows = M.highlights(lines, attached[buf]) }
        end
    end,
    on_range = function(_, _, buf, begin_row, _, end_row, end_col)
        local last_row = end_col == 0 and end_row - 1 or end_row
        for row = begin_row, last_row do
            for _, hl in ipairs(cache[buf].rows[row] or {}) do
                vim.api.nvim_buf_set_extmark(buf, ns, row, hl[2], {
                    end_row = hl[3] and row or row + 1,
                    end_col = hl[3] or 0,
                    hl_group = hl[4],
                    -- Tokens must be drawn over the tag background.
                    priority = hl[4] == '@jinja.tag' and priority or priority + 1,
                    ephemeral = true,
                    -- Inner language may enable spell (e.g. block tags inside YAML comments).
                    spell = hl[4] == '@comment',
                })
            end
        end
        return last_row + 1
    end,
})

-- Enables highlighting of Jinja tags and the inner language
-- (detected by file name without `.jinja`) in the buffer.
---@param buf integer
function M.attach(buf)
    buf = buf == 0 and vim.api.nvim_get_current_buf() or buf
    local path = vim.api.nvim_buf_get_name(buf)
    local delims = M.delimiters(path) or default_delimiters
    attached[buf] = delims
    cache[buf] = nil
    vim.bo[buf].commentstring = delims.comment[1] .. ' %s ' .. delims.comment[2]

    local name = path:match '^(.+)%.jinja$'
    local ft = name and vim.filetype.match { filename = name, buf = buf }
    local lang = ft and vim.treesitter.language.get_lang(ft)
    if lang and vim.treesitter.language.add(lang) then
        vim.treesitter.start(buf, lang)
    end
end

return M

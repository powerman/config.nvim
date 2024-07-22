-- Patch busted.format_results to avoid output red Failed/Errors if everything is OK.

-- Unmodified code from plenary.busted.
local HEADER = string.rep('=', 40)
local is_headless = require('plenary.nvim_meta').is_headless
local color_table = {
    yellow = 33,
    green = 32,
    red = 31,
}
local color_string = function(color, str)
    if not is_headless then
        return str
    end

    return string.format(
        '%s[%sm%s%s[%sm',
        string.char(27),
        color_table[color] or 0,
        str,
        string.char(27),
        0
    )
end

---@diagnostic disable-next-line: duplicate-set-field
require('plenary.busted').format_results = function(res)
    print ''
    print(color_string('green', 'Success: '), #res.pass)
    if #res.fail > 0 or #res.errs > 0 then
        print(color_string('red', 'Failed : '), #res.fail)
        print(color_string('red', 'Errors : '), #res.errs)
    end
    print(HEADER)
end

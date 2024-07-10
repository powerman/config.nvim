--[[ New operators motions to quickly replace and exchange text ]]
--
--  Replaces given target with current yank. This helps in common scenario when you've first
--  copied some text to clipboard (e.g. by selecting it in a browser) and then noticed this
--  text should replace existing one and… delete exiting before pasting - which result in
--  replacing contents of clipboard with just deleted text. Now you can replace existing text
--  with contents of clipboard (or another register) without deleting it first.
--
--  There are more features, see https://github.com/gbprod/substitute.nvim.
--
-- INFO: Used mapping will be shadowing the change character key `s` so you will have to use
-- the longer form `cl`. Same for `S` (use `cc` instead).

-- NOTE:  s{motion}   Replaces motion target or selection with yank.
-- NOTE:  ss          Replaces line with yank.
-- NOTE:  S           Replaces to the end of line with yank.

---@type LazySpec
return {
    'gbprod/substitute.nvim',
    version = '*',
    lazy = true,
    keys = {
        {
            's',
            function()
                require('substitute').operator()
            end,
            mode = 'n',
            desc = 'Substitute with motion',
        },
        {
            's',
            function()
                require('substitute').visual()
            end,
            mode = 'x',
            desc = 'Substitute selection',
        },
        {
            'ss',
            function()
                require('substitute').line()
            end,
            mode = 'n',
            desc = 'Substitute line',
        },
        {
            'S',
            function()
                require('substitute').eol()
            end,
            mode = 'n',
            desc = 'Substitute to the end of line',
        },
    },
    opts = {
        highlight_substituted_text = {
            timer = 150,
        },
    },
}

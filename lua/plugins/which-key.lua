--[[ Displays a popup with possible keybindings of the command you started typing ]]
--
--  - Uses the `desc` attributes of your mappings as the default label.
--  - Opens a popup with suggestions to complete a key binding.
--  - Built-in plugins:
--    - marks: shows your marks when you hit one of the jump keys.
--    - registers: shows the contents of your registers
--    - presets: help for motions, text-objects, operators, windows, nav, z and g
--    - spelling: spelling suggestions inside the which-key popup

-- NOTE:  <Leader>?   Buffer local keymaps

---@module 'lazy'
---@type LazySpec
return {
    { -- Useful plugin to show you pending keybinds.
        'folke/which-key.nvim',
        version = '*',
        event = 'VeryLazy',
        keys = {
            {
                '<Leader>?',
                function()
                    require('which-key').show { global = false }
                end,
                desc = 'Buffer local keymaps (which-key)',
            },
        },
        ---@type wk.Opts
        opts = {
            preset = 'modern',
            delay = function(ctx)
                return ctx.plugin and 0 or 300
            end,
            expand = 2,
            spec = {
                -- Improve descriptions like "help <key>-default".
                { 'Y', desc = 'Yank to the end of line' },
                { '&', desc = 'Repeat last substitute' },
                { '<C-L>', desc = 'Clears and redraws the screen' },
                -- Add missing.
                { 'ga', desc = 'Get ASCII code dec/hex/oct' },
                { 'gq', desc = 'Format lines in a smart way' },
                -- Improve description.
                { 'gw', desc = 'Format lines as a plain text' },
                -- Improve group descriptions.
                { '[', group = 'Jump to previous' },
                { ']', group = 'Jump to next' },
                { 's', group = 'Surrounding, substitute with {motion}' },
                { 'z', group = 'Fold, spell, scroll' },
                { 'gr', group = 'LSP' },
                { '<Leader>d', group = 'LSP: Document' },
                { '<Leader>g', group = 'LSP: Goto' },
                { '<Leader>h', group = 'Git: Hunk', mode = 'nx' },
                { '<Leader>s', group = 'Search' },
                { '<Leader>t', group = 'Toggle' },
                { '<Leader>w', group = 'LSP: Workspace' },
                -- Hide useless things.
                { '<Plug>(fzf-normal)', hidden = true },
            },
            keys = {
                scroll_down = '<C-Down>',
                scroll_up = '<C-Up>',
            },
        },
        config = function(_, opts)
            -- Workaround for Russian keys are not working when WhichKey menu is shown.
            local lmu = require 'langmapper.utils'
            local wk_state = require 'which-key.state'
            local check_orig = wk_state.check
            wk_state.check = function(state, key) ---@diagnostic disable-line: duplicate-set-field
                if key ~= nil then
                    key = lmu.translate_keycode(key, 'default', 'ru')
                end
                return check_orig(state, key)
            end

            require('which-key').setup(opts)
        end,
    },
}

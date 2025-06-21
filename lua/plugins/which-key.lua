--[[ Displays a popup with possible keybindings of the command you started typing ]]
--
--  - Uses the `desc` attributes of your mappings as the default label.
--  - Opens a popup with suggestions to complete a key binding.
--  - Built-in plugins:
--    - marks: shows your marks when you hit one of the jump keys.
--    - registers: shows the contents of your registers
--    - presets: help for motions, text-objects, operators, windows, nav, z and g
--    - spelling: spelling suggestions inside the which-key popup

-- NOTE:  <F1>     All keymaps
-- NOTE:  <S-F1>   Buffer local keymaps

---@module 'lazy'
---@type LazySpec
return {
    { -- Useful plugin to show you pending keybinds.
        'folke/which-key.nvim',
        version = '*',
        event = 'VeryLazy',
        keys = {
            {
                '<F1>',
                function()
                    require('which-key').show()
                end,
                mode = { 'n', 'i', 'c', 'x', 's', 't' },
                desc = 'All keymaps',
            },
            {
                '<F11>', -- Also <S-F1>.
                function()
                    require('which-key').show { global = false }
                end,
                mode = { 'n', 'i', 'c', 'x', 's', 't' },
                desc = 'Buffer local keymaps',
            },
        },
        ---@type wk.Opts
        opts = {
            preset = 'modern',
            win = {
                zindex = 1001, -- Should be >1000 to show over nvim-cmp windows.
            },
            delay = function(ctx)
                return ctx.plugin and 0 or vim.o.timeoutlen
            end,
            filter = function(mapping)
                return mapping.desc
                    and mapping.desc ~= 'telescope|nop'
                    and mapping.desc ~= 'autopairs map key'
            end,
            replace = {
                desc = {
                    { 'telescope|(.*)', '%1' },
                    { '(.*) LM %(translate .*', '%1' },
                },
            },
            expand = 2,
            spec = {
                -- WARN: There is a conflict between usual mapping and operator-pending mode
                -- mapping with same prefix keys. E.g. '>' starts both '>>' and '>{motion}'.
                -- Adding '>>' result in replacing predefined list with {motion} keys.
                --
                -- Hide useless things.
                {
                    hidden = true,
                    { '<Plug>(fzf-normal)' },
                    { '<S-CR>', desc = 'duplicates <CR>', mode = 'c' },
                    { '<C-S>', desc = 'duplicates <C-K>', mode = 'i' },
                    { 'h', desc = 'Left' },
                    { 'j', desc = 'Down' },
                    { 'k', desc = 'Up' },
                    { 'l', desc = 'Right' },
                },
                -- Add some useful Neovim mappings.
                { 'ga', desc = 'Get ASCII code dec/hex/oct' },
                { 'gq', desc = 'Format lines in a smart way' },
                { '[[', desc = 'Previous help/markdown/… section' },
                { ']]', desc = 'Next help/markdown/… section' },
                -- Add missing user mappings. BUG: Probably they should not be missing?
                { '<Leader>s.', desc = 'Find recent file' },
                { '<Leader>s/', desc = 'Grep open files' },
                -- Improve group descriptions.
                { '[', group = 'Jump to previous' },
                { ']', group = 'Jump to next' },
                { 's', group = 'Surrounding, Replace {motion} with yank' },
                { 'z', group = 'Fold, Spell, Scroll' },
                { 'gr', group = 'LSP' },
                { '<Leader>c', group = 'AI Chat' },
                { '<Leader>d', group = 'LSP: Document' },
                { '<Leader>g', group = 'LSP: Goto' },
                { '<Leader>h', group = 'Git: Hunk', mode = 'nx' },
                { '<Leader>s', group = 'Search' },
                { '<Leader>t', group = 'Toggle' },
                { '<Leader>w', group = 'LSP: Workspace' },
                -- Improve description.
                { 'Y', desc = 'Yank to the end of line' },
                { '&', desc = 'Repeat last substitute' },
                { '<C-L>', desc = 'Clears and redraws the screen' },
                { '<C-U>', desc = 'Delete characters before cursor', mode = 'i' },
                { 'gw', desc = 'Format lines as a plain text' },
                { '<Tab>', desc = 'Complete|Open menu|Menu next|Expand snippet', mode = 'i' },
                { '<Tab>', desc = 'Complete|Open menu|Menu next', mode = 'c' },
                { '<S-Tab>', desc = 'Open menu|Menu previous', mode = 'ic' },
                { '<CR>', desc = 'Complete/Expand menu item', mode = 'i' },
                { '<CR>', desc = 'Complete menu item|Start command', mode = 'c' },
                { '<C-Bslash>', desc = 'Close menu', mode = 'ic' },
                { '<C-Up>', desc = 'Scroll up menu item doc', mode = 'i' },
                { '<C-Down>', desc = 'Scroll down menu item doc', mode = 'i' },
                { '<C-Right>', desc = 'Expand snippet|Snippet next pos', mode = 'i' },
                { '<C-Left>', desc = 'Snippet previous pos', mode = 'i' },
                { '<C-CR>', desc = 'Snippet change choice', mode = 'i' },
                -- Improve icons.
                -- Colors: azure | blue | cyan | green | grey | orange | purple | red | yellow
                {
                    icon = { icon = '󰋗', color = 'grey' },
                    mode = { 'n', 'i', 'c', 'x', 's', 't' },
                    { '<F1>', desc = 'All keymaps' },
                    { '<F11>', desc = 'Buffer local keymaps' },
                },
            },
            keys = {
                scroll_down = '<C-PageDown>',
                scroll_up = '<C-PageUp>',
            },
        },
        config = function(_, opts)
            -- Workaround for Russian keys are not working when WhichKey menu is shown.
            --
            -- Uses external command `xkblayout-state` to detect current keyboard layout
            -- only for ambiguous keys in Russuan layout: .,/
            local cmd = { 'xkblayout-state', 'print', '%s' }
            local has_cmd = vim.fn.executable(cmd[1]) == 1
            local lmu = require 'langmapper.utils'
            local wk_state = require 'which-key.state'
            local check_orig = wk_state.check
            wk_state.check = function(state, key) ---@diagnostic disable-line: duplicate-set-field
                if key ~= nil then
                    local ambiguous = key == '.' or key == ',' or key == '/'
                    if not ambiguous or has_cmd and vim.system(cmd):wait().stdout == 'ru' then
                        key = lmu.translate_keycode(key, 'default', 'ru')
                    end
                end
                return check_orig(state, key)
            end

            require('which-key').setup(opts)
        end,
    },
}

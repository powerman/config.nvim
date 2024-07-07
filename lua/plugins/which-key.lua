--- BUG: Healthcheck show non-existing conflicts because it does not track unmapped keys:
--- https://github.com/folke/which-key.nvim/issues/615

---@type LazySpec
return {
    { -- Useful plugin to show you pending keybinds.
        'folke/which-key.nvim',
        event = 'VeryLazy',
        ---@type Options
        opts = {
            popup_mappings = {
                -- Use lower case to look consistent with <esc> and <bs>.
                scroll_down = '<c-down>',
                scroll_up = '<c-up>',
            },
        },
        config = function(_, opts) -- This is the function that runs, AFTER loading
            require('which-key').setup(opts)

            -- Document existing key chain prefixes and useful key chains.
            require('which-key').register({
                ['['] = 'Jump to previous',
                [']'] = 'Jump to next',
                ['s'] = 'Surrounding',
                ['z'] = 'Fold | Spell | Scroll',
                ['<<'] = 'Lines',
                ['>>'] = 'Lines',
                ['<Leader>c'] = '[C]ode',
                ['<Leader>d'] = '[D]ocument',
                ['<Leader>h'] = 'Git [H]unk',
                ['<Leader>r'] = '[R]ename',
                ['<Leader>s'] = '[S]earch',
                ['<Leader>t'] = '[T]oggle',
                ['<Leader>w'] = '[W]orkspace',
            }, { mode = 'n' })
            require('which-key').register({
                ['<Leader>h'] = 'Git [H]unk',
                ['<'] = 'Indent left',
                ['>'] = 'Indent right',
            }, { mode = 'v' })
        end,
    },
}

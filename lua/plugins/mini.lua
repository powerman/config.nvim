---@type LazySpec
return {
    { -- Collection of various small independent plugins/modules
        'echasnovski/mini.nvim',
        version = '*',
        config = function()
            -- Better Around/Inside textobjects
            --
            -- Examples:
            --  - va)  - [V]isually select [A]round [)]paren
            --  - yinq - [Y]ank [I]nside [N]ext [']quote
            --  - ci'  - [C]hange [I]nside [']quote
            local ai_gen_spec = require('mini.ai').gen_spec
            require('mini.ai').setup {
                n_lines = 500,
                custom_textobjects = {
                    F = ai_gen_spec.treesitter {
                        a = '@function.outer',
                        i = '@function.inner',
                    },
                    c = ai_gen_spec.treesitter {
                        a = { '@conditional.outer', '@loop.outer' },
                        i = { '@conditional.inner', '@loop.inner' },
                    },
                },
            }

            -- Add/delete/replace surroundings (brackets, quotes, etc.)
            --
            -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
            -- - sd'   - [S]urround [D]elete [']quotes
            -- - sr)'  - [S]urround [R]eplace [)] [']
            local sur_ts_input = require('mini.surround').gen_spec.input.treesitter
            require('mini.surround').setup {
                custom_surroundings = {
                    -- Use tree-sitter to search for function call
                    f = {
                        input = sur_ts_input { outer = '@call.outer', inner = '@call.inner' },
                    },
                },
            }

            -- Simple and easy statusline.
            --  You could remove this setup call if you don't like it,
            --  and try some other statusline plugin
            require('mini.statusline').setup { use_icons = vim.g.have_nerd_font }

            -- You can configure sections in the statusline by overriding their
            -- default behavior. For example, here we set the section for
            -- cursor location to LINE:COLUMN
            ---@diagnostic disable-next-line: duplicate-set-field
            MiniStatusline.section_location = function()
                local slash = MiniStatusline.config.use_icons and '' or ' /'
                return '%3l:%-2v' .. slash .. '%L'
            end
            local section_filename = MiniStatusline.section_filename
            ---@diagnostic disable-next-line: duplicate-set-field
            MiniStatusline.section_filename = function(args)
                -- Force short filename.
                return string.gsub(section_filename(args), '%%F', '%%f')
            end

            -- ... and there is more!
            --  Check out: https://github.com/echasnovski/mini.nvim
        end,
    },
}

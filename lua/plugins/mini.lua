--- Status line section for Lazy updates.
---
--- Empty string is returned if window width is lower than `args.trunc_width`.
---@param args table
---@return string: String suitable for 'statusline'.
local function section_lazyupdates(args)
    if MiniStatusline.is_truncated(args.trunc_width) then
        return ''
    end
    local status = require 'lazy.status'
    return status.has_updates() and status.updates() or ''
end

--- Default status line content with added section_lazyupdates.
---@return string: String suitable for 'statusline'.
local function statusline_active()
    local mode, mode_hl = MiniStatusline.section_mode { trunc_width = 120 }
    local git = MiniStatusline.section_git { trunc_width = 40 }
    local diff = MiniStatusline.section_diff { trunc_width = 75 }
    local diagnostics = MiniStatusline.section_diagnostics { trunc_width = 75 }
    local lsp = MiniStatusline.section_lsp { trunc_width = 75 }
    local filename = MiniStatusline.section_filename { trunc_width = 140 }
    local fileinfo = MiniStatusline.section_fileinfo { trunc_width = 120 }
    local location = MiniStatusline.section_location { trunc_width = 75 }
    local search = MiniStatusline.section_searchcount { trunc_width = 75 }

    local lazy_updates = section_lazyupdates { trunc_width = 75 }

    return MiniStatusline.combine_groups {
        { hl = mode_hl, strings = { mode } },
        { hl = 'MiniStatuslineDevinfo', strings = { git, diff, diagnostics, lsp } },
        '%<', -- Mark general truncate point
        { hl = 'MiniStatuslineFilename', strings = { filename } },
        '%=', -- End left alignment
        { hl = 'MiniStatuslineLazyupdates', strings = { lazy_updates } },
        { hl = 'MiniStatuslineFileinfo', strings = { fileinfo } },
        { hl = mode_hl, strings = { search, location } },
    }
end

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
            require('mini.statusline').setup {
                use_icons = vim.g.have_nerd_font,
                content = {
                    active = statusline_active,
                },
            }

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

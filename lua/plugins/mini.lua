--[[ 40+ independent plugins improving overall Neovim experience with minimal effort ]]
--
--  We use only some of available plugins (all already installed but not loaded).
--  See all plugins: https://github.com/echasnovski/mini.nvim?tab=readme-ov-file#modules

--[[ mini.ai - Extend and create a/i textobjects ]]
--
--  - Enhances some builtin textobjects (like `a(`, `a)`, `a'`, and more).
--  - Creates new ones (like `a*`, `a<Space>`, `af`, `a?`, and more).
--  - Allows user to create their own (like based on treesitter, and more).
--  - Has builtins for brackets, quotes, function call, argument, tag, user prompt, and any
--    punctuation/digit/whitespace character.
--
--  Examples:
--    - va)  - [V]isually select [A]round [)]paren
--    - yinq - [Y]ank [I]nside [N]ext [']quote
--    - ci'  - [C]hange [I]nside [']quote

-- NOTE: 󰴑 a{target}    Match around      b{()}q'"Ft…
-- NOTE: 󰴑 i{target}    Match inside      b{()}q'"Ft…
-- NOTE: 󰴑 an{target}   Match around next b{()}q'"Ft…
-- NOTE: 󰴑 in{target}   Match inside next b{()}q'"Ft…
-- NOTE: 󰴑 al{target}   Match around last b{()}q'"Ft…
-- NOTE: 󰴑 il{target}   Match inside last b{()}q'"Ft…

--[[ mini.surround - Add/delete/replace surroundings (brackets, quotes, etc.) ]]
--
--  - Add, delete, replace, find, highlight surrounding (pair of parenthesis, quotes, etc.).
--  - Has builtins for brackets, function call, tag, user prompt, and any
--    alphanumeric/punctuation/whitespace character.
--
--  See: https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-surround.md#features
--
--  Examples:
--    - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
--    - sd'   - [S]urround [D]elete [']quotes
--    - sr)'  - [S]urround [R]eplace [)] [']

-- NOTE:  sa{motion}{target}   Add })'"… around {motion}.
-- NOTE:  sr{target}{target}   Replace surround })'"… with })'"….
-- NOTE:  sd{target}           Delete surround })'"….

--[[ mini.statusline - Minimal and fast statusline module with opinionated default look ]]
--
--  - Define own custom statusline structure for active and inactive windows.
--  - Built-in active mode indicator with colors.
--  - Sections can hide information when window is too narrow.

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

---@module 'lazy'
---@type LazySpec
return {
    {
        'echasnovski/mini.nvim',
        version = '*',
        config = function()
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

            local sur_ts_input = require('mini.surround').gen_spec.input.treesitter
            require('mini.surround').setup {
                custom_surroundings = {
                    -- Use tree-sitter to search for function call
                    f = {
                        input = sur_ts_input { outer = '@call.outer', inner = '@call.inner' },
                    },
                },
            }

            require('mini.statusline').setup {
                use_icons = vim.g.have_nerd_font,
                content = {
                    active = statusline_active,
                },
            }

            -- Set the section for cursor location to LINE:COLUMN/LINES.
            ---@diagnostic disable-next-line: duplicate-set-field
            MiniStatusline.section_location = function()
                local slash = MiniStatusline.config.use_icons and '' or ' /'
                return '%3l:%-2v' .. slash .. '%L'
            end

            -- Force short filename.
            local section_filename = MiniStatusline.section_filename
            ---@diagnostic disable-next-line: duplicate-set-field
            MiniStatusline.section_filename = function(args)
                return string.gsub(section_filename(args), '%%F', '%%f')
            end
        end,
    },
}

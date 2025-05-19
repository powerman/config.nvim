--[[ A completion engine ]]
--
--  - Full support for LSP completion related capabilities.
--  - Powerful customizability via Lua functions.
--  - Smart handling of key mappings.
--  - Completion sources are installed from external repositories and "sourced".
--
--  Check available sources: https://github.com/hrsh7th/nvim-cmp/wiki/List-of-sources

-- NOTE:  <Tab>       Cmp: complete|expand|open menu|next.
-- NOTE:  <S-Tab>     Cmp: open menu|previous.
-- NOTE:  <CR>        Cmp: complete/expand selected.
-- NOTE:  <C-\>       Cmp: abort and close menu.
-- NOTE:  <C-Down>    Cmp: scroll item doc.
-- NOTE:  <C-Up>      Cmp: scroll item doc.
-- NOTE:  <C-Right>   Snip: expand or jump next.
-- NOTE:  <C-Left>    Snip: jump previous.
-- NOTE:  <C-CR>      Snip: change choice.

---@module 'lazy'
---@type LazySpec
return {
    {
        'hrsh7th/nvim-cmp',
        lazy = true,
        event = { 'InsertEnter', 'CmdlineEnter' },
        dependencies = {
            -- Adds completion sources.
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-nvim-lsp-signature-help',
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-path',
            'hrsh7th/cmp-cmdline',
            { 'saadparwaiz1/cmp_luasnip', dependencies = 'L3MON4D3/LuaSnip' },
            'folke/lazydev.nvim',

            -- Adds icons for completion types.
            'onsails/lspkind.nvim',
        },
        config = function()
            local cmp = require 'cmp'
            local types = require 'cmp.types'
            local luasnip = require 'luasnip'
            local lspkind = require 'lspkind'

            local max_buf_size = 1024 * 1024 -- Max size for indexing buffer contents.
            local get_bufnrs_current = function()
                local buf = vim.api.nvim_get_current_buf()
                local line_count = vim.api.nvim_buf_line_count(buf)
                local byte_size = vim.api.nvim_buf_get_offset(buf, line_count)
                return byte_size > max_buf_size and {} or { buf }
            end
            local get_bufnrs_all_visible = function()
                local bufs = {}
                local byte_size = 0
                for _, win in ipairs(vim.api.nvim_list_wins()) do
                    local buf = vim.api.nvim_win_get_buf(win)
                    local line_count = vim.api.nvim_buf_line_count(buf)
                    byte_size = byte_size + vim.api.nvim_buf_get_offset(buf, line_count)
                    bufs[buf] = true
                end
                return byte_size > max_buf_size and {} or vim.tbl_keys(bufs)
            end

            local has_words_before = function()
                if string.match(vim.fn.mode(), '^c') then
                    return true
                end
                local line, col = unpack(vim.api.nvim_win_get_cursor(0))
                local lines = vim.api.nvim_buf_get_lines(0, line - 1, line, true)
                return col ~= 0 and lines[1]:sub(col, col):match '%s' == nil
            end

            -- https://github.com/hrsh7th/nvim-cmp/issues/2072
            vim.keymap.set('c', '<CR>', function()
                if cmp.visible() then
                    return '<S-CR>'
                else
                    return '<CR>'
                end
            end, { remap = true, expr = true })

            ---@diagnostic disable: missing-fields
            cmp.setup {
                window = {
                    completion = cmp.config.window.bordered {
                        border = vim.g.float_border,
                        col_offset = -4, -- Offset icon before completion to the left.
                    },
                    documentation = cmp.config.window.bordered {
                        border = vim.g.float_border,
                    },
                },

                formatting = {
                    fields = { 'kind', 'abbr', 'menu' },
                    format = lspkind.cmp_format {
                        mode = 'symbol',
                        maxwidth = 30,
                        ellipsis_char = '…',
                        show_labelDetails = true,
                        menu = {
                            nvim_lsp = 'LSP',
                            nvim_lsp_signature_help = 'Sig',
                            buffer = 'Buf',
                            path = 'Path',
                            cmdline = 'Cmd',
                            luasnip = 'Snip',
                        },
                    },
                },

                completion = {
                    -- Show menu only when I ask for it!
                    autocomplete = false,
                },

                matching = {
                    -- Allow only prefix matching!
                    disallow_fuzzy_matching = true,
                    disallow_fullfuzzy_matching = true,
                    disallow_partial_fuzzy_matching = true,
                    disallow_partial_matching = true,
                    disallow_prefix_unmatching = true,
                },

                -- HACK: Work around https://github.com/hrsh7th/nvim-cmp/issues/1809.
                preselect = 'None',

                mapping = {
                    -- Smart unobtrusive completion in a shell-like way.
                    --
                    --  - Menu is shown only when user explicitly asks for it and there are
                    --    multiple possible completions/snippets available.
                    --  - Normal editing keys works as usually even if menu is shown:
                    --    - Completion menu might be shown only on <Tab> after word or <S-Tab>.
                    --    - Item in menu can be selected only by extra <Tab> or <S-Tab>.
                    --    - Behaviour of these keys changes only when menu item is selected
                    --      (i.e. after at least two <Tab> or <S-Tab>, meaning active
                    --      interaction with menu):
                    --      - <CR> completes/expands current item.
                    --      - <C-Down>, <C-Up> scroll current item docs.
                    --  - <Tab> action for a current word, with or without menu opened:
                    --    - If there only one possible snippet then expand it.
                    --    - If there only one possible completion then complete it.
                    --    - If there only one possible partial completion then complete it.
                    --    - If there are multiple possible completions then:
                    --      - If menu isn't opened then open menu (without selecting anything,
                    --        so it serves as a hint what you can type next).
                    --      - If menu is opened then select next item.
                    --  - <S-Tab> action:
                    --    - If menu is opened then select previous item.
                    --    - If menu is not opened then open menu (useful on empty line).
                    ['<Tab>'] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            if cmp.complete_common_string() then
                                return
                            elseif #cmp.get_entries() == 1 then
                                cmp.confirm { select = true }
                            else
                                cmp.select_next_item {
                                    behavior = types.cmp.SelectBehavior.Select,
                                }
                            end
                        elseif has_words_before() then
                            cmp.complete()
                            if cmp.complete_common_string() then
                                cmp.close()
                            elseif #cmp.get_entries() == 1 then
                                cmp.confirm { select = true }
                            end
                        else
                            fallback()
                        end
                    end, { 'i', 'c' }),
                    ['<S-Tab>'] = cmp.mapping(function(_)
                        if cmp.visible() then
                            cmp.select_prev_item {
                                behavior = types.cmp.SelectBehavior.Select,
                            }
                        else
                            cmp.complete()
                        end
                    end, { 'i', 'c' }),
                    ['<CR>'] = cmp.mapping(function(fallback)
                        if not cmp.confirm { select = false } then
                            fallback()
                        end
                    end, { 'i' }),
                    ['<S-CR>'] = cmp.mapping(function(fallback)
                        if not cmp.confirm { select = false } then
                            fallback()
                        end
                    end, { 'c' }),
                    ['<C-Bslash>'] = cmp.mapping(function(fallback)
                        if not cmp.abort() then
                            fallback()
                        end
                    end, { 'i', 'c' }),

                    -- Scroll the documentation window.
                    ['<C-Up>'] = cmp.mapping.scroll_docs(-4),
                    ['<C-Down>'] = cmp.mapping.scroll_docs(4),

                    -- INFO: These mappings probably should be in luasnip.lua, but here we can
                    -- easily make them support fallback.
                    ['<C-Right>'] = cmp.mapping(function(fallback)
                        if luasnip.expand_or_locally_jumpable() then
                            luasnip.expand_or_jump()
                        else
                            fallback()
                        end
                    end, { 'i', 's' }),
                    ['<C-Left>'] = cmp.mapping(function(fallback)
                        if luasnip.locally_jumpable(-1) then
                            luasnip.jump(-1)
                        else
                            fallback()
                        end
                    end, { 'i', 's' }),
                    ['<C-CR>'] = cmp.mapping(function(fallback)
                        if luasnip.choice_active() then
                            luasnip.change_choice(1)
                        else
                            fallback()
                        end
                    end, { 'i', 's' }),
                },

                sources = cmp.config.sources({
                    {
                        name = 'lazydev',
                        group_index = 0, -- set group index to 0 to skip loading LuaLS completions
                    },
                }, {
                    { name = 'nvim_lsp_signature_help' },
                }, {
                    {
                        name = 'nvim_lsp',
                        -- Remove Text completions from LSP.
                        -- entry_filter = function(entry, _)
                        --     return types.lsp.CompletionItemKind[entry:get_kind()] ~= 'Text'
                        -- end,
                    },
                    { name = 'luasnip' },
                }, {
                    {
                        name = 'buffer',
                        option = { get_bufnrs = get_bufnrs_all_visible },
                    },
                }),
            }

            cmp.setup.cmdline({ '/', '?' }, {
                sources = {
                    {
                        name = 'buffer',
                        option = { get_bufnrs = get_bufnrs_current },
                    },
                },
            })

            cmp.setup.cmdline(':', {
                -- enabled = false,
                sources = cmp.config.sources({
                    { name = 'path' },
                }, {
                    { name = 'cmdline' },
                }),
                matching = {
                    disallow_symbol_nonprefix_matching = false,
                },
            })
        end,
    },
}

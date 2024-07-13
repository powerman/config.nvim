-- TODO: Add doc.

---@type LazySpec
return {
    {
        'hrsh7th/nvim-cmp',
        event = { 'InsertEnter', 'CmdlineEnter' },
        dependencies = {
            -- Snippet Engine & its associated nvim-cmp source
            -- TODO: Move to `luasnip.lua`.
            -- TODO: Read docs and configure (e.g. add friendly-snippets).
            {
                'L3MON4D3/LuaSnip',
                build = 'make install_jsregexp',
                dependencies = {
                    -- `friendly-snippets` contains a variety of premade snippets.
                    --    See the README about individual language/framework/plugin snippets:
                    --    https://github.com/rafamadriz/friendly-snippets
                    -- {
                    --   'rafamadriz/friendly-snippets',
                    --   config = function()
                    --     require('luasnip.loaders.from_vscode').lazy_load()
                    --   end,
                    -- },
                },
            },

            -- Adds completion sources.
            -- TODO: Read docs for all of them. Setup if needed.
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-path',
            'hrsh7th/cmp-cmdline',
            'saadparwaiz1/cmp_luasnip', -- TODO: Add depencency on luasnip.

            -- Adds icons for completion types.
            'onsails/lspkind.nvim',
        },
        config = function()
            -- See `:help cmp`
            local cmp = require 'cmp'
            local types = require 'cmp.types'
            local luasnip = require 'luasnip'
            luasnip.config.setup {}
            local lspkind = require 'lspkind'

            local has_words_before = function()
                if string.match(vim.fn.mode(), '^c') then
                    return true
                end
                local line, col = unpack(vim.api.nvim_win_get_cursor(0))
                local lines = vim.api.nvim_buf_get_lines(0, line - 1, line, true)
                return col ~= 0 and lines[1]:sub(col, col):match '%s' == nil
            end

            ---@diagnostic disable: missing-fields
            cmp.setup {
                -- TODO: Shouldn't be needed in nvim-0.10. Expand works, but jumps not -
                -- probably jumps should be configured in luasnip? Or just leave it as is.
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },

                window = {
                    completion = cmp.config.window.bordered(),
                    documentation = cmp.config.window.bordered(),
                },

                formatting = {
                    format = lspkind.cmp_format {
                        mode = 'symbol_text',
                        maxwidth = 40,
                        ellipsis_char = '…',
                        show_labelDetails = true,
                        menu = {
                            buffer = '[Buf]',
                            nvim_lsp = '[LSP]',
                            luasnip = '[Snip]',
                            path = '[Path]',
                            cmdline = '[Cmd]',
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

                mapping = {
                    -- Smart unabtrusive completion in a shell-like way.
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
                                cmp.confirm {
                                    select = true,
                                }
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
                    end, { 'i', 'c' }),
                    ['<C-e>'] = cmp.mapping(function(fallback)
                        if not cmp.abort() then
                            fallback()
                        end
                    end, { 'i', 'c' }),

                    -- Scroll the documentation window.
                    ['<C-Up>'] = cmp.mapping.scroll_docs(-4),
                    ['<C-Down>'] = cmp.mapping.scroll_docs(4),

                    -- If you have a snippet like:
                    --  function $name($args)
                    --    $body
                    --  end
                    --
                    -- <C-Right> will move you to the next of each of the expansion locations.
                    -- <C-Left> is similar, except moving you backwards.
                    ['<C-Right>'] = cmp.mapping(function()
                        if luasnip.expand_or_locally_jumpable() then
                            luasnip.expand_or_jump()
                        end
                    end, { 'i', 's' }),
                    ['<C-Left>'] = cmp.mapping(function()
                        if luasnip.locally_jumpable(-1) then
                            luasnip.jump(-1)
                        end
                    end, { 'i', 's' }),
                },
                sources = cmp.config.sources({
                    { name = 'nvim_lsp' },
                    { name = 'luasnip' },
                }, {
                    { name = 'buffer' },
                }),
            }

            cmp.setup.cmdline({ '/', '?' }, {
                sources = {
                    { name = 'buffer' },
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

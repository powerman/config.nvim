--[[ Snippet Engine ]]
--
--  This is a snippet engine. It has a lot of features but does not contain any snippets.
--  Actual snippets may be provided by LSP or some other plugins or loaded from user's dir.
--
--  - Support LSP-style snippets.
--  - Support VSCode-like snippets.
--  - Support SnipMate-like snippets.
--  - Support snippets in Lua (own format, most featureful).
--  - Do not support UltiSnip snippets, but they can be easily manually converted to SnipMate.
--
--  Place your own SnipMate-like snippets in ~/.config/nvim/snippets/.

---@module 'lazy'
---@type LazySpec
return {
    {
        'L3MON4D3/LuaSnip',
        version = 'v2.*',
        build = 'make install_jsregexp',
        lazy = true, -- Will be loaded as cmp_luasnip dependency.
        dependencies = {
            'honza/vim-snippets', -- A library with a lof of SnipMate-like snippets.
        },
        config = function(_, opts)
            local luasnip = require 'luasnip'
            luasnip.config.setup(opts)

            require('luasnip.loaders.from_snipmate').lazy_load()

            -- INFO: These mappings are in cmp.lua with extra support for fallback.
            --
            -- vim.keymap.set({ 'i', 's' }, '<C-Right>', function()
            --     if luasnip.expand_or_locally_jumpable() then
            --         luasnip.expand_or_jump()
            --     end
            -- end, { silent = true })
            -- vim.keymap.set({ 'i', 's' }, '<C-Left>', function()
            --     if luasnip.locally_jumpable(-1) then
            --         luasnip.jump(-1)
            --     end
            -- end, { silent = true })
            -- vim.keymap.set({ 'i', 's' }, '<C-CR>', function()
            --     if luasnip.choice_active() then
            --         luasnip.change_choice(1)
            --     end
            -- end, { silent = true })
        end,
    },
}

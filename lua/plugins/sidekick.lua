--[[ Copilot LSP's "Next Edit Suggestions" with a built-in terminal for any AI CLI ]]

-- NOTE:  <Tab>       Sidekick: jump or apply NES.

---@module 'lazy'
---@type LazySpec
return {
    'folke/sidekick.nvim',
    cond = vim.g.allow_remote_llm and vim.g.ide,
    cmd = 'Sidekick',
    event = 'InsertEnter',
    keys = {
        {
            '<Tab>',
            function()
                -- if there is a next edit, jump to it, otherwise apply it if any
                if require('sidekick').nes_jump_or_apply() then
                    return -- jumped or applied
                end
                -- fall back to normal behavior
                return '<Tab>'
            end,
            mode = { 'n' },
            expr = true,
            desc = 'Goto/Apply Next Edit Suggestion',
        },
    },
    opts = {
        nes = {
            diff = {
                inline = false, -- "words"|"chars"|false
            },
        },
        ui = {
            -- stylua: ignore
            icons = {
              nes               = "",
              attached          = "",
              started           = "",
              installed         = "",
              missing           = "",
              external_attached = "󰖩",
              external_started  = "󰖪",
              terminal_attached = "",
              terminal_started  = "",
            },
        },
    },
}

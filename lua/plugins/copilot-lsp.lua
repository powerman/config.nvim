--[[ Integrating GitHub Copilot's AI-powered code suggestions via LSP ]]

---@module 'lazy'
---@type LazySpec
return {
    'copilotlsp-nvim/copilot-lsp',
    cond = vim.g.allow_remote_llm,
    init = function()
        vim.g.copilot_nes_debounce = 500

        vim.lsp.config('copilot_ls', {
            -- Avoid shell files which might contain secrets.
            filetypes = { 'lua', 'go' },
        })
        vim.lsp.enable 'copilot_ls'

        vim.keymap.set({ 'i', 'n' }, '<C-CR>', function()
            -- Try to jump to the start of the suggestion edit.
            -- If already at the start, then apply the pending suggestion and jump to the end of the edit.
            local _ = require('copilot-lsp.nes').walk_cursor_start_edit()
                or (
                    require('copilot-lsp.nes').apply_pending_nes()
                    and require('copilot-lsp.nes').walk_cursor_end_edit()
                )
        end)
        vim.keymap.set('i', '<M-\\>', function()
            if not require('copilot-lsp.nes').clear() then
                if require('copilot.suggestion').is_visible() then
                    require('copilot.suggestion').dismiss()
                else
                    require('copilot.suggestion').toggle_auto_trigger()
                end
            end
        end, { desc = 'Clear Copilot suggestion' })
        vim.keymap.set('n', '<M-\\>', function()
            require('copilot-lsp.nes').clear()
        end, { desc = 'Clear Copilot suggestion' })
    end,
}

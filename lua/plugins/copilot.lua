--[[ Fully featured & enhanced replacement for copilot.vim for interacting with Github Copilot ]]

---@module 'lazy'
---@type LazySpec
return {
    'zbirenbaum/copilot.lua',
    cond = vim.g.allow_remote_llm,
    lazy = false, -- Needs to setup autocommands for LSP before creating buffers.
    opts = {
        panel = {
            enabled = false,
        },
        suggestion = {
            enabled = true,
            auto_trigger = true, -- Disabled while evaluating copilot-lsp.
            keymap = {
                accept = '<M-CR>',
                accept_word = '<M-Right>',
                accept_line = '<M-Down>',
                next = '<M-]>',
                prev = '<M-[>',
                dismiss = '<M-\\>',
            },
        },
        should_attach = function(bufid, bufname)
            -- Default behavior.
            if not vim.bo.buflisted then
                return false
            end
            if vim.bo.buftype ~= '' then
                return false
            end
            -- Protect sensitive files which often contains secrets.
            local filename = vim.fn.fnamemodify(bufname, ':t')
            for _, glob in ipairs(vim.g.llm_secret_files) do
                local regex = vim.fn.glob2regpat(glob)
                if vim.fn.match(filename, regex) ~= -1 then
                    return false
                end
            end
            return true
        end,
    },
}

--[[ Configs for the Nvim LSP client ]]
--
--  LSP stands for Language Server Protocol. It's a protocol that helps editors
--  and language tooling communicate in a standardized fashion.
--
--  In general, you have a "server" which is some tool built to understand a particular
--  language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). These Language Servers
--  (sometimes called LSP servers) are standalone processes that communicate with some
--  "client" - in this case, Neovim!
--
--  LSP may provide Neovim with these features (not every LSP server supports all of them):
--    - Show dianostics (syntax errors, linter issues).
--    - Show documentation for a symbol under cursor.
--    - Show signature documentation for a function's arg under cursor.
--    - Show inlay hints.
--    - Highlight related symbols.
--    - Go to symbol's definition (smarter than supported by Neovim without LSP).
--    - Go to symbol's type definition.
--    - Go to symbol's implementation/interface.
--    - Go to symbol's declaration.
--    - Search for a symbol (in a current file or a whole project).
--    - Provide smart (context-aware) autocompletions.
--    - Provide smart (context-aware) snippets.
--    - Rename identifier (everywhere in a project, not just in current file).
--    - Code actions (can be anything, but usually it's an automated fix for some diagnostic).
--    - Autoformat.
--
--  All of the code for the language server client is located in the core of neovim.
--  Lspconfig is a helper plugin that leverages the language client API in neovim core for an
--  easier to use experience. Lspconfig handles:
--
--    - Launching a language server when a matching filetype is detected.
--    - Detecting the root directory of your project (it may differs for different LSP).
--    - Sending the correct initialization options and settings (these are two separate things
--      in the LSP specification) during launch.
--    - Attaching new buffers you open to the currently active language server.
--
-- INFO: Configure list of enabled LSP in `../tools/lsp.lua`.

-- NOTE:  :LspInfo     LSP: Status for active/configured servers.
-- NOTE:  K            LSP: Hover documentation.
-- NOTE:  KK           LSP: Into hover documentation.
-- NOTE:  <C-k>        LSP: Signature documentation.
-- NOTE:  <C-k><C-k>   LSP: Into signature documentation.
-- NOTE:  <Leader>r    LSP: Rename identifier.
-- NOTE:  <Leader>a    LSP: Code action.
-- NOTE:  gd           LSP: Goto definition.
-- NOTE:  gD           LSP: Goto type definition.
-- NOTE:  gI           LSP: Goto implementation.
-- NOTE:  <Leader>th   LSP: Toggle inlay hints.

local function setup_filetypes_docker_compose_language_service()
    vim.filetype.add {
        filename = {
            ['compose.yaml'] = 'yaml.docker-compose',
            ['compose.yml'] = 'yaml.docker-compose',
            ['docker-compose.yaml'] = 'yaml.docker-compose',
            ['docker-compose.yml'] = 'yaml.docker-compose',
        },
    }
end

local function create_lsp_augroup(name, client_id, bufnr)
    return vim.api.nvim_create_augroup(
        ---@diagnostic disable-next-line: redundant-parameter
        vim.fn.printf('user.lsp.%s.%s.%s', name, client_id, bufnr),
        { clear = true }
    )
end

-- Highlight references of the word under your cursor when your cursor
-- rests there for a little while.
-- When you move your cursor, the highlights will be cleared.
local function highlight_references(client_id, bufnr)
    local hl_group = create_lsp_augroup('highlight', client_id, bufnr)
    local detach_group = create_lsp_augroup('detach', client_id, bufnr)

    vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = bufnr,
        group = hl_group,
        callback = vim.lsp.buf.document_highlight,
    })

    vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        buffer = bufnr,
        group = hl_group,
        callback = vim.lsp.buf.clear_references,
    })

    vim.api.nvim_create_autocmd('LspDetach', {
        buffer = bufnr,
        group = detach_group,
        callback = function(ev)
            if client_id ~= ev.data.client_id then
                return
            end
            vim.lsp.buf.clear_references()
            vim.api.nvim_clear_autocmds { buffer = ev.buf, group = hl_group }
        end,
    })
end

-- This function gets run when an LSP attaches to a particular buffer.
-- That is to say, every time a new file is opened that is associated with
-- an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
-- function will be executed to configure the current buffer.
local function handle_LspAttach(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client then
        return
    end

    -- Here you can hide (disable) some server capabilities from a client.
    -- All server capabilities: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#serverCapabilities
    --
    --  if client.name == 'some' then client.server_capabilities.XXX = nil end

    local builtin = require 'telescope.builtin'
    local map = function(keys, func, desc, mode)
        mode = mode or 'n'
        vim.keymap.set(mode, keys, func, { buffer = ev.buf, desc = 'LSP: ' .. desc })
    end

    -- Opens a popup that displays documentation about the word under your cursor.
    map('K', function()
        vim.lsp.buf.hover {
            border = vim.g.float_border,
            max_width = math.floor(vim.fn.winwidth(0) * vim.g.float_max_width),
        }
    end, 'Hover documentation')

    -- Opens a popup that displays signature for the function's param under your cursor.
    map('<C-K>', function()
        vim.lsp.buf.signature_help {
            border = vim.g.float_border,
            max_width = math.floor(vim.fn.winwidth(0) * vim.g.float_max_width),
        }
    end, 'Signature documentation', { 'n', 'i' })

    -- Rename the identifier under your cursor.
    -- Most Language Servers support renaming across files, etc.
    map('<Leader>r', vim.lsp.buf.rename, 'Rename')

    -- Execute a code action, usually your cursor needs to be on top of an error
    -- or a suggestion from your LSP for this to activate.
    map('<Leader>a', vim.lsp.buf.code_action, 'Code action', { 'n', 'v' })

    -- Jump to the definition of the word under your cursor.
    -- This is where a variable was first declared, or where a function is
    -- defined, etc.
    map('gd', builtin.lsp_definitions, 'Goto definition')

    -- Jump to the type of the word under your cursor.
    -- Useful when you're not sure what type a variable is and you want to see
    -- the definition of its *type*, not where it was *defined*.
    map('gD', builtin.lsp_type_definitions, 'Goto type definition')

    -- Jump to the implementation of the word under your cursor.
    -- Useful when your language has ways of declaring types without an actual
    -- implementation (e.g. "interfaces").
    map('gI', builtin.lsp_implementations, 'Goto implementation')

    -- Find references for the word under your cursor.
    map('<Leader>gr', builtin.lsp_references, 'Goto references')

    -- Jump to the declaration of the word under your cursor.
    -- For example, in C this would take you to the header.
    map('<Leader>gd', vim.lsp.buf.declaration, 'Goto declaration')

    -- Fuzzy find all the symbols in your current document.
    -- Symbols are things like variables, functions, types, etc.
    map('<Leader>ds', builtin.lsp_document_symbols, 'Document symbols')

    -- Fuzzy find all the symbols in your current workspace.
    -- Similar to document symbols, except searches over your entire project.
    map('<Leader>ws', builtin.lsp_dynamic_workspace_symbols, 'Workspace symbols')

    -- Toggle inlay hints in your code, if the server supports them.
    -- This may be unwanted, since they displace some of your code.
    if client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
        map('<Leader>th', function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled {})
        end, 'Toggle inlay hints')
    end

    vim.api.nvim_create_autocmd('CursorHold', {
        buffer = ev.buf,
        group = create_lsp_augroup('auto_float', client.id, ev.buf),
        callback = function()
            if not vim.g.auto_open_diagnostic then
                return
            end
            vim.diagnostic.open_float {
                focusable = false,
                -- Append InsertEnter to defaults.
                close_events = { 'CursorMoved', 'CursorMovedI', 'InsertCharPre', 'InsertEnter' },
            }
        end,
    })

    if client.server_capabilities.documentHighlightProvider then
        highlight_references(client.id, ev.buf)
    end
end

---@module 'lazy'
---@type LazySpec
return {
    {
        'neovim/nvim-lspconfig',
        version = '*',
        lazy = false, -- Needs to setup autocommands for LSP before creating buffers.
        dependencies = {
            -- Setup $PATH for current project before running LSP servers.
            'project',
            -- Provides 'cmp' capabilities for LSP clients.
            'hrsh7th/cmp-nvim-lsp',
            -- Use telescope builtin handlers instead of Neovim builtins to open lists of
            -- locations provided by LSP in telescope UI instead of quickfix window.
            'nvim-telescope/telescope.nvim',
        },
        init = function()
            setup_filetypes_docker_compose_language_service()
        end,
        config = function()
            vim.api.nvim_create_autocmd('LspAttach', {
                group = vim.api.nvim_create_augroup('user.lsp.attach', { clear = true }),
                callback = handle_LspAttach,
            })

            -- LSP servers and clients are able to communicate to each other what features they support.
            -- By default, Neovim doesn't support everything that is in the LSP specification.
            -- When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
            -- So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
            vim.lsp.config('*', {
                capabilities = require('cmp_nvim_lsp').default_capabilities(),
            })

            for server_name, server in pairs(require 'tools.lsp') do
                vim.lsp.enable(server_name)
                vim.lsp.config(server_name, server)
            end
        end,
    },
}

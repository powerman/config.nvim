-- [[ Configs for the Nvim LSP client ]]
--
--  LSP stands for Language Server Protocol. It's a protocol that helps editors
--  and language tooling communicate in a standardized fashion.
--
--  In general, you have a "server" which is some tool built to understand a particular
--  language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). These Language Servers
--  (sometimes called LSP servers, but that's kind of like ATM Machine) are standalone
--  processes that communicate with some "client" - in this case, Neovim!
--
--  LSP provides Neovim with features like:
--    - Go to definition
--    - Find references
--    - Autocompletion
--    - Symbol Search
--    - and more!
--
--  All of the code for the language server client is located in the core of neovim.
--  Lspconfig is a helper plugin that leverages the language client API in neovim core for an
--  easier to use experience. Lspconfig handles:
--
--    - Launching a language server when a matching filetype is detected.
--    - Detecting the root directory of your project.
--    - Sending the correct initialization options and settings (these are two separate things
--      in the LSP specification) during launch.
--    - Attaching new buffers you open to the currently active language server.

-- NOTE:  :LspInfo     LSP: Status for active/configured servers.
-- NOTE:  K            LSP: Hover documentation.
-- NOTE:  KK           LSP: Into hover documentation.
-- NOTE:  <Leader>r    LSP: Rename identifier.
-- NOTE:  <Leader>ca   LSP: Code action.
-- NOTE:  gd           LSP: Goto definition.
-- NOTE:  gD           LSP: Goto type definition.
-- NOTE:  gI           LSP: Goto implementation.
-- NOTE:  <Leader>ts   LSP: Toggle inlay hints.

local function setup_filetypes_termux_ls()
    vim.filetype.add {
        extension = {
            -- ArchLinux/Windows Msys2
            install = 'sh.install',
            -- Gentoo
            ebuild = 'sh.ebuild',
            eclass = 'sh.eclass',
            -- Zsh
            mdd = 'sh.mdd',
        },
        filename = {
            -- Android Termux
            ['build.sh'] = 'sh.build',
            -- ArchLinux/Windows Msys2
            ['PKGBUILD'] = 'sh.PKGBUILD',
            ['makepkg.conf'] = 'sh.makepkg.conf',
        },
        pattern = {
            -- Android Termux
            ['.*%.subpackage%.sh'] = 'sh.subpackage',
            -- Gentoo
            ['.*/etc/make%.conf'] = 'sh.make.conf',
            ['.*/etc/portage/make%.conf'] = 'sh.make.conf',
            ['.*/etc/portage/color%.map'] = 'sh.color.map',
        },
    }
end

-- HACK: Monkey-patch because lspconfig don't know about termux language server yet.
-- https://github.com/termux/termux-language-server/issues/21
local function register_termux_ls()
    local configs = require 'lspconfig.configs'
    if not configs['termux_ls'] then
        configs['termux_ls'] = require 'lspconfig/server_configurations/termux_ls'
    end
end

-- LSP servers and clients are able to communicate to each other what features they support.
-- By default, Neovim doesn't support everything that is in the LSP specification.
-- When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
-- So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
--
-- All client capabilities: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#clientCapabilities
local function make_client_capabilities()
    local override = {} -- You can override any of `cmp` capabilities.
    return vim.tbl_deep_extend(
        'force',
        -- Take Neovim's capabilities...
        vim.lsp.protocol.make_client_capabilities(),
        -- ...and extend it with `cmp` plugin's completion capabilities.
        require('cmp_nvim_lsp').default_capabilities(override)
    )
end

-- Highlight references of the word under your cursor when your cursor
-- rests there for a little while.
-- When you move your cursor, the highlights will be cleared.
local function highlight_references(client_id, bufnr)
    local create_lsp_augroup = function(name)
        return vim.api.nvim_create_augroup(
            ---@diagnostic disable-next-line: redundant-parameter
            vim.fn.printf('user.lsp.%s.%s.%s', name, client_id, bufnr),
            { clear = true }
        )
    end
    local hl_group = create_lsp_augroup 'highlight'
    local detach_group = create_lsp_augroup 'detach'

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

    -- HACK: https://github.com/termux/termux-language-server/issues/19#issuecomment-2200349890
    if client.name == 'termux_ls' then
        client.server_capabilities.documentFormattingProvider = nil
    end

    local builtin = require 'telescope.builtin'
    local map = function(keys, func, desc)
        vim.keymap.set('n', keys, func, { buffer = ev.buf, desc = 'LSP: ' .. desc })
    end

    -- Opens a popup that displays documentation about the word under your cursor
    -- See `:help K` for why this keymap.
    map('K', vim.lsp.buf.hover, 'Hover Documentation')

    -- Rename the identifier under your cursor.
    -- Most Language Servers support renaming across files, etc.
    map('<Leader>r', vim.lsp.buf.rename, '[R]ename')

    -- Execute a code action, usually your cursor needs to be on top of an error
    -- or a suggestion from your LSP for this to activate.
    map('<Leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')

    -- Jump to the definition of the word under your cursor.
    -- This is where a variable was first declared, or where a function is
    -- defined, etc.
    map('gd', builtin.lsp_definitions, '[G]oto [D]efinition')

    -- Jump to the type of the word under your cursor.
    -- Useful when you're not sure what type a variable is and you want to see
    -- the definition of its *type*, not where it was *defined*.
    map('gD', builtin.lsp_type_definitions, '[G]oto Type [D]efinition')

    -- Jump to the implementation of the word under your cursor.
    -- Useful when your language has ways of declaring types without an actual
    -- implementation (e.g. "interfaces").
    map('gI', builtin.lsp_implementations, '[G]oto [I]mplementation')

    -- Find references for the word under your cursor.
    map('gr', builtin.lsp_references, '[G]oto [R]eferences')

    -- Jump to the declaration of the word under your cursor.
    -- For example, in C this would take you to the header.
    map('<Leader>D', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

    -- Fuzzy find all the symbols in your current document.
    -- Symbols are things like variables, functions, types, etc.
    map('<Leader>ds', builtin.lsp_document_symbols, '[D]ocument [S]ymbols')

    -- Fuzzy find all the symbols in your current workspace.
    -- Similar to document symbols, except searches over your entire project.
    map('<Leader>ws', builtin.lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

    -- Enable inlay hints in your code, if the server supports them.
    -- This may be unwanted, since they displace some of your code.
    if client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
        vim.lsp.inlay_hint.enable(true)
        map('<Leader>th', function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled {})
        end, '[T]oggle Inlay [H]ints')
    end

    if client.server_capabilities.documentHighlightProvider then
        highlight_references(client.id, ev.buf)
    end
end

---@module 'lazy'
---@type LazySpec
return {
    {
        'neovim/nvim-lspconfig',
        dependencies = {
            -- Provides 'cmp' capabilities for LSP clients.
            'hrsh7th/cmp-nvim-lsp',
            -- Use telescope builtin handlers instead of Neovim builtins to open lists of
            -- locations provided by LSP in telescope UI instead of quickfix window.
            'nvim-telescope/telescope.nvim',
        },
        lazy = false, -- Needs to setup autocommands for LSP before creating buffers.
        init = function()
            setup_filetypes_termux_ls()
            vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, {
                border = 'rounded',
                max_width = 96,
            })
        end,
        config = function()
            register_termux_ls()

            vim.api.nvim_create_autocmd('LspAttach', {
                group = vim.api.nvim_create_augroup('user.lsp.attach', { clear = true }),
                callback = handle_LspAttach,
            })

            local client_capabilities = make_client_capabilities()
            for server_name, server in pairs(require 'tools.lsp') do
                server.capabilities =
                    vim.tbl_deep_extend('force', client_capabilities, server.capabilities or {})
                require('lspconfig')[server_name].setup(server)
            end
        end,
    },
}

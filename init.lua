--[[ Configuration ]]
--
--  INFO: Use <Leader>sc to search cheatsheet with most useful features of this configuration.
--
--  See https://learnxinyminutes.com/docs/lua/.
--  See `:help lua-guide`.

-- NOTE:  nvim --cmd 'let debug_lsp=1'   LSP: Enable debugging.

-- Use <Space> as both <Leader> and <LocalLeader> keys.
-- See `:help mapleader`.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Set to false if you prefer to manually open diagnostic with <Leader>e.
-- See also `vim.diagnostic.config { virtual_lines }` in `setup.lua` as an alternative.
vim.g.auto_open_diagnostic = false

-- Set to true if you have a Nerd Font installed and selected in the terminal.
vim.g.have_nerd_font = true

-- Set to true if you use a Nerd Font with "Propo" suffix in font name (wide icons).
vim.g.nerd_font_propo = true

-- Max size for floating windows.
-- Must be <=1.
vim.g.float_max_height = 0.96
vim.g.float_max_width = 0.96

-- Set to true if you want transparent background.
-- Auto-detected for urxvt terminal, false in other terminals.
vim.g.transparent = string.find(vim.env.TERM or '', '^rxvt') ~= nil
    and string.find(vim.env.COLORFGBG or '', '%d$') == nil

-- You can start Neovim this way to enable it: `nvim --cmd 'let debug_lsp=1'`.
vim.g.debug_lsp = vim.g.debug_lsp or false

-- Used to setup PATH and some plugins. Configure your markers for vim.fs.root as needed.
vim.g.project_root = vim.fs.root(0, '.git') or vim.fn.getcwd()

-- Change working directory to project root.
-- This is needed for some plugins that use the current working directory - e.g. MCP servers.
vim.cmd('cd ' .. vim.g.project_root)

-- Setup project-specific PATH.
local project_bin_dirs = { '.buildcache/bin' }
vim.env.PATH = require('custom.util').project_path(project_bin_dirs) .. vim.env.PATH

-- Set to true if you agree to send your files to 3rd-party companies.
vim.g.allow_remote_llm = vim.fn.filereadable '/proc/1/comm' == 1
    and vim.fn.readfile('/proc/1/comm')[1] == 'firejail'

-- List of files (in glob format) that should not be sent to LLM.
vim.g.llm_secret_files = {
    '.env*',
    'env*.sh',
    '.secret.sh',
}

-- List of shell commands allowed to LLM without manual approve.
vim.g.llm_allowed_cmds = {
    -- Common development commands.
    './scripts/test',
    'actionlint',
    'go build *',
    'go clean *',
    'go doc *',
    'go env -changed',
    'go env GOROOT',
    'go env', -- WARN: Unwanted if used with -w.
    'go fmt *',
    'go get *',
    'go run *',
    'go test *',
    'golangci-lint run --fix',
    'golangci-lint run',
    'make lint',
    'make test',
    'mise doctor',
    -- 'mise exec *', XXX: Dangerous, allows any command.
    -- 'mise x *', XXX: Dangerous, allows any command.
    'mise lint',
    'mise run *',
    'mise tasks',
    'mise test',
    'npm test *',
    'npx jest *',
    'nvim *', -- WARN: Dangerous if use Lua or plugins to run shell commands.
    'stylua .',
    'vusted *',
    'xmllint *',
    -- General commands.
    'cut *',
    'false',
    'ps *',
    'sort -u',
    'sort', -- WARN: Dangerous if used with --compress-program.
    -- 'timeout *', XXX: Dangerous, allows any command.
    'true',
    'wc *',
    'which *',
    -- Search files.
    'diff *',
    'find *', -- WARN: Dangerous if used with -exec.
    'grep *',
    'ls *',
    'tree *',
    -- File management.
    'cp *',
    'mkdir *',
    'mv *',
    'rm -* .cache/*',
    'rmdir *',
    'touch *',
    'unzip *',
    -- File editing (usually with redirects).
    'awk *', -- WARN: Dangerous if used with system().
    'cat *',
    'echo *',
    'head *',
    'sed *',
    'tail *',
    'xargs cat',
    -- Git commands.
    'git checkout -- *',
    'git checkout HEAD -- *',
    'git diff *',
    'git grep *',
    'git log *',
    'git reset --hard HEAD',
    'git restore *',
    'git show *',
    'git stash *',
    'git status --porcelain',
    'git status',
    --- Docker commands.
    -- 'docker build *',
    -- 'docker compose *',
    -- 'docker run *',
}

-- Sound file to play on LLM response.
vim.g.llm_message_sound = '/usr/share/sounds/freedesktop/stereo/message.oga'

-- Setup Nerd Fonts.
require 'nerd-fonts'

-- Setting options.
require 'options'

-- Setting basic keymaps (working without plugins).
require 'keymaps'

-- Setting basic autocommands (working without plugins).
require 'autocmd'

-- Rest of basic setup (working without plugins).
require 'setup'

-- Install `lazy.nvim` plugin manager.
require 'lazy-bootstrap'

-- Install and configure all plugins.
require 'lazy-plugins'

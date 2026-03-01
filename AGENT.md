# General rules for the project

## Project Context (Reference)

Project "config.nvim" - personal Neovim configuration for daily coding work
(few users, different Linux distributions).

- Minimum Neovim version: 0.11.
- Lua dialect: LuaJIT 2.1 (Lua 5.1). Use `vim.*` APIs, not `io.*` or `os.*`.
- Plugin manager: Lazy.nvim (specs in `lua/plugins/*.lua`).

Priorities, in order:

1. **Security** – Default to safe behavior, especially when interacting with AI agents.
2. **Simplicity** – Add config options to `init.lua` only if trivial to implement.
3. **Fast startup** – Lazy-load all non-critical resources; avoid blocking init operations.
4. **Discoverability** – Assign `desc` to all keymaps; organize `which-key` groups; add NOTE comments.
5. **Minimal footprint** – Prefer Neovim built-ins and Lua APIs over external plugins.

### Structure

Standard Neovim config structure plus:

- `.cache/` — Git-ignored directory for temporary files.
- `mise.toml`, `mise.lock` — Project tasks and tools managed by Mise.
- `init.lua`, `lua/*.lua`, `lua/plugins/*.lua` — Main configuration files.
- `lua/custom/` — Custom Lua modules and helpers for the Lazy plugin setup.
- `lua/tools/` — Configuration data for LSP servers and formatters.
- `lua/patch/` — Lua monkey-patches for other plugins.
- `patches/` — Diff patches automatically applied to plugins installed via Lazy.
- `run_plenary.vim`, `tests/` — Testing with Plenary.
- `sgconfig.yml`, `.sg/` — Custom ast-grep linting rules.
- `codecompanion/` — Additional configuration for the CodeCompanion plugin.

### Tasks

Use these commands for corresponding tasks:

- `mise run lint` — run all linters.
- `mise run fmt` — fix formatting issues reported by linters.
- `mise run test` — run all tests.

---

## Mandatory Rules

### Repository Safety

- DO NOT create, amend, squash, rebase, or otherwise modify commits.
- DO NOT switch branches.
- DO NOT perform any network git operations inside this repository
  (e.g. `git push`, `git pull`, `git fetch`).
- You MAY use `git stash` if necessary, but clean up after yourself.
- You MAY use `git restore` for reverting local changes.
- Do not delete, rewrite, or mass-modify files outside the explicit scope of the task.
- Avoid destructive shell commands (e.g. `rm -rf`, recursive operations)
  unless explicitly required.
- DO NOT edit `lazy-lock.json` manually.
  Plugin versions are managed via `:Lazy update` and `:Lazy restore`.

### Coding Standards

#### Semantic Linefeeds (comments and documentation only)

Start each sentence on a new line.
Break long sentences at natural pauses —
after commas, semicolons, conjunctions,
or between logical clauses.
Do NOT hard-wrap to a fixed column width.
The goal is meaningful diffs:
one changed idea = one changed line.

```lua
--- Checks if a buffer is valid and listed.
--- Returns false for scratch buffers,
--- because they should not appear in the buffer list.
---
--- If the buffer has been modified,
--- the caller must decide whether to save or discard changes
--- before removing it from the list.
```

#### Documentation (markdown)

- Write new documentation in English.
- Avoid adding new documentation unless specifically requested by user.
- Update existing documentation together with code changes
  ONLY if otherwise existing documentation became incorrect.
- Keep lines within 96 characters.

#### Commenting

- Write new comments in English.
- Do not add redundant comments that restate obvious code behavior.
- Explain rationale, intent, trade-offs, and non-obvious behavior.
- Use full sentences in comments and documentation.
- Keep lines within 96 characters.

#### Formatting and Style

- Lua style is defined in `.stylua.toml`.
- Always run `mise run fmt` to fix formatting.
- Lua comments:
  - `--` for inline comments.
  - `---` for docstrings.

#### Naming

- Lua modules must use lowercase with underscores (`module_name.lua`).

#### Plugin Spec Style

- One plugin per file in `lua/plugins/`, named after the plugin.
  - Exception: plugins which are extensions for other plugin may be in main plugin's file.
- Use `opts` table over `config` function when possible.
- Prefer `event`, `ft`, `cmd`, or `keys` for lazy-loading.
- Pin plugin versions with `commit` or `tag` only when there is a known breakage.

---

## Recommended Practices

### Testing

- Custom Lua modules in `lua/custom/`
  should have corresponding tests in `tests/custom/`.
- Lua monkey-patches in `lua/patch/NAME/`
  should have corresponding tests in `tests/NAME/`.

### Tool / Shell Discipline

- Store temporary scripts in `.cache/`
  unless the language requires another location.
- Remove temporary scripts after use,
  unless the user is expected to run them manually.
- Avoid creating persistent artifacts unless required by the task.
- Prefer existing project tooling (`mise`, linters, test runner)
  over ad-hoc commands.

### Do Not

- Do not add `vim.cmd` calls where a Lua API exists.
- Do not use `vim.fn` for things available in `vim.api` or `vim.*.`
- Do not add autocommands outside of `augroup` (use `vim.api.nvim_create_augroup`).

## Common Gotchas

- Always add a comment `-- NOTE: {type-icon} {keys/command}  {description}`
  at file header for each added/modified usable feature (keymapping, command, textobject).
  This is for discoverability by searching for all NOTE "todo comments",
  implemented in telescope plugin config and mapped on `<Leader>sc`.
- `vim.keymap.set` — always provide `desc` in opts for which-key discoverability.
- Lazy plugin specs use `opts` (table/function) instead of `config`
  when the plugin supports `setup(opts)`.

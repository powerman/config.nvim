---@type LazySpec
return {
    {
        'nvim-lua/plenary.nvim', -- Not a plugin, just a useful library.
        config = function()
            local Path = require 'plenary.path'

            --- TODO: Add tests.
            local normalize = Path.normalize
            --- Monkey-patch Path:normalize method to make it try harder looking for shortest
            --- relative path by checking also path UP from cwd: '../../…'.
            ---@diagnostic disable-next-line: duplicate-set-field
            Path.normalize = function(self, cwd)
                -- Absolute (DOWN FROM / or ~) or relative (DOWN FROM cwd).
                local orig = normalize(self, cwd)
                -- Absolute (DOWN FROM / or ~), but we'll make it relative (UP FROM cwd).
                local rel = vim.fn.fnamemodify(orig, ':p:~')

                if string.match(orig, '^[/~]') then -- Absolute, thus may be shorter.
                    local abs = vim.fn.fnamemodify(rel, ':p')
                    local abs_path = Path:new(abs)
                    local dir = cwd .. '/'
                    local up = ''
                    repeat
                        up = up .. '../'
                        rel = abs_path:make_relative(Path:new(dir .. up):absolute())
                    until rel ~= abs
                    rel = up .. rel
                end

                return string.len(orig) <= string.len(rel) and orig or rel
            end
        end,
    },
}

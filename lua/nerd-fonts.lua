--[[ Nerd Fonts ]]
--
--  See https://www.nerdfonts.com/.

-- Fix icon width for Nerd Fonts v3 (non-Mono variant).
if not vim.g.mono_nerd_font then
    -- Nerd Fonts v3.
    vim.fn.setcellwidths {
        { 0x23fb, 0x23fe, 2 },
        { 0x2665, 0x2665, 2 },
        { 0x2b58, 0x2b58, 2 },
        { 0xe000, 0xe09f, 2 },
        { 0xe0c0, 0xf8ff, 2 },
        { 0xf0001, 0xfffff, 2 },
    }
end

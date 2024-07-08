-- [[ Nerd Fonts ]]
--
--  See https://www.nerdfonts.com/.

-- Fix icon width for Nerd Fonts (non-Mono variant).
if not vim.g.mono_nerd_font then
    -- Nerd Fonts v3.2.1.
    vim.fn.setcellwidths {
        { 0x23fb, 0x23fe, 2 }, -- IEC Power Symbols
        { 0x2665, 0x2665, 2 }, -- Octicons
        { 0x2b58, 0x2b58, 2 }, -- IEC Power Symbols
        { 0xe000, 0xe00a, 2 }, -- Pomicons
        { 0xe0b8, 0xe0c8, 2 }, -- Powerline Extra
        { 0xe0ca, 0xe0ca, 2 }, -- Powerline Extra
        { 0xe0cc, 0xe0d7, 2 }, -- Powerline Extra
        { 0xe200, 0xe2a9, 2 }, -- Font Awesome Extension
        { 0xe300, 0xe3e3, 2 }, -- Weather Icons
        { 0xe5fa, 0xe6b5, 2 }, -- Seti-UI + Custom
        { 0xe700, 0xe7c5, 2 }, -- Devicons
        { 0xea60, 0xec1e, 2 }, -- Codicons
        { 0xed00, 0xefce, 2 }, -- Font Awesome
        { 0xf000, 0xf2ff, 2 }, -- Font Awesome
        { 0xf300, 0xf375, 2 }, -- Font Logos
        { 0xf400, 0xf533, 2 }, -- Octicons
        { 0xf0001, 0xf1af0, 2 }, -- Material Design
    }
end

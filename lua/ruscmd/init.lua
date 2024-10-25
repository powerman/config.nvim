local M = {}

---@class RusCmdConfig
---@field cabbrev? table<string,string>

-- Setup mapping from Russian to English keys for Normal and Command modes.
---@param cfg RusCmdConfig
M.setup = function(cfg)
    local cabbrev = {
        ['ив'] = 'bd',
        ['ит'] = 'bn',
        ['й'] = 'q',
        ['йф'] = 'qa',
        ['ц'] = 'w',
        ['цй'] = 'wq',
        ['цйф'] = 'wqa',
    }
    for lhs, rhs in pairs(cfg.cabbrev or {}) do
        cabbrev[lhs] = rhs
    end

    -- Avoid switching between Russian/English keyboards when you need to enter Normal mode command.
    vim.opt.langmap = 'ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯ;ABCDEFGHIJKLMNOPQRSTUVWXYZ'
        .. ',фисвуапршолдьтщзйкыегмцчня;abcdefghijklmnopqrstuvwxyz'
        .. ',ё`,Ё~,х[,Х{,ъ],Ъ},ж\\;,Ж:,э\',Э",б\\,,Б<,ю.,Ю>'

    -- Avoid switching between Russian/English keyboards for frequently used Command mode commands.
    for lhs, rhs in pairs(cabbrev) do
        local tmpl = "cabbrev <expr> %s getcmdtype()==':' && getcmdline()=='%s' ? '%s' : '%s'"
        vim.cmd(string.format(tmpl, lhs, lhs, rhs, lhs))
    end
end

return M

--- Response translation rules.
--- Ported from responseTranslationRules.tsx.

local M = {}

local validLocales = {
    'auto',
    'en',
    'fr',
    'it',
    'de',
    'es',
    'ru',
    'zh-CN',
    'zh-TW',
    'ja',
    'ko',
    'cs',
    'pt-br',
    'tr',
    'pl',
}

--- Render locale instruction if applicable.
---@param opts Copilot.Options
---@return string
function M.render(opts)
    local locale = opts.locale
    if not locale then
        return ''
    end

    local valid = false
    for _, v in ipairs(validLocales) do
        if locale == v then
            valid = true
            break
        end
    end
    if not valid then
        return ''
    end

    -- "auto" would require OS locale detection; treat as the literal value.
    if locale == 'en' then
        return ''
    end

    return 'Respond in the following locale: ' .. locale .. '.\n'
end

return M

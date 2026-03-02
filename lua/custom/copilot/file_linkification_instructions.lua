--- File linkification instructions.
--- Ported from fileLinkificationInstructions.tsx.

local M = {}

local tag = require('custom.copilot.base.tag').wrap

---@return string
function M.render()
    return tag(
        'fileLinkification',
        table.concat({
            'When mentioning files or line numbers, use workspace-relative paths and 1-based line numbers.',
            '',
            'BACKTICKS ARE ALLOWED AND RECOMMENDED:',
            '- Wrap file paths and file:line references in backticks.',
            '- Use inline-code formatting for all file references.',
            '',
            'REQUIRED FORMATS (Neovim-compatible):',
            '- File only: `path/to/file.ts`',
            '- Line: `path/to/file.ts:10`',
            '',
            'DO NOT USE:',
            '- Markdown links.',
            '- Line ranges like :10-12.',
            '- URI schemes such as file://',
            '- Fragment syntax like #L10.',
            '',
            'PATH RULES:',
            '- Always use workspace-relative paths.',
            "- Use '/' as separator.",
            '- Use 1-based line numbers.',
            '- Reference only existing files.',
            '- If multiple lines must be referenced, list them separately:',
            '  `file.ts:10`',
            '  `file.ts:20`',
            '',
            'USAGE EXAMPLES:',
            '- The handler is in `src/handler.ts:10`.',
            '- See `src/config.ts` for settings.',
            '- Initialization happens in `src/widget.ts:321`.',
            '',
            'FORBIDDEN (NEVER OUTPUT):',
            '- Markdown-style links: [file.ts](file.ts#L10)',
            '- Ranges: `file.ts:10-12`',
            '- Fragment syntax: `file.ts#L10`',
            '- URI forms: `file:///path/to/file.ts`',
            '- Non-linked plain references when a precise location is given (always use backticks).',
        }, '\n')
    )
end

return M

local M = {
    USER_ROLE = 'user',
    SYSTEM_ROLE = 'system',
    chat = {},
    inline = {},
}

M.get_text = function(context)
    local buf = vim.api.nvim_get_current_buf()
    local lines =
        vim.api.nvim_buf_get_lines(buf, context.start_line - 1, context.end_line, false)
    if #lines == 0 then
        return ''
    end

    if context.start_line == context.end_line then
        return string.sub(lines[1], context.start_col, context.end_col)
    end

    lines[1] = string.sub(lines[1], context.start_col)
    lines[#lines] = string.sub(lines[#lines], 1, context.end_col)
    return table.concat(lines, '\n')
end

M.send_code = function(context)
    local actions = require 'codecompanion.helpers.actions'
    local text = actions.get_code(context.start_line, context.end_line)

    return 'I have the following code:\n\n```'
        .. context.filetype
        .. '\n'
        .. text
        .. '\n```\n\n'
end

M.chat.std = {
    n = { { role = M.USER_ROLE, content = '' } },
    i = { { role = M.USER_ROLE, content = '' } },
    v = { -- Same as in default "Chat" menu item.
        {
            role = M.SYSTEM_ROLE,
            content = function(context)
                return 'I want you to act as a senior '
                    .. context.filetype
                    .. ' developer. I will give you specific code examples and ask you questions. I want you to advise me with explanations and code examples.'
            end,
        },
        {
            role = M.USER_ROLE,
            content = function(context)
                return M.send_code(context)
            end,
            opts = {
                contains_code = true,
            },
        },
    },
}

M.inline.selected_text = function(context)
    return '<selected_text>\n'
        .. M.get_text(context)
        .. '</selected_text>\n'
        .. '<filetype>\n'
        .. context.filetype
        .. '\n'
        .. '</filetype>\n'
end

-- Designed for weak (8B) local Ollama models.
M.inline.improve_grammar = [[
<prompt>
Your task is to take the text I have selected in the buffer
and rewrite it into a clear, grammatically correct version
while preserving the original language, meaning and tone as closely as possible.
Correct any spelling mistakes, punctuation errors, verb tense issues, word choice problems,
and other grammatical mistakes.

The selected text is a part of code documentation — either code comments or Markdown file.

If the selected text contains both code and comments, do not change the code.
Include code in your response as-is and make your changes only within comments.

If the selected text is in Markdown format:
- Do NOT add, change or delete the Markdown structure (headers, lists, tables, blockquotes).
- Do NOT change inline code blocks (e.g. `code`).
- You may improve inline formatting (e.g. bold/italic) only if relevant to your corrections.

**IMPORTANT CONSTRAINTS**:
- You must preserve the original formatting, indentation, line breaks, block/line comment markers.
- You must try hard to avoid too long (above 100 characters) lines:
  use more concise sentences or break them into multiple lines.
- You must return only a raw JSON object, strictly following this schema:

    {
      "code": "<corrected_text_here>",
      "language": "<filetype_here>"
    }

- Do NOT include triple backticks or any Markdown formatting unless it is a part of selected text.
- Do NOT include any explanations, justifications, or reasoning.
- If the selected text is already correct, return it **unchanged** in the "code" field.

Violation of these constraints will be treated as incorrect output.
</prompt>
/no_think
]]

-- Designed for weak (8B) local Ollama models.
M.chat.translate = [[
You are a highly skilled translator with expertise in many languages.
Your task is to identify the language of the text I provide and accurately translate it into
the specified target language while preserving the meaning, tone, and nuance of the original text.
Please maintain proper grammar, spelling, and punctuation in the translated version.

If text language is English, then translate it into Russian, otherwise translate it into English.

The text I provide may contain code snippets, Markdown formatting, or other special elements -
do not translate them but preserve them as-is in the translated text.

Respond with the translated text only, without any additional explanations or comments.
]]

return M

---
name: Improve grammar
interaction: inline
description: Improve grammar in the selected text
opts:
  adapter:
    name: ollama
    model: ministral-3:8b
  alias: grammar
  modes:
    - v
  placement: replace
  stop_context_insertion: true
  user_prompt: false
---

## system

Your task is to take the text I have selected in the buffer and rewrite it into a clear,
grammatically correct version while preserving the original language, meaning and tone as
closely as possible.
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
- You must try hard to avoid too long (above 100 characters) lines: use more concise sentences
  or break them into multiple lines.
- You must return only a raw JSON object, strictly following this schema:

      {
        "code": "<corrected_text_here>",
        "language": "<filetype_here>"
      }

- Do NOT include triple backticks or any Markdown formatting unless it is a part of selected text.
- Do NOT include any explanations, justifications, or reasoning.
- If the selected text is already correct, return it **unchanged** in the "code" field.

Violation of these constraints will be treated as incorrect output.

## user

`````${context.filetype}
${context.code}
`````

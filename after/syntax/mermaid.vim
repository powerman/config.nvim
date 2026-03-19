" Add YAML frontmatter support to Mermaid syntax.
" Mermaid v10+ supports ---\n...\n--- frontmatter, but the built-in syntax
" file does not handle it.

unlet b:current_syntax
syntax include @mermaidYaml syntax/yaml.vim
let b:current_syntax = 'mermaid'

syntax region mermaidFrontmatter
    \ start='\%^---$'
    \ end='^---$'
    \ contains=@mermaidYaml
    \ keepend

" Mermaid renders `...` node labels as Markdown.
unlet b:current_syntax
syntax include @mermaidMarkdown syntax/markdown.vim
let b:current_syntax = 'mermaid'

syntax region mermaidMarkdownString matchgroup=String start=/"`/ end=/`"/ contains=@mermaidMarkdown
highlight link mermaidMarkdownString String

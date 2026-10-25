; extends

; Inject inner language into text of Jinja templates.
; The b:jinja_lang variable is set in after/ftplugin/jinja.lua,
; and used by the set-jinja-lang! custom directive (treesitter.lua).
; Raw block body is not processed by Jinja, so it is also a text of the inner language.
([
  (content)
  (raw_body)
] @injection.content
  (#set-jinja-lang!)
  (#set! injection.combined))

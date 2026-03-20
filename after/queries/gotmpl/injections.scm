; extends

; Inject inner language into text nodes of Go template files.
; The b:gotmpl_lang variable is set in after/ftplugin/gotmpl.lua,
; and checked by the gotmpl-lang? custom predicate (treesitter.lua).

((text) @injection.content
  (#gotmpl-lang? "caddy")
  (#set! injection.language "caddy")
  (#set! injection.combined))

((text) @injection.content
  (#gotmpl-lang? "ini")
  (#set! injection.language "ini")
  (#set! injection.combined))

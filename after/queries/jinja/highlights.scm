; extends

; Background of whole Jinja tags, to make them stand out from inner language.
(source
  [
    (render_expression)
    (control)
    (comment)
  ] @jinja.tag)

(raw_block
  [
    (raw_start)
    (raw_end)
  ] @jinja.tag)

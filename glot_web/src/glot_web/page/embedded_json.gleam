import gleam/json
import gleam/string
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

/// Render JSON as a non-executable HTML script data block.
///
/// Script elements are raw-text elements, so their contents must not contain an
/// HTML tag opener. Escaping all HTML-significant characters also keeps this
/// boundary safe if the JSON contains user-authored source code or metadata.
pub fn script(id id: String, data data: json.Json) -> Element(msg) {
  html.script(
    [attribute.id(id), attribute.type_("application/json")],
    data |> json.to_string |> escape_for_html,
  )
}

pub fn escape_for_html(value: String) -> String {
  value
  |> string.replace("&", "\\u0026")
  |> string.replace("<", "\\u003c")
  |> string.replace(">", "\\u003e")
}

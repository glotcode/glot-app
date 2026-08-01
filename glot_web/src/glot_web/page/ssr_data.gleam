import gleam/json
import glot_web/page/embedded_json
import lustre/element.{type Element}

/// The shared DOM contract between server rendering and frontend startup.
pub const element_id = "glot-ssr-data"

pub fn view(data: json.Json) -> Element(msg) {
  embedded_json.script(id: element_id, data: data)
}

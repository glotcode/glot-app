import gleam/dynamic/decode
import gleam/list
import gleam/string
import glot_frontend/public/editor/files as editor_files
import glot_frontend/public/editor/message.{
  type ExecutionMsg, TabKeyPressed, TabSelected,
}
import glot_frontend/public/editor/model.{
  type Editor, type EditorTab, FileTab, StdinTab,
}
import glot_frontend/public/editor/tab_semantics
import glot_web/page/editor_layout
import lustre/element.{type Element}
import lustre/event

pub fn view(model: Editor) -> List(Element(ExecutionMsg)) {
  tab_semantics.available_tabs(
    list.length(model.snippet.files),
    model.snippet.stdin,
  )
  |> list.map(fn(tab) {
    tab_button(tab_label(model, tab), tab, model.workspace.selected_tab == tab)
  })
}

fn tab_button(
  label: String,
  tab: EditorTab,
  is_selected: Bool,
) -> Element(ExecutionMsg) {
  editor_layout.tab_button(
    label: label,
    is_selected: is_selected,
    id: tab_semantics.tab_id(tab),
    panel_id: tab_semantics.panel_id,
    attributes: [
      event.on_click(TabSelected(tab)),
      event.advanced("keydown", {
        use key <- decode.field("key", decode.string)
        let handled =
          key == "Home"
          || key == "End"
          || key == "ArrowRight"
          || key == "ArrowDown"
          || key == "ArrowLeft"
          || key == "ArrowUp"
        decode.success(event.handler(
          TabKeyPressed(tab, key),
          prevent_default: handled,
          stop_propagation: False,
        ))
      }),
    ],
  )
}

fn tab_label(model: Editor, tab: EditorTab) -> String {
  case tab {
    StdinTab -> "<stdin>"
    FileTab(index) -> {
      let filename = editor_files.name_at(model.snippet.files, index)
      case string.length(filename) > 10 {
        False -> filename
        True -> editor_files.truncated_name(filename)
      }
    }
  }
}

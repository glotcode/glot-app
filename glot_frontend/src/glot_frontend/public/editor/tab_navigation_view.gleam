import gleam/dynamic/decode
import gleam/list
import gleam/option
import gleam/string
import glot_core/snippet/snippet_model
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
  let file_tabs =
    file_tabs(model.snippet.files, model.workspace.selected_tab, 0)
  case model.snippet.stdin {
    option.Some(_) ->
      list.append(file_tabs, [
        tab_button(
          "<stdin>",
          StdinTab,
          model.workspace.selected_tab == StdinTab,
        ),
      ])
    option.None -> file_tabs
  }
}

fn file_tabs(
  files: List(snippet_model.File),
  selected_tab: EditorTab,
  index: Int,
) -> List(Element(ExecutionMsg)) {
  case files {
    [] -> []
    [snippet_model.File(name:, ..), ..rest] -> [
      tab_button(
        tab_label(name),
        FileTab(index),
        selected_tab == FileTab(index),
      ),
      ..file_tabs(rest, selected_tab, index + 1)
    ]
  }
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

fn tab_label(filename: String) -> String {
  case string.length(filename) > 10 {
    False -> filename
    True -> editor_files.truncated_name(filename)
  }
}

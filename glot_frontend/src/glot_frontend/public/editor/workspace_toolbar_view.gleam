import gleam/list
import glot_core/language
import glot_frontend/public/editor/message.{
  type EditorMsg, AddEntryClicked, Execution, File, SelectedTabActionClicked,
  Settings, SettingsClicked,
}
import glot_frontend/public/editor/model.{
  type Editor, type EditorTab, FileTab, StdinTab,
}
import glot_frontend/public/editor/tab_navigation_view
import glot_web/page/editor_layout
import glot_web/page/icons
import lustre/attribute
import lustre/element.{type Element}
import lustre/event

pub fn view(model: Editor) -> List(Element(EditorMsg)) {
  let read_only = !language.is_writable(model.snippet.language)
  [
    icon_action_button(
      "editor-shell__settings-button",
      "Editor settings",
      Settings(SettingsClicked),
      [icons.cog_6_tooth()],
      read_only,
    ),
    editor_layout.tab_scroll(
      tab_navigation_view.view(model)
      |> list.map(fn(tab) { element.map(tab, Execution) }),
    ),
    selected_tab_action_button(model.workspace.selected_tab, read_only),
    icon_action_button(
      "editor-shell__tab-action-button",
      "Add editor entry",
      File(AddEntryClicked),
      [icons.document_plus()],
      read_only,
    ),
  ]
}

fn icon_action_button(
  class_name: String,
  aria_label: String,
  msg: EditorMsg,
  children: List(Element(EditorMsg)),
  disabled: Bool,
) -> Element(EditorMsg) {
  editor_layout.shell_button(
    class_name: class_name,
    attributes: [
      attribute.attribute("aria-label", aria_label),
      attribute.disabled(disabled),
      event.on_click(msg),
    ],
    children: children,
  )
}

fn selected_tab_action_button(
  tab: EditorTab,
  disabled: Bool,
) -> Element(EditorMsg) {
  editor_layout.tab_meta_button(
    aria_label: selected_tab_action_label(tab),
    pill_label: "Edit",
    attributes: [
      attribute.disabled(disabled),
      event.on_click(File(SelectedTabActionClicked)),
    ],
  )
}

fn selected_tab_action_label(tab: EditorTab) -> String {
  case tab {
    FileTab(_) -> "Edit selected file"
    StdinTab -> "Manage stdin tab"
  }
}

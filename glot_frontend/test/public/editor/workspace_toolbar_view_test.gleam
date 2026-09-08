import gleam/option
import gleam/string
import glot_core/language
import glot_frontend/public/editor/environment
import glot_frontend/public/editor/model
import glot_frontend/public/editor/ready
import glot_frontend/public/editor/workspace_toolbar_view
import lustre/element
import lustre/element/html

pub fn toolbar_renders_settings_tabs_file_management_and_add_actions_test() {
  let rendered = new_editor() |> render

  assert string.contains(rendered, "aria-label=\"Editor settings\"")
  assert string.contains(rendered, "aria-label=\"Editor files\"")
  assert string.contains(rendered, "aria-label=\"Edit selected file\"")
  assert string.contains(rendered, "aria-label=\"Add editor entry\"")
  assert string.contains(rendered, ">Edit</span>")
}

pub fn stdin_selection_changes_the_management_action_label_test() {
  let base = new_editor()
  let editor =
    model.Editor(
      ..base,
      snippet: model.Snippet(..base.snippet, stdin: option.Some("input")),
      workspace: model.Workspace(..base.workspace, selected_tab: model.StdinTab),
    )
  let rendered = render(editor)

  assert string.contains(rendered, "aria-label=\"Manage stdin tab\"")
  assert string.contains(rendered, "id=\"editor-stdin-tab\"")
  assert string.contains(rendered, "aria-selected=\"true\"")
}

fn new_editor() -> model.Editor {
  ready.new(language.JavaScript, environment.defaults())
}

fn render(editor: model.Editor) -> String {
  html.div([], workspace_toolbar_view.view(editor))
  |> element.to_document_string
}

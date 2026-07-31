import gleam/list
import gleam/option
import gleam/string
import glot_core/language
import glot_core/snippet/snippet_model
import glot_frontend/public/editor/model
import glot_frontend/public/editor/ready
import glot_frontend/public/editor/settings
import glot_frontend/public/editor/tab_navigation_view
import lustre/element
import lustre/element/html

pub fn tabs_render_from_the_shared_order_with_one_selected_tab_test() {
  let base = new_editor()
  let editor =
    model.Editor(
      ..base,
      snippet: model.Snippet(
        ..base.snippet,
        files: [
          snippet_model.File("main.js", "main"),
          snippet_model.File("helper.js", "helper"),
        ],
        stdin: option.Some("input"),
      ),
      workspace: model.Workspace(
        ..base.workspace,
        selected_tab: model.FileTab(1),
      ),
    )
  let rendered = render(editor)

  assert string.contains(rendered, "id=\"editor-file-tab-0\"")
  assert string.contains(rendered, "id=\"editor-file-tab-1\"")
  assert string.contains(rendered, "id=\"editor-stdin-tab\"")
  assert string.contains(
    rendered,
    "class=\"editor-shell__tab editor-shell__tab--selected\" id=\"editor-file-tab-1\"",
  )
  assert rendered |> string.split("aria-selected=\"true\"") |> list.length == 2
}

pub fn absent_stdin_is_not_rendered_and_long_names_are_truncated_test() {
  let base = new_editor()
  let editor =
    model.Editor(
      ..base,
      snippet: model.Snippet(
        ..base.snippet,
        files: [snippet_model.File("very-long-filename.js", "source")],
        stdin: option.None,
      ),
    )
  let rendered = render(editor)

  assert string.contains(rendered, ">very...ame.js</span>")
  assert !string.contains(rendered, "editor-stdin-tab")
}

fn new_editor() -> model.Editor {
  ready.new(language.JavaScript, settings.defaults())
}

fn render(editor: model.Editor) -> String {
  html.div([], tab_navigation_view.view(editor))
  |> element.to_document_string
}

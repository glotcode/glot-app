import gleam/option
import gleam/string
import gleam/time/timestamp
import glot_core/language
import glot_core/snippet/snippet_model
import glot_frontend/public/editor/model
import glot_frontend/public/editor/operations
import glot_frontend/public/editor/ready
import glot_frontend/public/editor/settings
import glot_frontend/public/editor/view
import lustre/element
import support/editor_fixture
import youid/uuid.{type Uuid}

pub fn new_editor_shell_renders_editable_title_and_initial_document_test() {
  let rendered = render(new_editor(), option.Some(editor_fixture.owner_id()))

  assert string.contains(rendered, ">Hello World</h1>")
  assert string.contains(rendered, "aria-label=\"Edit snippet metadata\"")
  assert !string.contains(rendered, "aria-label=\"Snippet info\"")
  assert string.contains(rendered, "language=\"javascript\"")
  assert string.contains(rendered, "editor-external-revision=\"0\"")
  assert string.contains(rendered, "editor-revision=\"0\"")
  assert string.contains(rendered, "keyboard-bindings=\"default\"")
}

pub fn existing_editor_title_actions_follow_ownership_test() {
  let editor = existing_editor()
  let owner = render(editor, option.Some(editor_fixture.owner_id()))
  assert string.contains(owner, "aria-label=\"Snippet info\"")
  assert string.contains(owner, "class=\"editor-page__title-edit-button\"")

  let non_owner = render(editor, option.Some(editor_fixture.other_user_id()))
  assert string.contains(non_owner, "aria-label=\"Snippet info\"")
  assert !string.contains(non_owner, "class=\"editor-page__title-edit-button\"")
}

pub fn shell_projects_selected_document_revisions_and_settings_test() {
  let base = new_editor()
  let editor =
    model.Editor(
      ..base,
      snippet: model.Snippet(..base.snippet, files: [
        snippet_model.File("main.js", "main"),
        snippet_model.File("helper.js", "export const answer = 42"),
      ]),
      workspace: model.Workspace(
        editor_revision: 7,
        editor_external_revision: 42,
        selected_tab: model.FileTab(1),
      ),
      editor_settings: settings.EditorSettings(settings.VimBindings),
    )
  let rendered = render(editor, option.Some(editor_fixture.owner_id()))

  assert string.contains(rendered, "value=\"export const answer = 42\"")
  assert string.contains(rendered, "editor-external-revision=\"42\"")
  assert string.contains(rendered, "editor-revision=\"7\"")
  assert string.contains(rendered, "keyboard-bindings=\"vim\"")
}

pub fn shell_disables_operations_independently_while_they_are_active_test() {
  let editor = new_editor()
  let #(running, _) = operations.begin_execution(editor.operations)
  let running_editor = model.Editor(..editor, operations: running)
  let running_rendered =
    render(running_editor, option.Some(editor_fixture.owner_id()))
  assert string.contains(
    running_rendered,
    "disabled type=\"button\">Running...</button>",
  )
  assert string.contains(running_rendered, "type=\"button\">Save</button>")

  let #(saving, _) = operations.begin_save(editor.operations)
  let saving_editor = model.Editor(..editor, operations: saving)
  let saving_rendered =
    render(saving_editor, option.Some(editor_fixture.owner_id()))
  assert string.contains(saving_rendered, "type=\"button\">Run</button>")
  assert string.contains(
    saving_rendered,
    "disabled type=\"button\">Saving...</button>",
  )
}

fn new_editor() -> model.Editor {
  ready.new(language.JavaScript, settings.defaults())
}

fn existing_editor() -> model.Editor {
  let base = new_editor()
  model.Editor(
    ..base,
    snippet: model.Snippet(
      ..base.snippet,
      slug: option.Some("existing"),
      owner_user_id: option.Some(editor_fixture.owner_id()),
      owner_username: option.Some("fixture-owner"),
    ),
  )
}

fn render(
  editor: model.Editor,
  current_user_id: option.Option(Uuid),
) -> String {
  view.view(
    model.Ready(editor),
    current_user_id,
    timestamp.from_unix_seconds(300),
  )
  |> element.to_document_string
}

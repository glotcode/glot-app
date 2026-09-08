import gleam/option
import gleam/string
import gleam/time/timestamp
import glot_core/language
import glot_core/snippet/snippet_model
import glot_frontend/public/editor/workspace
import glot_frontend/public/editor/environment
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
  // The editor renders as ordinary elements: a textarea holding the whole
  // document, and a highlighting layer for the visible lines.
  assert string.contains(rendered, "class=\"code-editor__input\"")
  assert string.contains(rendered, "data-bindings=\"default\"")
  assert string.contains(rendered, "code-editor__token--string")
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

pub fn shell_renders_the_selected_document_and_the_binding_mode_test() {
  let base =
    ready.new(
      language.JavaScript,
      environment.Environment(
        settings: settings.EditorSettings(settings.VimBindings),
        mac: False,
      ),
    )
  let with_files =
    model.Editor(
      ..base,
      snippet: model.Snippet(..base.snippet, files: [
        snippet_model.File("main.js", "main"),
        snippet_model.File("helper.js", "export const answer = 42"),
      ]),
      workspace: workspace.build(
        [
          snippet_model.File("main.js", "main"),
          snippet_model.File("helper.js", "export const answer = 42"),
        ],
        option.None,
        model.FileTab(1),
        language.JavaScript,
        environment.Environment(
          settings: settings.EditorSettings(settings.VimBindings),
          mac: False,
        ),
      ),
    )
  let rendered = render(with_files, option.Some(editor_fixture.owner_id()))

  // The whole document is in the textarea, and the highlighting layer renders
  // the same text for the viewport.
  assert string.contains(rendered, "export const answer = 42")
  assert string.contains(rendered, "data-bindings=\"vim\"")
  assert string.contains(rendered, "data-session=\"file-1\"")
  assert string.contains(rendered, "data-generation=\"0\"")
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

pub fn long_running_execution_replaces_the_disabled_button_with_cancel_test() {
  let editor = new_editor()
  let #(running, generation) = operations.begin_execution(editor.operations)
  let assert option.Some(cancellable) =
    operations.offer_execution_cancellation(running, generation)
  let cancellable_editor = model.Editor(..editor, operations: cancellable)
  let rendered =
    render(cancellable_editor, option.Some(editor_fixture.owner_id()))

  assert string.contains(rendered, "type=\"button\">Cancel</button>")
  assert !string.contains(rendered, "disabled type=\"button\">Cancel</button>")
}

pub fn plaintext_editor_is_read_only_test() {
  let editor = ready.new(language.Plaintext, environment.defaults())
  let rendered = render(editor, option.Some(editor_fixture.owner_id()))

  assert string.contains(rendered, "class=\"code-editor__input\" data-generation")
  assert string.contains(rendered, "readonly")
  // Plaintext stays unhighlighted.
  assert !string.contains(rendered, "code-editor__token--keyword")
  assert string.contains(
    rendered,
    "disabled type=\"button\">Not runnable</button>",
  )
  assert string.contains(
    rendered,
    "disabled type=\"button\">Read only</button>",
  )
  assert !string.contains(rendered, "aria-label=\"Edit snippet metadata\"")
}

fn new_editor() -> model.Editor {
  ready.new(language.JavaScript, environment.defaults())
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

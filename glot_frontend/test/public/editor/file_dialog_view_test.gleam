import gleam/option
import gleam/string
import glot_core/language
import glot_core/snippet/snippet_model
import glot_frontend/public/editor/environment
import glot_frontend/public/editor/file_dialog_view
import glot_frontend/public/editor/model
import glot_frontend/public/editor/ready
import lustre/element

pub fn add_file_submit_reflects_filename_validity_test() {
  let editor = new_editor()
  let empty = render_add(editor)
  assert string.contains(empty, "disabled type=\"submit\">Add")

  let valid = editor |> with_add_filename("helper.js") |> render_add
  assert string.contains(valid, "value=\"helper.js\"")
  assert !string.contains(valid, "disabled type=\"submit\">Add")

  let duplicate = editor |> with_add_filename("main.js") |> render_add
  assert string.contains(duplicate, "disabled type=\"submit\">Add")
}

pub fn add_stdin_explains_availability_and_disables_duplicates_test() {
  let available = new_editor() |> with_add_kind(model.AddStdinEntry)
  let rendered = render_add(available)
  assert string.contains(
    rendered,
    "Add a dedicated &lt;stdin&gt; tab for runtime input.",
  )
  assert !string.contains(rendered, "disabled type=\"submit\">Add")

  let unavailable =
    model.Editor(
      ..available,
      snippet: model.Snippet(..available.snippet, stdin: option.Some("input")),
    )
    |> render_add
  assert string.contains(
    unavailable,
    "&lt;stdin&gt; already exists for this snippet.",
  )
  assert string.contains(unavailable, "disabled type=\"submit\">Add")
}

pub fn file_edit_actions_reflect_rename_and_deletion_policy_test() {
  let single = new_editor()
  let rendered = render_edit(single)
  assert !string.contains(rendered, "Delete file")
  assert !string.contains(rendered, "disabled type=\"submit\">Save")

  let invalid = single |> with_edit_filename("") |> render_edit
  assert string.contains(invalid, "disabled type=\"submit\">Save")

  let multiple =
    single
    |> with_files([
      snippet_model.File("main.js", "main"),
      snippet_model.File("helper.js", "helper"),
    ])
    |> select(model.FileTab(1))
    |> with_edit_filename("helper.js")
    |> render_edit
  assert string.contains(multiple, "Delete file")
  assert !string.contains(multiple, "disabled type=\"submit\">Save")
}

pub fn stdin_edit_offers_deletion_without_file_fields_test() {
  let editor =
    new_editor()
    |> with_stdin("input")
    |> select(model.StdinTab)
  let rendered = render_edit(editor)

  assert string.contains(rendered, "Delete &lt;stdin&gt;")
  assert string.contains(rendered, ">Close</button>")
  assert !string.contains(rendered, "editor-page-edit-entry-input")
  assert !string.contains(rendered, "type=\"submit\"")
}

fn new_editor() -> model.Editor {
  ready.new(language.JavaScript, environment.defaults())
}

fn render_add(editor: model.Editor) -> String {
  file_dialog_view.add_dialog(editor) |> element.to_document_string
}

fn render_edit(editor: model.Editor) -> String {
  file_dialog_view.edit_dialog(editor) |> element.to_document_string
}

fn with_add_filename(editor: model.Editor, filename: String) -> model.Editor {
  model.Editor(
    ..editor,
    entry_drafts: model.EntryDrafts(
      ..editor.entry_drafts,
      add: model.AddEntryDraft(model.AddFileEntry, filename),
    ),
  )
}

fn with_add_kind(
  editor: model.Editor,
  kind: model.AddEntryKind,
) -> model.Editor {
  model.Editor(
    ..editor,
    entry_drafts: model.EntryDrafts(
      ..editor.entry_drafts,
      add: model.AddEntryDraft(..editor.entry_drafts.add, kind: kind),
    ),
  )
}

fn with_edit_filename(editor: model.Editor, filename: String) -> model.Editor {
  model.Editor(
    ..editor,
    entry_drafts: model.EntryDrafts(
      ..editor.entry_drafts,
      edit: model.EditEntryDraft(filename),
    ),
  )
}

fn with_files(
  editor: model.Editor,
  files: List(snippet_model.File),
) -> model.Editor {
  model.Editor(..editor, snippet: model.Snippet(..editor.snippet, files: files))
}

fn with_stdin(editor: model.Editor, stdin: String) -> model.Editor {
  model.Editor(
    ..editor,
    snippet: model.Snippet(..editor.snippet, stdin: option.Some(stdin)),
  )
}

fn select(editor: model.Editor, tab: model.EditorTab) -> model.Editor {
  model.Editor(
    ..editor,
    workspace: model.Workspace(..editor.workspace, selected_tab: tab),
  )
}

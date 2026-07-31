import gleam/option
import glot_core/language
import glot_core/snippet/snippet_model
import glot_frontend/public/editor/file_policy
import glot_frontend/public/editor/model
import glot_frontend/public/editor/ready
import glot_frontend/public/editor/settings

pub fn add_file_requires_a_unique_trimmed_valid_name_test() {
  let editor = new_editor()

  assert file_policy.can_submit_add_entry(with_add_file(editor, " helper.js "))
  assert !file_policy.can_submit_add_entry(with_add_file(editor, ""))
  assert !file_policy.can_submit_add_entry(with_add_file(editor, "main.js"))
  assert !file_policy.can_submit_add_entry(with_add_file(
    editor,
    "this-filename-is-longer-than-thirty-characters.js",
  ))
}

pub fn stdin_can_only_be_added_once_test() {
  let editor = with_add_kind(new_editor(), model.AddStdinEntry)
  assert file_policy.can_submit_add_entry(editor)
  assert file_policy.add_stdin_message(option.None)
    == "Add a dedicated <stdin> tab for runtime input."

  let with_stdin =
    model.Editor(
      ..editor,
      snippet: model.Snippet(..editor.snippet, stdin: option.Some("input")),
    )
  assert !file_policy.can_submit_add_entry(with_stdin)
  assert file_policy.add_stdin_message(with_stdin.snippet.stdin)
    == "<stdin> already exists for this snippet."
}

pub fn edit_accepts_the_selected_name_but_rejects_other_duplicates_test() {
  let editor =
    with_files(new_editor(), [
      snippet_model.File("main.js", "main"),
      snippet_model.File("helper.js", "helper"),
    ])
  let selected =
    model.Editor(
      ..editor,
      workspace: model.Workspace(
        ..editor.workspace,
        selected_tab: model.FileTab(1),
      ),
    )

  assert file_policy.can_submit_edit_entry(with_edit_name(selected, "helper.js"))
  assert file_policy.can_submit_edit_entry(with_edit_name(
    selected,
    " renamed.js ",
  ))
  assert !file_policy.can_submit_edit_entry(with_edit_name(selected, "main.js"))
  assert !file_policy.can_submit_edit_entry(with_edit_name(selected, ""))
  assert !file_policy.can_submit_edit_entry(
    model.Editor(
      ..selected,
      workspace: model.Workspace(
        ..selected.workspace,
        selected_tab: model.StdinTab,
      ),
    ),
  )
}

pub fn deletion_requires_a_selected_file_and_a_remaining_file_test() {
  let editor = new_editor()
  assert !file_policy.can_delete_selected_file(editor)

  let multiple =
    with_files(editor, [
      snippet_model.File("main.js", "main"),
      snippet_model.File("helper.js", "helper"),
    ])
  assert file_policy.can_delete_selected_file(multiple)
  assert !file_policy.can_delete_selected_file(
    model.Editor(
      ..multiple,
      workspace: model.Workspace(
        ..multiple.workspace,
        selected_tab: model.StdinTab,
      ),
    ),
  )
}

fn new_editor() -> model.Editor {
  ready.new(language.JavaScript, settings.defaults())
}

fn with_add_file(editor: model.Editor, filename: String) -> model.Editor {
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

fn with_edit_name(editor: model.Editor, filename: String) -> model.Editor {
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

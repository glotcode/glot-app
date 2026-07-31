import gleam/option
import glot_core/language
import glot_core/snippet/snippet_model
import glot_frontend/public/editor/file_policy
import glot_frontend/public/editor/model
import glot_frontend/public/editor/ready
import glot_frontend/public/editor/settings

pub fn add_file_requires_a_unique_trimmed_valid_name_test() {
  let editor = new_editor()

  let valid = with_add_file(editor, " helper.js ")
  assert file_policy.add_entry(valid) == file_policy.AddFile("helper.js")
  assert file_policy.can_submit_add_entry(valid)
  assert file_policy.add_entry(with_add_file(editor, ""))
    == file_policy.AddEntryBlocked
  assert file_policy.add_entry(with_add_file(editor, "main.js"))
    == file_policy.AddEntryBlocked
  assert file_policy.add_entry(with_add_file(
      editor,
      "this-filename-is-longer-than-thirty-characters.js",
    ))
    == file_policy.AddEntryBlocked
}

pub fn stdin_can_only_be_added_once_test() {
  let editor = with_add_kind(new_editor(), model.AddStdinEntry)
  assert file_policy.add_entry(editor) == file_policy.AddStdin
  assert file_policy.can_submit_add_entry(editor)
  assert file_policy.add_stdin_message(option.None)
    == "Add a dedicated <stdin> tab for runtime input."

  let with_stdin =
    model.Editor(
      ..editor,
      snippet: model.Snippet(..editor.snippet, stdin: option.Some("input")),
    )
  assert file_policy.add_entry(with_stdin) == file_policy.AddEntryBlocked
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

  assert file_policy.edit_entry(with_edit_name(selected, "helper.js"))
    == file_policy.RenameFile(1, "helper.js")
  assert file_policy.edit_entry(with_edit_name(selected, " renamed.js "))
    == file_policy.RenameFile(1, "renamed.js")
  assert file_policy.edit_entry(with_edit_name(selected, "main.js"))
    == file_policy.EditEntryBlocked
  assert file_policy.edit_entry(with_edit_name(selected, ""))
    == file_policy.EditEntryBlocked
  assert file_policy.edit_entry(
      model.Editor(
        ..selected,
        workspace: model.Workspace(
          ..selected.workspace,
          selected_tab: model.StdinTab,
        ),
      ),
    )
    == file_policy.EditEntryBlocked
}

pub fn deletion_requires_a_selected_file_and_a_remaining_file_test() {
  let editor = new_editor()
  assert file_policy.delete_entry(editor) == file_policy.DeleteEntryBlocked

  let multiple =
    with_files(editor, [
      snippet_model.File("main.js", "main"),
      snippet_model.File("helper.js", "helper"),
    ])
  assert file_policy.delete_entry(multiple) == file_policy.DeleteFile(0)
  assert file_policy.can_delete_selected_file(multiple)
  assert file_policy.delete_entry(
      model.Editor(
        ..multiple,
        snippet: model.Snippet(..multiple.snippet, stdin: option.Some("input")),
        workspace: model.Workspace(
          ..multiple.workspace,
          selected_tab: model.StdinTab,
        ),
      ),
    )
    == file_policy.DeleteStdin
}

pub fn decisions_reject_nonexistent_selected_entries_test() {
  let editor =
    with_files(new_editor(), [
      snippet_model.File("main.js", "main"),
      snippet_model.File("helper.js", "helper"),
    ])
  let invalid_file =
    model.Editor(
      ..editor,
      workspace: model.Workspace(
        ..editor.workspace,
        selected_tab: model.FileTab(5),
      ),
      entry_drafts: model.EntryDrafts(
        ..editor.entry_drafts,
        edit: model.EditEntryDraft("valid.js"),
      ),
    )
  assert file_policy.edit_entry(invalid_file) == file_policy.EditEntryBlocked
  assert file_policy.delete_entry(invalid_file)
    == file_policy.DeleteEntryBlocked

  let missing_stdin =
    model.Editor(
      ..editor,
      workspace: model.Workspace(
        ..editor.workspace,
        selected_tab: model.StdinTab,
      ),
    )
  assert file_policy.delete_entry(missing_stdin)
    == file_policy.DeleteEntryBlocked
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

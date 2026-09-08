import glot_core/language
import glot_core/snippet/snippet_model
import glot_frontend/public/editor/environment
import glot_frontend/public/editor/code_editor/browser_command
import glot_frontend/public/editor/command
import glot_frontend/public/editor/draft_projection
import glot_frontend/public/editor/file_update
import glot_frontend/public/editor/message
import glot_frontend/public/editor/model
import glot_frontend/public/editor/ready

pub fn add_dialog_messages_own_the_add_draft_and_browser_commands_test() {
  let editor =
    model.Editor(
      ..new_editor(),
      entry_drafts: model.EntryDrafts(
        ..new_editor().entry_drafts,
        add: model.AddEntryDraft(model.AddStdinEntry, "stale"),
      ),
    )
  let #(opened, open_command) =
    file_update.update(editor, message.AddEntryClicked)
  assert opened.entry_drafts.add == model.AddEntryDraft(model.AddFileEntry, "")
  assert open_command == command.OpenDialog("editor-page-add-entry-dialog")

  let #(kind_selected, kind_command) =
    file_update.update(
      opened,
      message.AddEntryKindSelected(model.AddStdinEntry),
    )
  assert kind_selected.entry_drafts.add.kind == model.AddStdinEntry
  assert kind_command == command.None

  let #(changed, change_command) =
    file_update.update(
      kind_selected,
      message.AddEntryFilenameChanged("draft.js"),
    )
  assert changed.entry_drafts.add.filename == "draft.js"
  assert change_command == command.None
}

pub fn successful_add_closes_the_dialog_and_persists_the_projected_draft_test() {
  let editor = with_add_filename(new_editor(), "helper.js")
  let #(added, next_command) =
    file_update.update(editor, message.AddEntrySubmitted)

  assert added.snippet.files
    == [
      snippet_model.File("main.js", "console.log(\"Hello World!\");"),
      snippet_model.File("helper.js", ""),
    ]
  assert next_command
    == command.Batch([
      command.CloseDialog("editor-page-add-entry-dialog"),
      command.SaveDraft(draft_projection.write(added)),
      command.CodeEditor(browser_command.SyncSession("file-1", 0, "", 0, 0, 0, 0)),
    ])
}

pub fn rejected_add_leaves_state_and_effects_unchanged_test() {
  let editor = with_add_filename(new_editor(), "main.js")
  assert file_update.update(editor, message.AddEntrySubmitted)
    == #(editor, command.None)
}

pub fn add_cancel_and_close_reset_the_draft_with_distinct_effects_test() {
  let editor = with_add_filename(new_editor(), "discarded.js")
  let #(cancelled, cancel_command) =
    file_update.update(editor, message.AddEntryCancelled)
  assert cancelled.entry_drafts.add.filename == ""
  assert cancel_command == command.CloseDialog("editor-page-add-entry-dialog")

  let #(closed, close_command) =
    file_update.update(editor, message.AddEntryDialogClosed)
  assert closed.entry_drafts.add.filename == ""
  assert close_command == command.Focus("code-editor-input")
}

pub fn edit_dialog_messages_own_the_edit_draft_and_browser_commands_test() {
  let editor = two_file_editor()
  let stale =
    model.Editor(
      ..editor,
      entry_drafts: model.EntryDrafts(
        ..editor.entry_drafts,
        edit: model.EditEntryDraft("stale"),
      ),
    )
  let #(opened, open_command) =
    file_update.update(stale, message.SelectedTabActionClicked)
  assert opened.entry_drafts.edit.filename == "helper.js"
  assert open_command == command.OpenDialog("editor-page-edit-entry-dialog")

  let #(changed, change_command) =
    file_update.update(opened, message.EditEntryFilenameChanged("renamed.js"))
  assert changed.entry_drafts.edit.filename == "renamed.js"
  assert change_command == command.None

  let #(cancelled, cancel_command) =
    file_update.update(changed, message.EditEntryCancelled)
  assert cancelled.entry_drafts.edit.filename == "helper.js"
  assert cancel_command == command.CloseDialog("editor-page-edit-entry-dialog")

  let #(closed, close_command) =
    file_update.update(changed, message.EditEntryDialogClosed)
  assert closed.entry_drafts.edit.filename == "helper.js"
  assert close_command == command.Focus("code-editor-input")
}

pub fn rename_and_delete_persist_only_successful_changes_test() {
  let editor = two_file_editor()
  let renamed_draft =
    model.Editor(
      ..editor,
      entry_drafts: model.EntryDrafts(
        ..editor.entry_drafts,
        edit: model.EditEntryDraft("renamed.js"),
      ),
    )
  let #(renamed, rename_command) =
    file_update.update(renamed_draft, message.EditEntrySubmitted)
  assert renamed.snippet.files
    == [
      snippet_model.File("main.js", "main"),
      snippet_model.File("renamed.js", "helper"),
    ]
  assert rename_command
    == command.Batch([
      command.CloseDialog("editor-page-edit-entry-dialog"),
      command.SaveDraft(draft_projection.write(renamed)),
    ])

  let #(deleted, delete_command) =
    file_update.update(renamed, message.EditEntryDeleted)
  assert deleted.snippet.files == [snippet_model.File("main.js", "main")]
  assert delete_command
    == command.Batch([
      command.CloseDialog("editor-page-edit-entry-dialog"),
      command.SaveDraft(draft_projection.write(deleted)),
      command.CodeEditor(browser_command.SyncSession("file-0", 0, "console.log(\"Hello World!\");", 0, 0, 0, 0)),
    ])

  assert file_update.update(deleted, message.EditEntryDeleted)
    == #(deleted, command.None)
}

fn new_editor() -> model.Editor {
  ready.new(language.JavaScript, environment.defaults())
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

fn two_file_editor() -> model.Editor {
  let editor = new_editor()
  model.Editor(
    ..editor,
    snippet: model.Snippet(..editor.snippet, files: [
      snippet_model.File("main.js", "main"),
      snippet_model.File("helper.js", "helper"),
    ]),
    workspace: model.Workspace(
      ..editor.workspace,
      selected_tab: model.FileTab(1),
    ),
    entry_drafts: model.EntryDrafts(
      ..editor.entry_drafts,
      edit: model.EditEntryDraft("helper.js"),
    ),
  )
}

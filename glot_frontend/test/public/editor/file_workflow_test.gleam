import gleam/option
import glot_core/language
import glot_core/snippet/snippet_model
import glot_frontend/public/editor/file_workflow
import glot_frontend/public/editor/model
import glot_frontend/public/editor/ready
import glot_frontend/public/editor/settings

pub fn adding_a_file_trims_its_name_and_rebuilds_dependent_state_test() {
  let editor = with_add_draft(new_editor(), model.AddFileEntry, " helper.js ")
  let assert option.Some(added) = file_workflow.add_entry(editor)

  assert added.snippet.files
    == [
      snippet_model.File("main.js", "console.log(\"Hello World!\");"),
      snippet_model.File("helper.js", ""),
    ]
  assert added.workspace.selected_tab == model.FileTab(1)
  assert added.workspace.editor_external_revision == 1
  assert added.entry_drafts.add.filename == ""
  assert added.entry_drafts.edit.filename == "helper.js"
}

pub fn invalid_and_duplicate_files_leave_the_editor_unchanged_test() {
  let editor = new_editor()
  assert file_workflow.add_entry(with_add_draft(editor, model.AddFileEntry, ""))
    == option.None
  assert file_workflow.add_entry(with_add_draft(
      editor,
      model.AddFileEntry,
      "main.js",
    ))
    == option.None
}

pub fn stdin_addition_and_deletion_rebuild_selection_and_drafts_test() {
  let editor = with_add_draft(new_editor(), model.AddStdinEntry, "ignored")
  let assert option.Some(added) = file_workflow.add_entry(editor)
  assert added.snippet.stdin == option.Some("")
  assert added.workspace.selected_tab == model.StdinTab
  assert added.workspace.editor_external_revision == 1
  assert added.entry_drafts.add.kind == model.AddFileEntry
  assert file_workflow.add_entry(with_add_draft(
      added,
      model.AddStdinEntry,
      "ignored",
    ))
    == option.None

  let assert option.Some(deleted) = file_workflow.delete_selected_entry(added)
  assert deleted.snippet.stdin == option.None
  assert deleted.workspace.selected_tab == model.FileTab(0)
  assert deleted.workspace.editor_external_revision == 2
  assert deleted.entry_drafts.edit.filename == "main.js"
}

pub fn rename_allows_the_current_name_and_rejects_other_duplicates_test() {
  let editor = two_file_editor()
  let unchanged_name = with_edit_name(editor, " helper.js ")
  let assert option.Some(unchanged) =
    file_workflow.rename_selected_file(unchanged_name)
  assert unchanged.snippet.files == editor.snippet.files
  assert unchanged.entry_drafts.edit.filename == "helper.js"

  assert file_workflow.rename_selected_file(with_edit_name(editor, "main.js"))
    == option.None
  assert file_workflow.rename_selected_file(
      model.Editor(
        ..editor,
        workspace: model.Workspace(
          ..editor.workspace,
          selected_tab: model.StdinTab,
        ),
      ),
    )
    == option.None
}

pub fn deleting_files_keeps_the_nearest_valid_selection_test() {
  let editor = two_file_editor()
  let assert option.Some(last_deleted) =
    file_workflow.delete_selected_entry(editor)
  assert last_deleted.snippet.files == [snippet_model.File("main.js", "main")]
  assert last_deleted.workspace.selected_tab == model.FileTab(0)
  assert last_deleted.entry_drafts.edit.filename == "main.js"
  assert file_workflow.delete_selected_entry(last_deleted) == option.None

  let first_selected =
    model.Editor(
      ..two_file_editor(),
      workspace: model.Workspace(
        ..two_file_editor().workspace,
        selected_tab: model.FileTab(0),
      ),
    )
  let assert option.Some(first_deleted) =
    file_workflow.delete_selected_entry(first_selected)
  assert first_deleted.snippet.files
    == [snippet_model.File("helper.js", "helper")]
  assert first_deleted.workspace.selected_tab == model.FileTab(0)
}

pub fn invalid_selected_entries_cannot_report_successful_mutations_test() {
  let editor = two_file_editor()
  let invalid =
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

  assert file_workflow.rename_selected_file(invalid) == option.None
  assert file_workflow.delete_selected_entry(invalid) == option.None
}

pub fn selected_content_updates_only_the_selected_document_test() {
  let editor = two_file_editor()
  let file_updated =
    file_workflow.update_selected_tab_content(editor, "updated helper")
  assert file_updated.snippet.files
    == [
      snippet_model.File("main.js", "main"),
      snippet_model.File("helper.js", "updated helper"),
    ]

  let stdin_editor =
    model.Editor(
      ..editor,
      snippet: model.Snippet(..editor.snippet, stdin: option.Some("old input")),
      workspace: model.Workspace(
        ..editor.workspace,
        selected_tab: model.StdinTab,
      ),
    )
  let stdin_updated =
    file_workflow.update_selected_tab_content(stdin_editor, "new input")
  assert stdin_updated.snippet.stdin == option.Some("new input")
  assert stdin_updated.snippet.files == editor.snippet.files
}

pub fn resetting_each_dialog_draft_preserves_the_other_test() {
  let editor =
    model.Editor(
      ..new_editor(),
      entry_drafts: model.EntryDrafts(
        add: model.AddEntryDraft(model.AddStdinEntry, "add draft"),
        edit: model.EditEntryDraft("edit draft"),
      ),
    )

  let add_reset = file_workflow.reset_add_entry_draft(editor)
  assert add_reset.entry_drafts.add
    == model.AddEntryDraft(model.AddFileEntry, "")
  assert add_reset.entry_drafts.edit == editor.entry_drafts.edit

  let edit_reset = file_workflow.reset_edit_entry_draft(editor)
  assert edit_reset.entry_drafts.add == editor.entry_drafts.add
  assert edit_reset.entry_drafts.edit == model.EditEntryDraft("main.js")
}

fn new_editor() -> model.Editor {
  ready.new(language.JavaScript, settings.defaults())
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

fn with_add_draft(
  editor: model.Editor,
  kind: model.AddEntryKind,
  filename: String,
) -> model.Editor {
  model.Editor(
    ..editor,
    entry_drafts: model.EntryDrafts(
      ..editor.entry_drafts,
      add: model.AddEntryDraft(kind, filename),
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

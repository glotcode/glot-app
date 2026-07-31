import gleam/option
import gleeunit
import glot_core/language
import glot_core/snippet/snippet_model
import glot_frontend/public/editor/execution_update
import glot_frontend/public/editor/file_workflow
import glot_frontend/public/editor/message
import glot_frontend/public/editor/model
import glot_frontend/public/editor/run_instructions
import support/editor_scenario

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn custom_run_instructions_are_normalized_from_the_draft_test() {
  let instructions =
    model.RunInstructionsDraft(
      build_commands_text: " npm install \n\n npm run build ",
      run_command: " node main.js ",
    )
    |> run_instructions.run_instructions_from_draft

  assert instructions.build_commands == ["npm install", "npm run build"]
  assert instructions.run_command == "node main.js"
}

pub fn file_workflow_adds_selects_and_updates_a_file_atomically_test() {
  let assert model.Ready(editor) =
    editor_scenario.new_editor(language.JavaScript)
  let adding =
    model.Editor(
      ..editor,
      entry_drafts: model.EntryDrafts(
        ..editor.entry_drafts,
        add: model.AddEntryDraft(
          kind: model.AddFileEntry,
          filename: " helper.js ",
        ),
      ),
    )
  let assert option.Some(added) = file_workflow.add_entry(adding)
  assert added.workspace.selected_tab == model.FileTab(1)
  assert added.snippet.files
    == [
      snippet_model.File("main.js", "console.log(\"Hello World!\");"),
      snippet_model.File("helper.js", ""),
    ]

  let updated = file_workflow.update_selected_tab_content(added, "export {}")
  assert updated.snippet.files
    == [
      snippet_model.File("main.js", "console.log(\"Hello World!\");"),
      snippet_model.File("helper.js", "export {}"),
    ]
}

pub fn deleting_the_only_file_is_rejected_test() {
  let assert model.Ready(editor) =
    editor_scenario.new_editor(language.JavaScript)
  assert file_workflow.delete_selected_entry(editor) == option.None
}

pub fn tab_navigation_does_not_mutate_entry_dialog_drafts_test() {
  let assert model.Ready(editor) =
    editor_scenario.new_editor(language.JavaScript)
  let editor =
    model.Editor(
      ..editor,
      entry_drafts: model.EntryDrafts(
        add: model.AddEntryDraft(model.AddStdinEntry, "untouched-add"),
        edit: model.EditEntryDraft("untouched-edit"),
      ),
    )
  let #(selected, _) =
    execution_update.update(editor, message.TabSelected(model.FileTab(0)))

  assert selected.entry_drafts == editor.entry_drafts
}

pub fn resetting_one_entry_draft_preserves_the_other_test() {
  let assert model.Ready(editor) =
    editor_scenario.new_editor(language.JavaScript)
  let editor =
    model.Editor(
      ..editor,
      entry_drafts: model.EntryDrafts(
        add: model.AddEntryDraft(model.AddStdinEntry, "add draft"),
        edit: model.EditEntryDraft("edit draft"),
      ),
    )

  let add_reset = file_workflow.reset_add_entry_draft(editor)
  assert add_reset.entry_drafts.add.filename == ""
  assert add_reset.entry_drafts.edit == editor.entry_drafts.edit

  let edit_reset = file_workflow.reset_edit_entry_draft(editor)
  assert edit_reset.entry_drafts.add == editor.entry_drafts.add
  assert edit_reset.entry_drafts.edit.filename == "main.js"
}

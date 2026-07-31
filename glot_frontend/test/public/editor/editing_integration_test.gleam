import gleam/list
import gleam/option
import gleam/string
import gleam/time/timestamp
import glot_core/language
import glot_core/snippet/snippet_model
import glot_frontend/public/editor/draft
import glot_frontend/public/editor/draft_persistence
import glot_frontend/public/editor/message
import glot_frontend/public/editor/metadata_dialog_view
import glot_frontend/public/editor/model
import glot_frontend/public/editor/settings
import glot_frontend/public/editor/view
import lustre/element
import support/editor_fixture
import support/editor_scenario

pub fn add_file_renders_a_tab_and_participates_in_execution_test() {
  let scenario =
    new_scenario()
    |> editor_scenario.dispatch_file(message.AddEntryClicked)
    |> editor_scenario.dispatch_file(message.AddEntryFilenameChanged(
      "helper.js",
    ))
    |> editor_scenario.dispatch_file(message.AddEntrySubmitted)
    |> editor_scenario.dispatch_execution(message.SourceCodeChanged(
      "export const answer = 42",
      1,
    ))
  let editor = editor_scenario.editor(scenario)
  assert editor.snippet.files
    == [
      snippet_model.File("main.js", "console.log(\"Hello World!\");"),
      snippet_model.File("helper.js", "export const answer = 42"),
    ]
  assert editor.workspace.selected_tab == model.FileTab(1)
  assert string.contains(render(scenario), "helper.js")

  let scenario =
    editor_scenario.dispatch_execution(scenario, message.RunSubmitted)
  let assert [editor_scenario.RunCode(request, _)] =
    editor_scenario.pending(scenario)
  assert request.payload.files == editor.snippet.files
}

pub fn duplicate_and_invalid_filenames_are_rejected_without_draft_effects_test() {
  let invalid =
    new_scenario()
    |> editor_scenario.dispatch_file(message.AddEntryClicked)
    |> editor_scenario.dispatch_file(message.AddEntrySubmitted)
  let invalid_editor = editor_scenario.editor(invalid)
  assert list.length(invalid_editor.snippet.files) == 1
  assert !has_draft_save(editor_scenario.observed(invalid))

  let duplicate =
    invalid
    |> editor_scenario.dispatch_file(message.AddEntryFilenameChanged("main.js"))
    |> editor_scenario.dispatch_file(message.AddEntrySubmitted)
  let duplicate_editor = editor_scenario.editor(duplicate)
  assert list.length(duplicate_editor.snippet.files) == 1
  assert string.contains(render(duplicate), "disabled type=\"submit\">Add")
}

pub fn add_dialog_cancel_and_close_reset_draft_and_restore_focus_test() {
  let cancelled =
    new_scenario()
    |> editor_scenario.dispatch_file(message.AddEntryClicked)
    |> editor_scenario.dispatch_file(message.AddEntryFilenameChanged(
      "discarded.js",
    ))
    |> editor_scenario.dispatch_file(message.AddEntryCancelled)
  let cancelled_editor = editor_scenario.editor(cancelled)
  assert cancelled_editor.entry_drafts.add.filename == ""
  assert list.contains(
    editor_scenario.observed(cancelled),
    editor_scenario.DialogClosed("editor-page-add-entry-dialog"),
  )

  let closed =
    cancelled
    |> editor_scenario.dispatch_file(message.AddEntryClicked)
    |> editor_scenario.dispatch_file(message.AddEntryFilenameChanged(
      "also-discarded.js",
    ))
    |> editor_scenario.dispatch_file(message.AddEntryDialogClosed)
  let closed_editor = editor_scenario.editor(closed)
  assert closed_editor.entry_drafts.add.filename == ""
  assert list.contains(
    editor_scenario.observed(closed),
    editor_scenario.ElementFocused("editor-page-codemirror"),
  )
}

pub fn rename_and_delete_workflow_keeps_selection_and_run_payload_consistent_test() {
  let scenario =
    new_scenario()
    |> add_file("second.js")
    |> editor_scenario.dispatch_file(message.SelectedTabActionClicked)
    |> editor_scenario.dispatch_file(message.EditEntryFilenameChanged(
      "renamed.js",
    ))
    |> editor_scenario.dispatch_file(message.EditEntrySubmitted)
  let renamed = editor_scenario.editor(scenario)
  assert renamed.snippet.files
    == [
      snippet_model.File("main.js", "console.log(\"Hello World!\");"),
      snippet_model.File("renamed.js", ""),
    ]

  let scenario =
    editor_scenario.dispatch_file(scenario, message.SelectedTabActionClicked)
    |> editor_scenario.dispatch_file(message.EditEntryDeleted)
  let deleted = editor_scenario.editor(scenario)
  assert deleted.snippet.files
    == [snippet_model.File("main.js", "console.log(\"Hello World!\");")]
  assert deleted.workspace.selected_tab == model.FileTab(0)
  let scenario =
    editor_scenario.dispatch_execution(scenario, message.RunSubmitted)
  let assert [editor_scenario.RunCode(request, _)] =
    editor_scenario.pending(scenario)
  assert request.payload.files == deleted.snippet.files
}

pub fn deleting_the_only_file_through_the_dialog_leaves_editor_unchanged_test() {
  let scenario =
    new_scenario()
    |> editor_scenario.dispatch_file(message.SelectedTabActionClicked)
  let before = editor_scenario.model(scenario)
  let scenario =
    editor_scenario.dispatch_file(scenario, message.EditEntryDeleted)
  assert editor_scenario.model(scenario) == before
  assert !has_draft_save(editor_scenario.observed(scenario))
  assert !string.contains(render(scenario), "Delete file")
}

pub fn edit_dialog_cancel_and_close_restore_filename_and_editor_focus_test() {
  let scenario =
    new_scenario()
    |> add_file("second.js")
    |> editor_scenario.dispatch_file(message.SelectedTabActionClicked)
    |> editor_scenario.dispatch_file(message.EditEntryFilenameChanged(
      "discarded.js",
    ))
    |> editor_scenario.dispatch_file(message.EditEntryCancelled)
  let cancelled = editor_scenario.editor(scenario)
  assert cancelled.entry_drafts.edit.filename == "second.js"
  assert list.contains(
    editor_scenario.observed(scenario),
    editor_scenario.DialogClosed("editor-page-edit-entry-dialog"),
  )

  let scenario =
    editor_scenario.dispatch_file(scenario, message.SelectedTabActionClicked)
    |> editor_scenario.dispatch_file(message.EditEntryFilenameChanged(
      "also-discarded.js",
    ))
    |> editor_scenario.dispatch_file(message.EditEntryDialogClosed)
  let closed = editor_scenario.editor(scenario)
  assert closed.entry_drafts.edit.filename == "second.js"
  assert list.contains(
    editor_scenario.observed(scenario),
    editor_scenario.ElementFocused("editor-page-codemirror"),
  )
}

pub fn stdin_can_be_added_edited_executed_and_removed_test() {
  let scenario =
    new_scenario()
    |> editor_scenario.dispatch_file(message.AddEntryClicked)
    |> editor_scenario.dispatch_file(message.AddEntryKindSelected(
      model.AddStdinEntry,
    ))
    |> editor_scenario.dispatch_file(message.AddEntrySubmitted)
    |> editor_scenario.dispatch_execution(message.SourceCodeChanged(
      "fixture input",
      1,
    ))
  let with_stdin = editor_scenario.editor(scenario)
  assert with_stdin.snippet.stdin == option.Some("fixture input")
  assert with_stdin.workspace.selected_tab == model.StdinTab

  let scenario =
    editor_scenario.dispatch_execution(scenario, message.RunSubmitted)
  let assert [editor_scenario.RunCode(request, _)] =
    editor_scenario.pending(scenario)
  assert request.payload.stdin == option.Some("fixture input")
  let scenario =
    editor_scenario.respond_to_run(
      scenario,
      editor_fixture.successful_run(stdout: "ok", stderr: "", error: ""),
    )
    |> editor_scenario.dispatch_file(message.SelectedTabActionClicked)
    |> editor_scenario.dispatch_file(message.EditEntryDeleted)
  let without_stdin = editor_scenario.editor(scenario)
  assert without_stdin.snippet.stdin == option.None
  assert without_stdin.workspace.selected_tab == model.FileTab(0)
}

pub fn switching_tabs_updates_rendered_document_and_external_revision_test() {
  let scenario = new_scenario() |> add_file("empty.js")
  let before = editor_scenario.editor(scenario)
  let scenario =
    editor_scenario.dispatch_execution(
      scenario,
      message.TabSelected(model.FileTab(0)),
    )
  let after = editor_scenario.editor(scenario)
  assert after.workspace.editor_external_revision
    == before.workspace.editor_external_revision + 1
  let rendered = render(scenario)
  assert string.contains(
    rendered,
    "value=\"console.log(&quot;Hello World!&quot;);\"",
  )
  assert string.contains(rendered, "editor-external-revision=\"2\"")
}

pub fn metadata_submission_updates_rendering_and_persists_the_draft_test() {
  let scenario =
    new_scenario()
    |> editor_scenario.dispatch_metadata(message.EditMetadataClicked)
    |> editor_scenario.dispatch_metadata(message.TitleDraftChanged("New title"))
    |> editor_scenario.dispatch_metadata(message.EditMetadataVisibilitySelected(
      snippet_model.Public,
    ))
    |> editor_scenario.dispatch_metadata(message.EditMetadataSubmitted)
  let editor = editor_scenario.editor(scenario)
  assert editor.snippet.title == "New title"
  assert editor.snippet.visibility == snippet_model.Public
  assert list.contains(
    editor_scenario.observed(scenario),
    editor_scenario.DraftSaved(draft_persistence.Write(
      target: draft_persistence.NewSnippet("javascript"),
      value: draft.EditorDraft(
        title: "New title",
        language: language.JavaScript,
        files: editor.snippet.files,
        stdin: option.None,
        run_instructions_override: option.None,
      ),
    )),
  )
  assert string.contains(render(scenario), ">New title</h1>")
}

pub fn metadata_visibility_is_only_shown_for_existing_snippets_test() {
  let assert model.Ready(new_editor) =
    editor_scenario.new_editor(language.JavaScript)
  let new_dialog =
    metadata_dialog_view.view(new_editor)
    |> element.to_document_string
  assert !string.contains(new_dialog, "aria-label=\"Visibility\"")

  let existing_dialog =
    metadata_dialog_view.view(
      model.Editor(
        ..new_editor,
        snippet: model.Snippet(
          ..new_editor.snippet,
          slug: option.Some("visibility-fixture"),
        ),
      ),
    )
    |> element.to_document_string
  assert string.contains(existing_dialog, "aria-label=\"Visibility\"")
}

pub fn metadata_cancel_and_close_restore_drafts_and_focus_editor_test() {
  let scenario =
    new_scenario()
    |> editor_scenario.dispatch_metadata(message.EditMetadataClicked)
    |> editor_scenario.dispatch_metadata(message.TitleDraftChanged("Discarded"))
    |> editor_scenario.dispatch_metadata(message.EditMetadataVisibilitySelected(
      snippet_model.Public,
    ))
    |> editor_scenario.dispatch_metadata(message.EditMetadataCancelled)
  let cancelled = editor_scenario.editor(scenario)
  assert cancelled.metadata_draft.title == cancelled.snippet.title
  assert cancelled.metadata_draft.visibility == cancelled.snippet.visibility
  assert !has_draft_save(editor_scenario.observed(scenario))

  let scenario =
    editor_scenario.dispatch_metadata(scenario, message.EditMetadataClicked)
    |> editor_scenario.dispatch_metadata(message.TitleDraftChanged(
      "Also discarded",
    ))
    |> editor_scenario.dispatch_metadata(message.EditMetadataDialogClosed)
  let closed = editor_scenario.editor(scenario)
  assert closed.metadata_draft.title == closed.snippet.title
  assert list.contains(
    editor_scenario.observed(scenario),
    editor_scenario.ElementFocused("editor-page-codemirror"),
  )
}

pub fn custom_run_instructions_and_keyboard_settings_drive_execution_test() {
  let scenario =
    new_scenario()
    |> editor_scenario.dispatch_settings(message.SettingsClicked)
    |> editor_scenario.dispatch_settings(message.KeyboardBindingsDraftSelected(
      settings.VimBindings,
    ))
    |> editor_scenario.dispatch_settings(
      message.RunInstructionsModeDraftChanged("custom"),
    )
    |> editor_scenario.dispatch_settings(
      message.RunInstructionsBuildCommandsDraftChanged(
        " npm install \n\n npm run build ",
      ),
    )
    |> editor_scenario.dispatch_settings(
      message.RunInstructionsRunCommandDraftChanged(" node dist/main.js "),
    )
    |> editor_scenario.dispatch_settings(message.SettingsSubmitted)
  let editor = editor_scenario.editor(scenario)
  assert editor.editor_settings.keyboard_bindings == settings.VimBindings
  let assert option.Some(instructions) =
    editor.snippet.run_instructions_override
  assert instructions.build_commands == ["npm install", "npm run build"]
  assert instructions.run_command == "node dist/main.js"
  assert has_settings_save(editor_scenario.observed(scenario))
  assert has_draft_save(editor_scenario.observed(scenario))

  let scenario =
    editor_scenario.dispatch_execution(scenario, message.RunSubmitted)
  let assert [editor_scenario.RunCode(request, _)] =
    editor_scenario.pending(scenario)
  assert request.payload.run_instructions == instructions
}

pub fn cancelling_settings_discards_drafts_without_storage_writes_test() {
  let scenario =
    new_scenario()
    |> editor_scenario.dispatch_settings(message.SettingsClicked)
    |> editor_scenario.dispatch_settings(message.KeyboardBindingsDraftSelected(
      settings.EmacsBindings,
    ))
    |> editor_scenario.dispatch_settings(
      message.RunInstructionsModeDraftChanged("custom"),
    )
    |> editor_scenario.dispatch_settings(
      message.RunInstructionsRunCommandDraftChanged("discarded"),
    )
    |> editor_scenario.dispatch_settings(message.SettingsCancelled)
  let editor = editor_scenario.editor(scenario)
  assert editor.editor_settings == settings.defaults()
  assert editor.settings_draft.editor_settings == settings.defaults()
  assert editor.snippet.run_instructions_override == option.None
  assert !has_settings_save(editor_scenario.observed(scenario))
  assert !has_draft_save(editor_scenario.observed(scenario))

  let scenario =
    editor_scenario.dispatch_settings(scenario, message.SettingsClicked)
    |> editor_scenario.dispatch_settings(message.SettingsDialogClosed)
  assert list.contains(
    editor_scenario.observed(scenario),
    editor_scenario.ElementFocused("editor-page-codemirror"),
  )
}

pub fn switching_custom_instructions_back_to_default_restores_language_defaults_test() {
  let scenario =
    new_scenario()
    |> editor_scenario.dispatch_settings(message.SettingsClicked)
    |> editor_scenario.dispatch_settings(
      message.RunInstructionsModeDraftChanged("custom"),
    )
    |> editor_scenario.dispatch_settings(
      message.RunInstructionsRunCommandDraftChanged("custom"),
    )
    |> editor_scenario.dispatch_settings(message.SettingsSubmitted)
    |> editor_scenario.dispatch_settings(message.SettingsClicked)
    |> editor_scenario.dispatch_settings(
      message.RunInstructionsModeDraftChanged("default"),
    )
    |> editor_scenario.dispatch_settings(message.SettingsSubmitted)
  let editor = editor_scenario.editor(scenario)
  assert editor.snippet.run_instructions_override == option.None
  let scenario =
    editor_scenario.dispatch_execution(scenario, message.RunSubmitted)
  let assert [editor_scenario.RunCode(request, _)] =
    editor_scenario.pending(scenario)
  assert request.payload.run_instructions.run_command == "node main.js"
}

pub fn snippet_information_dialog_renders_existing_snippet_metadata_test() {
  let base = editor_scenario.new_editor(language.JavaScript)
  let assert model.Ready(editor) = base
  let existing =
    model.Ready(
      model.Editor(
        ..editor,
        snippet: model.Snippet(
          ..editor.snippet,
          slug: option.Some("info-fixture"),
          owner_user_id: option.Some(editor_fixture.owner_id()),
          owner_username: option.Some("fixture-owner"),
          title: "Information title",
          visibility: snippet_model.Public,
          created_at: option.Some(timestamp.from_unix_seconds(100)),
          updated_at: option.Some(timestamp.from_unix_seconds(200)),
        ),
      ),
    )
  let scenario =
    editor_scenario.start(existing, option.Some(editor_fixture.owner_id()))
    |> editor_scenario.dispatch_snippet_info(message.SnippetInfoClicked)
  let rendered = render(scenario)
  assert string.contains(rendered, "Snippet info")
  assert string.contains(rendered, "Information title")
  assert string.contains(rendered, "fixture-owner")
  assert string.contains(rendered, "https://glot.io/snippets/info-fixture")

  let dismissed =
    editor_scenario.dispatch_snippet_info(
      scenario,
      message.SnippetInfoDismissed,
    )
  assert list.contains(
    editor_scenario.observed(dismissed),
    editor_scenario.DialogClosed("editor-page-snippet-info-dialog"),
  )
  let closed =
    editor_scenario.dispatch_snippet_info(dismissed, message.SnippetInfoClosed)
  assert list.contains(
    editor_scenario.observed(closed),
    editor_scenario.ElementFocused("editor-page-codemirror"),
  )
}

fn new_scenario() -> editor_scenario.Scenario {
  editor_scenario.new_editor(language.JavaScript)
  |> editor_scenario.start(option.Some(editor_fixture.owner_id()))
}

fn add_file(scenario: editor_scenario.Scenario, name: String) {
  scenario
  |> editor_scenario.dispatch_file(message.AddEntryClicked)
  |> editor_scenario.dispatch_file(message.AddEntryFilenameChanged(name))
  |> editor_scenario.dispatch_file(message.AddEntrySubmitted)
}

fn render(scenario: editor_scenario.Scenario) -> String {
  view.view(
    editor_scenario.model(scenario),
    option.Some(editor_fixture.owner_id()),
    timestamp.from_unix_seconds(300),
  )
  |> element.to_document_string
}

fn has_draft_save(effects: List(editor_scenario.ObservedEffect)) -> Bool {
  list.any(effects, fn(effect) {
    case effect {
      editor_scenario.DraftSaved(_) -> True
      _ -> False
    }
  })
}

fn has_settings_save(effects: List(editor_scenario.ObservedEffect)) -> Bool {
  list.any(effects, fn(effect) {
    case effect {
      editor_scenario.SettingsSaved(_) -> True
      _ -> False
    }
  })
}

import gleam/list
import gleam/option
import gleam/string
import gleam/time/timestamp
import glot_core/language
import glot_core/snippet/snippet_model
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
    |> editor_scenario.dispatch(message.AddEntryClicked)
    |> editor_scenario.dispatch(message.AddEntryFilenameChanged("helper.js"))
    |> editor_scenario.dispatch(message.AddEntrySubmitted)
    |> editor_scenario.dispatch(message.SourceCodeChanged(
      "export const answer = 42",
      1,
    ))
  let assert model.SupportedLanguage(editor) = editor_scenario.model(scenario)
  assert editor.files
    == [
      snippet_model.File("main.js", "console.log(\"Hello World!\");"),
      snippet_model.File("helper.js", "export const answer = 42"),
    ]
  assert editor.selected_tab == model.FileTab(1)
  assert string.contains(render(scenario), "helper.js")

  let scenario = editor_scenario.dispatch(scenario, message.RunSubmitted)
  let assert [editor_scenario.RunCode(request, _)] =
    editor_scenario.pending(scenario)
  assert request.payload.files == editor.files
}

pub fn duplicate_and_invalid_filenames_are_rejected_without_draft_effects_test() {
  let invalid =
    new_scenario()
    |> editor_scenario.dispatch(message.AddEntryClicked)
    |> editor_scenario.dispatch(message.AddEntrySubmitted)
  let assert model.SupportedLanguage(invalid_editor) =
    editor_scenario.model(invalid)
  assert list.length(invalid_editor.files) == 1
  assert !has_draft_save(editor_scenario.observed(invalid))

  let duplicate =
    invalid
    |> editor_scenario.dispatch(message.AddEntryFilenameChanged("main.js"))
    |> editor_scenario.dispatch(message.AddEntrySubmitted)
  let assert model.SupportedLanguage(duplicate_editor) =
    editor_scenario.model(duplicate)
  assert list.length(duplicate_editor.files) == 1
  assert string.contains(render(duplicate), "disabled type=\"submit\">Add")
}

pub fn add_dialog_cancel_and_close_reset_draft_and_restore_focus_test() {
  let cancelled =
    new_scenario()
    |> editor_scenario.dispatch(message.AddEntryClicked)
    |> editor_scenario.dispatch(message.AddEntryFilenameChanged("discarded.js"))
    |> editor_scenario.dispatch(message.AddEntryCancelled)
  let assert model.SupportedLanguage(cancelled_editor) =
    editor_scenario.model(cancelled)
  assert cancelled_editor.add_entry_filename == ""
  assert list.contains(
    editor_scenario.observed(cancelled),
    editor_scenario.DialogClosed("editor-page-add-entry-dialog"),
  )

  let closed =
    cancelled
    |> editor_scenario.dispatch(message.AddEntryClicked)
    |> editor_scenario.dispatch(message.AddEntryFilenameChanged(
      "also-discarded.js",
    ))
    |> editor_scenario.dispatch(message.AddEntryDialogClosed)
  let assert model.SupportedLanguage(closed_editor) =
    editor_scenario.model(closed)
  assert closed_editor.add_entry_filename == ""
  assert list.contains(
    editor_scenario.observed(closed),
    editor_scenario.ElementFocused("editor-page-codemirror"),
  )
}

pub fn rename_and_delete_workflow_keeps_selection_and_run_payload_consistent_test() {
  let scenario =
    new_scenario()
    |> add_file("second.js")
    |> editor_scenario.dispatch(message.SelectedTabActionClicked)
    |> editor_scenario.dispatch(message.EditEntryFilenameChanged("renamed.js"))
    |> editor_scenario.dispatch(message.EditEntrySubmitted)
  let assert model.SupportedLanguage(renamed) = editor_scenario.model(scenario)
  assert renamed.files
    == [
      snippet_model.File("main.js", "console.log(\"Hello World!\");"),
      snippet_model.File("renamed.js", ""),
    ]

  let scenario =
    editor_scenario.dispatch(scenario, message.SelectedTabActionClicked)
    |> editor_scenario.dispatch(message.EditEntryDeleted)
  let assert model.SupportedLanguage(deleted) = editor_scenario.model(scenario)
  assert deleted.files
    == [snippet_model.File("main.js", "console.log(\"Hello World!\");")]
  assert deleted.selected_tab == model.FileTab(0)
  let scenario = editor_scenario.dispatch(scenario, message.RunSubmitted)
  let assert [editor_scenario.RunCode(request, _)] =
    editor_scenario.pending(scenario)
  assert request.payload.files == deleted.files
}

pub fn deleting_the_only_file_through_the_dialog_leaves_editor_unchanged_test() {
  let scenario =
    new_scenario()
    |> editor_scenario.dispatch(message.SelectedTabActionClicked)
  let before = editor_scenario.model(scenario)
  let scenario = editor_scenario.dispatch(scenario, message.EditEntryDeleted)
  assert editor_scenario.model(scenario) == before
  assert !has_draft_save(editor_scenario.observed(scenario))
  assert !string.contains(render(scenario), "Delete file")
}

pub fn edit_dialog_cancel_and_close_restore_filename_and_editor_focus_test() {
  let scenario =
    new_scenario()
    |> add_file("second.js")
    |> editor_scenario.dispatch(message.SelectedTabActionClicked)
    |> editor_scenario.dispatch(message.EditEntryFilenameChanged("discarded.js"))
    |> editor_scenario.dispatch(message.EditEntryCancelled)
  let assert model.SupportedLanguage(cancelled) =
    editor_scenario.model(scenario)
  assert cancelled.edit_entry_filename == "second.js"
  assert list.contains(
    editor_scenario.observed(scenario),
    editor_scenario.DialogClosed("editor-page-edit-entry-dialog"),
  )

  let scenario =
    editor_scenario.dispatch(scenario, message.SelectedTabActionClicked)
    |> editor_scenario.dispatch(message.EditEntryFilenameChanged(
      "also-discarded.js",
    ))
    |> editor_scenario.dispatch(message.EditEntryDialogClosed)
  let assert model.SupportedLanguage(closed) = editor_scenario.model(scenario)
  assert closed.edit_entry_filename == "second.js"
  assert list.contains(
    editor_scenario.observed(scenario),
    editor_scenario.ElementFocused("editor-page-codemirror"),
  )
}

pub fn stdin_can_be_added_edited_executed_and_removed_test() {
  let scenario =
    new_scenario()
    |> editor_scenario.dispatch(message.AddEntryClicked)
    |> editor_scenario.dispatch(message.AddEntryKindSelected(
      model.AddStdinEntry,
    ))
    |> editor_scenario.dispatch(message.AddEntrySubmitted)
    |> editor_scenario.dispatch(message.SourceCodeChanged("fixture input", 1))
  let assert model.SupportedLanguage(with_stdin) =
    editor_scenario.model(scenario)
  assert with_stdin.stdin == option.Some("fixture input")
  assert with_stdin.selected_tab == model.StdinTab

  let scenario = editor_scenario.dispatch(scenario, message.RunSubmitted)
  let assert [editor_scenario.RunCode(request, _)] =
    editor_scenario.pending(scenario)
  assert request.payload.stdin == option.Some("fixture input")
  let scenario =
    editor_scenario.respond_to_run(
      scenario,
      editor_fixture.successful_run(stdout: "ok", stderr: "", error: ""),
    )
    |> editor_scenario.dispatch(message.SelectedTabActionClicked)
    |> editor_scenario.dispatch(message.EditEntryDeleted)
  let assert model.SupportedLanguage(without_stdin) =
    editor_scenario.model(scenario)
  assert without_stdin.stdin == option.None
  assert without_stdin.selected_tab == model.FileTab(0)
}

pub fn switching_tabs_updates_rendered_document_and_external_revision_test() {
  let scenario = new_scenario() |> add_file("empty.js")
  let assert model.SupportedLanguage(before) = editor_scenario.model(scenario)
  let scenario =
    editor_scenario.dispatch(scenario, message.TabSelected(model.FileTab(0)))
  let assert model.SupportedLanguage(after) = editor_scenario.model(scenario)
  assert after.editor_external_revision == before.editor_external_revision + 1
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
    |> editor_scenario.dispatch(message.EditMetadataClicked)
    |> editor_scenario.dispatch(message.TitleDraftChanged("New title"))
    |> editor_scenario.dispatch(message.EditMetadataVisibilitySelected(
      snippet_model.Public,
    ))
    |> editor_scenario.dispatch(message.EditMetadataSubmitted)
  let assert model.SupportedLanguage(editor) = editor_scenario.model(scenario)
  assert editor.title == "New title"
  assert editor.visibility == snippet_model.Public
  assert has_draft_save(editor_scenario.observed(scenario))
  assert string.contains(render(scenario), ">New title</h1>")
}

pub fn metadata_visibility_is_only_shown_for_existing_snippets_test() {
  let assert model.SupportedLanguage(new_editor) =
    editor_scenario.new_editor(language.JavaScript)
  let new_dialog =
    metadata_dialog_view.view(new_editor)
    |> element.to_document_string
  assert !string.contains(new_dialog, "aria-label=\"Visibility\"")

  let existing_dialog =
    metadata_dialog_view.view(
      model.RealModel(..new_editor, slug: option.Some("visibility-fixture")),
    )
    |> element.to_document_string
  assert string.contains(existing_dialog, "aria-label=\"Visibility\"")
}

pub fn metadata_cancel_and_close_restore_drafts_and_focus_editor_test() {
  let scenario =
    new_scenario()
    |> editor_scenario.dispatch(message.EditMetadataClicked)
    |> editor_scenario.dispatch(message.TitleDraftChanged("Discarded"))
    |> editor_scenario.dispatch(message.EditMetadataVisibilitySelected(
      snippet_model.Public,
    ))
    |> editor_scenario.dispatch(message.EditMetadataCancelled)
  let assert model.SupportedLanguage(cancelled) =
    editor_scenario.model(scenario)
  assert cancelled.title_draft == cancelled.title
  assert cancelled.save_visibility_draft == cancelled.visibility
  assert !has_draft_save(editor_scenario.observed(scenario))

  let scenario =
    editor_scenario.dispatch(scenario, message.EditMetadataClicked)
    |> editor_scenario.dispatch(message.TitleDraftChanged("Also discarded"))
    |> editor_scenario.dispatch(message.EditMetadataDialogClosed)
  let assert model.SupportedLanguage(closed) = editor_scenario.model(scenario)
  assert closed.title_draft == closed.title
  assert list.contains(
    editor_scenario.observed(scenario),
    editor_scenario.ElementFocused("editor-page-codemirror"),
  )
}

pub fn custom_run_instructions_and_keyboard_settings_drive_execution_test() {
  let scenario =
    new_scenario()
    |> editor_scenario.dispatch(message.SettingsClicked)
    |> editor_scenario.dispatch(message.KeyboardBindingsDraftSelected(
      settings.VimBindings,
    ))
    |> editor_scenario.dispatch(message.RunInstructionsModeDraftChanged(
      "custom",
    ))
    |> editor_scenario.dispatch(
      message.RunInstructionsBuildCommandsDraftChanged(
        " npm install \n\n npm run build ",
      ),
    )
    |> editor_scenario.dispatch(message.RunInstructionsRunCommandDraftChanged(
      " node dist/main.js ",
    ))
    |> editor_scenario.dispatch(message.SettingsSubmitted)
  let assert model.SupportedLanguage(editor) = editor_scenario.model(scenario)
  assert editor.editor_settings.keyboard_bindings == settings.VimBindings
  let assert option.Some(instructions) = editor.run_instructions_override
  assert instructions.build_commands == ["npm install", "npm run build"]
  assert instructions.run_command == "node dist/main.js"
  assert has_settings_save(editor_scenario.observed(scenario))
  assert has_draft_save(editor_scenario.observed(scenario))

  let scenario = editor_scenario.dispatch(scenario, message.RunSubmitted)
  let assert [editor_scenario.RunCode(request, _)] =
    editor_scenario.pending(scenario)
  assert request.payload.run_instructions == instructions
}

pub fn cancelling_settings_discards_drafts_without_storage_writes_test() {
  let scenario =
    new_scenario()
    |> editor_scenario.dispatch(message.SettingsClicked)
    |> editor_scenario.dispatch(message.KeyboardBindingsDraftSelected(
      settings.EmacsBindings,
    ))
    |> editor_scenario.dispatch(message.RunInstructionsModeDraftChanged(
      "custom",
    ))
    |> editor_scenario.dispatch(message.RunInstructionsRunCommandDraftChanged(
      "discarded",
    ))
    |> editor_scenario.dispatch(message.SettingsCancelled)
  let assert model.SupportedLanguage(editor) = editor_scenario.model(scenario)
  assert editor.editor_settings == settings.defaults()
  assert editor.editor_settings_draft == settings.defaults()
  assert editor.run_instructions_override == option.None
  assert !has_settings_save(editor_scenario.observed(scenario))
  assert !has_draft_save(editor_scenario.observed(scenario))

  let scenario =
    editor_scenario.dispatch(scenario, message.SettingsClicked)
    |> editor_scenario.dispatch(message.SettingsDialogClosed)
  assert list.contains(
    editor_scenario.observed(scenario),
    editor_scenario.ElementFocused("editor-page-codemirror"),
  )
}

pub fn switching_custom_instructions_back_to_default_restores_language_defaults_test() {
  let scenario =
    new_scenario()
    |> editor_scenario.dispatch(message.SettingsClicked)
    |> editor_scenario.dispatch(message.RunInstructionsModeDraftChanged(
      "custom",
    ))
    |> editor_scenario.dispatch(message.RunInstructionsRunCommandDraftChanged(
      "custom",
    ))
    |> editor_scenario.dispatch(message.SettingsSubmitted)
    |> editor_scenario.dispatch(message.SettingsClicked)
    |> editor_scenario.dispatch(message.RunInstructionsModeDraftChanged(
      "default",
    ))
    |> editor_scenario.dispatch(message.SettingsSubmitted)
  let assert model.SupportedLanguage(editor) = editor_scenario.model(scenario)
  assert editor.run_instructions_override == option.None
  let scenario = editor_scenario.dispatch(scenario, message.RunSubmitted)
  let assert [editor_scenario.RunCode(request, _)] =
    editor_scenario.pending(scenario)
  assert request.payload.run_instructions.run_command == "node main.js"
}

pub fn snippet_information_dialog_renders_existing_snippet_metadata_test() {
  let base = editor_scenario.new_editor(language.JavaScript)
  let assert model.SupportedLanguage(editor) = base
  let existing =
    model.SupportedLanguage(
      model.RealModel(
        ..editor,
        slug: option.Some("info-fixture"),
        owner_user_id: option.Some(editor_fixture.owner_id()),
        owner_username: option.Some("fixture-owner"),
        title: "Information title",
        visibility: snippet_model.Public,
        created_at: option.Some(timestamp.from_unix_seconds(100)),
        updated_at: option.Some(timestamp.from_unix_seconds(200)),
      ),
    )
  let scenario =
    editor_scenario.start(existing, option.Some(editor_fixture.owner_id()))
    |> editor_scenario.dispatch(message.SnippetInfoClicked)
  let rendered = render(scenario)
  assert string.contains(rendered, "Snippet info")
  assert string.contains(rendered, "Information title")
  assert string.contains(rendered, "fixture-owner")
  assert string.contains(rendered, "https://glot.io/snippets/info-fixture")

  let dismissed =
    editor_scenario.dispatch(scenario, message.SnippetInfoDismissed)
  assert list.contains(
    editor_scenario.observed(dismissed),
    editor_scenario.DialogClosed("editor-page-snippet-info-dialog"),
  )
  let closed = editor_scenario.dispatch(dismissed, message.SnippetInfoClosed)
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
  |> editor_scenario.dispatch(message.AddEntryClicked)
  |> editor_scenario.dispatch(message.AddEntryFilenameChanged(name))
  |> editor_scenario.dispatch(message.AddEntrySubmitted)
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

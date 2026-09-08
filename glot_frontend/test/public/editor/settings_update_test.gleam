import gleam/option
import glot_core/language
import glot_frontend/public/editor/environment
import glot_frontend/public/editor/command
import glot_frontend/public/editor/draft_projection
import glot_frontend/public/editor/message
import glot_frontend/public/editor/model
import glot_frontend/public/editor/ready
import glot_frontend/public/editor/settings
import glot_frontend/public/editor/settings_draft
import glot_frontend/public/editor/settings_update

pub fn opening_synchronizes_the_draft_from_authoritative_settings_test() {
  let custom = language.RunInstructions(["npm build"], "node dist.js")
  let base =
    ready.new(
      language.JavaScript,
      environment.Environment(
        settings: settings.EditorSettings(settings.VimBindings),
        mac: False,
      ),
    )
  let editor =
    model.Editor(
      ..base,
      snippet: model.Snippet(
        ..base.snippet,
        run_instructions_override: option.Some(custom),
      ),
      settings_draft: model.SettingsDraft(
        settings.EditorSettings(settings.EmacsBindings),
        model.DefaultRunInstructions,
        model.RunInstructionsDraft("stale", "stale"),
      ),
    )
  let #(opened, next_command) =
    settings_update.update(editor, message.SettingsClicked)

  assert opened.settings_draft == settings_draft.from_editor(editor)
  assert opened.settings_draft.editor_settings
    == settings.EditorSettings(settings.VimBindings)
  assert opened.settings_draft.run_instructions_mode
    == model.CustomRunInstructions
  assert opened.settings_draft.run_instructions
    == model.RunInstructionsDraft("npm build", "node dist.js")
  assert next_command == command.OpenDialog("editor-page-settings-dialog")
}

pub fn draft_messages_update_only_the_selected_setting_test() {
  let editor = ready.new(language.JavaScript, environment.defaults())
  let #(bindings, bindings_command) =
    settings_update.update(
      editor,
      message.KeyboardBindingsDraftSelected(settings.EmacsBindings),
    )
  assert bindings.settings_draft.editor_settings
    == settings.EditorSettings(settings.EmacsBindings)
  assert bindings.settings_draft.run_instructions
    == editor.settings_draft.run_instructions
  assert bindings_command == command.None

  let #(mode, mode_command) =
    settings_update.update(
      bindings,
      message.RunInstructionsModeDraftChanged("custom"),
    )
  assert mode.settings_draft.run_instructions_mode
    == model.CustomRunInstructions
  assert mode.settings_draft.editor_settings
    == bindings.settings_draft.editor_settings
  assert mode_command == command.None

  let #(build, build_command) =
    settings_update.update(
      mode,
      message.RunInstructionsBuildCommandsDraftChanged("npm build"),
    )
  assert build.settings_draft.run_instructions.build_commands_text
    == "npm build"
  assert build.settings_draft.run_instructions.run_command
    == mode.settings_draft.run_instructions.run_command
  assert build_command == command.None

  let #(run, run_command) =
    settings_update.update(
      build,
      message.RunInstructionsRunCommandDraftChanged("node dist.js"),
    )
  assert run.settings_draft.run_instructions.build_commands_text == "npm build"
  assert run.settings_draft.run_instructions.run_command == "node dist.js"
  assert run_command == command.None
}

pub fn submitting_commits_settings_and_persists_both_projections_test() {
  let base = ready.new(language.JavaScript, environment.defaults())
  let editor =
    model.Editor(
      ..base,
      settings_draft: model.SettingsDraft(
        settings.EditorSettings(settings.VimBindings),
        model.CustomRunInstructions,
        model.RunInstructionsDraft(" npm build ", " node dist.js "),
      ),
    )
  let #(submitted, next_command) =
    settings_update.update(editor, message.SettingsSubmitted)

  assert submitted.editor_settings
    == settings.EditorSettings(settings.VimBindings)
  assert submitted.snippet.run_instructions_override
    == option.Some(language.RunInstructions(["npm build"], "node dist.js"))
  assert next_command
    == command.Batch([
      command.CloseDialog("editor-page-settings-dialog"),
      command.SaveSettings(settings.EditorSettings(settings.VimBindings)),
      command.SaveDraft(draft_projection.write(submitted)),
    ])
}

pub fn submitting_default_mode_removes_the_custom_override_test() {
  let custom = language.RunInstructions([], "custom")
  let base = ready.new(language.JavaScript, environment.defaults())
  let editor =
    model.Editor(
      ..base,
      snippet: model.Snippet(
        ..base.snippet,
        run_instructions_override: option.Some(custom),
      ),
      settings_draft: model.SettingsDraft(
        ..base.settings_draft,
        run_instructions_mode: model.DefaultRunInstructions,
      ),
    )
  let #(submitted, _) =
    settings_update.update(editor, message.SettingsSubmitted)

  assert submitted.snippet.run_instructions_override == option.None
}

pub fn cancel_and_close_resynchronize_with_distinct_browser_effects_test() {
  let base =
    ready.new(
      language.JavaScript,
      environment.Environment(
        settings: settings.EditorSettings(settings.VimBindings),
        mac: False,
      ),
    )
  let stale =
    model.Editor(
      ..base,
      settings_draft: model.SettingsDraft(
        settings.EditorSettings(settings.EmacsBindings),
        model.CustomRunInstructions,
        model.RunInstructionsDraft("stale", "stale"),
      ),
    )
  let #(cancelled, cancel_command) =
    settings_update.update(stale, message.SettingsCancelled)
  assert cancelled.settings_draft == settings_draft.from_editor(stale)
  assert cancel_command == command.CloseDialog("editor-page-settings-dialog")

  let #(closed, close_command) =
    settings_update.update(stale, message.SettingsDialogClosed)
  assert closed.settings_draft == settings_draft.from_editor(stale)
  assert close_command == command.Focus("code-editor-input")
}

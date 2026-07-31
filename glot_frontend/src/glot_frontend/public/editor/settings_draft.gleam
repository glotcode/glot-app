import gleam/option
import glot_core/language
import glot_core/snippet/snippet_model
import glot_frontend/public/editor/model.{
  type Editor, type SettingsDraft, SettingsDraft,
}
import glot_frontend/public/editor/run_instructions
import glot_frontend/public/editor/settings

/// Build the editable settings projection from authoritative editor values.
/// Opening, cancelling, and closing the dialog all synchronize through this
/// function so stale draft values cannot leak between dialog sessions.
pub fn new(
  editor_settings: settings.EditorSettings,
  language: language.Language,
  files: List(snippet_model.File),
  run_instructions_override: option.Option(language.RunInstructions),
) -> SettingsDraft {
  let effective_run_instructions = case run_instructions_override {
    option.Some(instructions) -> instructions
    option.None -> run_instructions.default_run_instructions(language, files)
  }

  SettingsDraft(
    editor_settings: editor_settings,
    run_instructions_mode: run_instructions.run_instructions_mode_from_override(
      run_instructions_override,
    ),
    run_instructions: run_instructions.run_instructions_to_draft(
      effective_run_instructions,
    ),
  )
}

pub fn from_editor(editor: Editor) -> SettingsDraft {
  new(
    editor.editor_settings,
    editor.snippet.language,
    editor.snippet.files,
    editor.snippet.run_instructions_override,
  )
}

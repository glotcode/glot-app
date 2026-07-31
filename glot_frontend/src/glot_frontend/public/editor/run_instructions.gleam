import gleam/list
import gleam/option
import gleam/string
import glot_core/language
import glot_core/run
import glot_core/snippet/snippet_model
import glot_frontend/public/editor/command
import glot_frontend/public/editor/files as editor_files
import glot_frontend/public/editor/message.{
  type ExecutionMsg, VersionRunFinished,
}
import glot_frontend/public/editor/model.{
  type Editor, type RunInstructionsDraft, type RunInstructionsMode,
  CustomRunInstructions, DefaultRunInstructions, RunInstructionsDraft,
}

pub fn run_instructions_to_draft(
  run_instructions: language.RunInstructions,
) -> RunInstructionsDraft {
  RunInstructionsDraft(
    build_commands_text: string.join(
      run_instructions.build_commands,
      with: "\n",
    ),
    run_command: run_instructions.run_command,
  )
}

pub fn run_instructions_mode(model: Editor) -> RunInstructionsMode {
  run_instructions_mode_from_override(model.snippet.run_instructions_override)
}

pub fn run_instructions_mode_from_override(
  override: option.Option(language.RunInstructions),
) -> RunInstructionsMode {
  case override {
    option.Some(_) -> CustomRunInstructions
    option.None -> DefaultRunInstructions
  }
}

pub fn run_instructions_mode_from_string(value: String) -> RunInstructionsMode {
  case value {
    "custom" -> CustomRunInstructions
    _ -> DefaultRunInstructions
  }
}

pub fn run_instructions_mode_to_string(mode: RunInstructionsMode) -> String {
  case mode {
    DefaultRunInstructions -> "default"
    CustomRunInstructions -> "custom"
  }
}

pub fn run_instructions_from_draft(
  draft: RunInstructionsDraft,
) -> language.RunInstructions {
  language.RunInstructions(
    build_commands: draft.build_commands_text
      |> string.split("\n")
      |> list.map(string.trim)
      |> list.filter(fn(command) { command != "" }),
    run_command: string.trim(draft.run_command),
  )
}

pub fn default_run_instructions(
  lang: language.Language,
  files: List(snippet_model.File),
) -> language.RunInstructions {
  let default_name = language.default_filename(lang)
  let main_file = editor_files.select_main_name(files, default_name)
  let other_files =
    files
    |> list.map(fn(file) { file.name })
    |> editor_files.remove_first_name(main_file)

  language.run_instructions(lang, main_file, other_files)
}

pub fn effective_run_instructions(model: Editor) -> language.RunInstructions {
  case model.snippet.run_instructions_override {
    option.Some(run_instructions) -> run_instructions
    option.None ->
      default_run_instructions(model.snippet.language, model.snippet.files)
  }
}

pub fn run_instructions_override_from_draft(
  model: Editor,
) -> option.Option(language.RunInstructions) {
  case model.settings_draft.run_instructions_mode {
    DefaultRunInstructions -> option.None
    CustomRunInstructions ->
      option.Some(run_instructions_from_draft(
        model.settings_draft.run_instructions,
      ))
  }
}

pub fn version_run_command(
  lang: language.Language,
) -> command.Command(ExecutionMsg) {
  command.GetLanguageVersion(
    run.GetLanguageVersionRequest(language: lang),
    fn(result) { VersionRunFinished(lang, result) },
  )
}

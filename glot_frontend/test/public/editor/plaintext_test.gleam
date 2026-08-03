import glot_core/language
import glot_frontend/public/editor/command
import glot_frontend/public/editor/run_instructions

pub fn plaintext_does_not_request_a_language_version_test() {
  let assert command.None =
    run_instructions.version_run_command(language.Plaintext)
  Nil
}

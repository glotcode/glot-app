import gleam/option.{type Option}
import glot_backend/run_code/effect/algebra
import glot_backend/run_code/model/config.{type DockerRunConfig}
import glot_backend/system/effect/error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types
import glot_core/language.{type Language}
import glot_core/run

pub fn run_code(
  config: Option(DockerRunConfig),
  request: run.RunRequest,
) -> program_types.Program(run.RunResult) {
  program.perform(
    program_types.RunCodeEffect(
      algebra.RunCode(config, request, program.from_mapped_result(
        _,
        map_error: error.run_request_error,
      )),
    ),
  )
}

pub fn get_language_version(
  config: Option(DockerRunConfig),
  language: Language,
) -> program_types.Program(run.RunResult) {
  program.perform(
    program_types.RunCodeEffect(
      algebra.GetLanguageVersion(config, language, program.from_mapped_result(
        _,
        map_error: error.run_request_error,
      )),
    ),
  )
}

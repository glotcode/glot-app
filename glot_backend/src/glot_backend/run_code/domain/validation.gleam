import gleam/result
import glot_backend/system/effect/error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_core/language.{type Language}
import glot_core/run.{type RunRequest}

pub fn require_valid_request(request: RunRequest) -> Program(Language) {
  request
  |> run.validate_request
  |> result.map_error(error.validation)
  |> program.from_result
}

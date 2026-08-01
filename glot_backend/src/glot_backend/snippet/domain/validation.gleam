import gleam/result
import glot_backend/system/effect/error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_core/snippet/snippet_dto.{type SnippetData}
import glot_core/snippet/snippet_model
import glot_core/snippet/snippet_spam

pub fn require_valid_fields(data: SnippetData) -> Program(Nil) {
  validate_fields(data)
  |> program.from_result
}

fn validate_fields(data: SnippetData) -> Result(Nil, error.Error) {
  snippet_model.validate_fields(
    data.title,
    data.stdin,
    data.run_instructions,
    data.files,
  )
  |> result.map_error(error.validation)
}

pub fn require_clean(data: SnippetData) -> Program(Nil) {
  ensure_clean(data)
  |> program.from_result
}

fn ensure_clean(data: SnippetData) -> Result(Nil, error.Error) {
  data
  |> snippet_spam.ensure_clean
  |> result.map_error(error.validation)
}

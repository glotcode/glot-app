import gleam/result
import glot_backend/system/effect/error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{
  type Program, type TransactionProgram,
}
import glot_backend/system/effect/transaction/transaction_program
import glot_core/language
import glot_core/snippet/snippet_dto.{type SnippetData}
import glot_core/snippet/snippet_model.{type HydratedSnippet}
import glot_core/snippet/snippet_spam
import glot_core/validation_error

pub fn require_valid_fields(data: SnippetData) -> Program(Nil) {
  validate_fields(data)
  |> program.from_result
}

fn validate_fields(data: SnippetData) -> Result(Nil, error.Error) {
  use _ <- result.try(require_writable_language(data.language))
  snippet_model.validate_fields(
    data.title,
    data.stdin,
    data.run_instructions,
    data.files,
  )
  |> result.map_error(error.validation)
}

fn require_writable_language(
  language_value: language.Language,
) -> Result(Nil, error.Error) {
  case language.is_writable(language_value) {
    True -> Ok(Nil)
    False ->
      Error(
        error.validation(
          validation_error.ReadOnlyLanguage(language.to_string(language_value)),
        ),
      )
  }
}

pub fn require_writable_snippet(snippet: HydratedSnippet) -> Program(Nil) {
  require_writable_language(snippet.identity.language)
  |> program.from_result
}

pub fn require_writable_snippet_tx(
  snippet: HydratedSnippet,
) -> TransactionProgram(Nil) {
  require_writable_language(snippet.identity.language)
  |> transaction_program.from_result
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

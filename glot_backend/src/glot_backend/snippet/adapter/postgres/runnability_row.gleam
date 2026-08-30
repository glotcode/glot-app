import gleam/dynamic/decode
import gleam/json
import gleam/option
import gleam/result
import gleam/string
import glot_backend/sql
import glot_backend/system/effect/error/db_error
import glot_core/helpers/uuid_helpers
import glot_core/language
import glot_core/snippet/runnability
import glot_core/snippet/snippet_model

pub fn from_unchecked(
  row: sql.GetNewestUncheckedSnippetRunnability,
) -> Result(runnability.Candidate, db_error.DbQueryError) {
  use snippet_language <- result.try(
    language.from_string(row.language)
    |> option.to_result(db_error.DbQueryError(
      "Invalid snippet language: " <> row.language,
    )),
  )
  use visibility <- result.try(
    snippet_model.visibility_from_string(row.visibility)
    |> option.to_result(db_error.DbQueryError(
      "Invalid snippet visibility: " <> row.visibility,
    )),
  )
  use files <- result.try(
    json.parse(row.files, decode.list(snippet_model.file_decoder()))
    |> result.map_error(fn(errors) {
      db_error.DbQueryError("Invalid snippet files: " <> string.inspect(errors))
    }),
  )
  use run_instructions <- result.try(decode_run_instructions(
    row.run_instructions,
  ))
  use attempts <- result.try(
    runnability.attempts_from_int(row.runnability_check_attempts)
    |> result.map_error(db_error.DbQueryError),
  )
  let snippet =
    snippet_model.Snippet(
      id: uuid_helpers.from_bit_array(row.id),
      slug: row.slug,
      user_id: uuid_helpers.from_bit_array(row.user_id),
      title: row.title,
      language: snippet_language,
      visibility: visibility,
      stdin: row.stdin,
      run_instructions: run_instructions,
      files: files,
      created_at: row.created_at,
      updated_at: row.updated_at,
    )
  Ok(runnability.Candidate(snippet, row.updated_at, attempts))
}

fn decode_run_instructions(
  value: option.Option(String),
) -> Result(option.Option(language.RunInstructions), db_error.DbQueryError) {
  case value {
    option.None -> Ok(option.None)
    option.Some(json_value) ->
      json.parse(json_value, language.run_instructions_decoder())
      |> result.map(option.Some)
      |> result.map_error(fn(errors) {
        db_error.DbQueryError(
          "Invalid snippet run instructions: " <> string.inspect(errors),
        )
      })
  }
}

import gleam/json
import gleam/option
import gleam/result
import gleam/string
import gleam/time/timestamp.{type Timestamp}
import glot_backend/sql
import glot_backend/system/database as db_helpers
import glot_backend/system/effect/error/db_error
import glot_core/language
import glot_core/snippet/snippet_model.{type Snippet}
import glot_core/snippet/spam_classification
import youid/uuid.{type Uuid}

pub fn create(
  db: db_helpers.Db,
  snippet: Snippet,
) -> Result(Nil, db_error.DbCommandError) {
  db_helpers.execute(
    db,
    sql.insert_snippet(
      id: uuid.to_bit_array(snippet.id),
      slug: snippet.slug,
      user_id: uuid.to_bit_array(snippet.user_id),
      language: language.to_string(snippet.language),
      title: snippet.title,
      visibility: snippet_model.visibility_to_string(snippet.visibility),
      stdin: snippet.stdin,
      run_instructions: encode_run_instructions(snippet),
      files: encode_files(snippet),
      created_at: snippet.created_at,
      updated_at: snippet.updated_at,
    ),
    command_error,
  )
  |> result.map(fn(_) { Nil })
}

pub fn update(
  db: db_helpers.Db,
  snippet: Snippet,
) -> Result(Nil, db_error.DbCommandError) {
  db_helpers.execute(
    db,
    sql.update_snippet(
      id: uuid.to_bit_array(snippet.id),
      slug: snippet.slug,
      user_id: uuid.to_bit_array(snippet.user_id),
      language: language.to_string(snippet.language),
      title: snippet.title,
      visibility: snippet_model.visibility_to_string(snippet.visibility),
      stdin: snippet.stdin,
      run_instructions: encode_run_instructions(snippet),
      files: encode_files(snippet),
      created_at: snippet.created_at,
      updated_at: snippet.updated_at,
    ),
    command_error,
  )
  |> result.map(fn(_) { Nil })
}

pub fn delete(
  db: db_helpers.Db,
  id: Uuid,
) -> Result(Nil, db_error.DbCommandError) {
  db_helpers.execute(
    db,
    sql.delete_snippet(uuid.to_bit_array(id)),
    command_error,
  )
  |> result.map(fn(_) { Nil })
}

pub fn store_spam_classification(
  db: db_helpers.Db,
  id: Uuid,
  expected_updated_at: Timestamp,
  classification: spam_classification.ClassificationResult,
) -> Result(Nil, db_error.DbCommandError) {
  db_helpers.execute(
    db,
    sql.store_spam_classification(
      option.Some(spam_classification.decision_to_string(
        classification.decision,
      )),
      option.Some(classification.confidence),
      option.Some(spam_classification.reason_code_to_string(
        classification.reason_code,
      )),
      option.Some(classification.classified_at),
      uuid.to_bit_array(id),
      expected_updated_at,
    ),
    command_error,
  )
  |> result.map(fn(_) { Nil })
}

pub fn store_spam_classification_failure(
  db: db_helpers.Db,
  id: Uuid,
  expected_updated_at: Timestamp,
  failure: spam_classification.ClassificationFailure,
) -> Result(Nil, db_error.DbCommandError) {
  db_helpers.execute(
    db,
    sql.store_spam_classification_failure(
      option.Some(failure.error_code),
      option.Some(failure.failed_at),
      uuid.to_bit_array(id),
      expected_updated_at,
    ),
    command_error,
  )
  |> result.map(fn(_) { Nil })
}

pub fn delete_by_account_id(
  db: db_helpers.Db,
  account_id: Uuid,
) -> Result(Nil, db_error.DbCommandError) {
  db_helpers.execute(
    db,
    sql.delete_snippets_by_account_id(uuid.to_bit_array(account_id)),
    command_error,
  )
  |> result.map(fn(_) { Nil })
}

fn encode_run_instructions(snippet: Snippet) -> option.Option(String) {
  snippet.run_instructions
  |> option.map(fn(run_instructions) {
    language.encode_run_instructions(run_instructions)
    |> json.to_string
  })
}

fn encode_files(snippet: Snippet) -> String {
  json.to_string(json.array(snippet.files, snippet_model.encode_file))
}

fn command_error(error) -> db_error.DbCommandError {
  db_error.DbCommandError(string.inspect(error))
}

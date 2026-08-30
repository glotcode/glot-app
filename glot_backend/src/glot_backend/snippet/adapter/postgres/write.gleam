import gleam/json
import gleam/option
import gleam/result
import gleam/string
import gleam/time/timestamp.{type Timestamp}
import glot_backend/sql
import glot_backend/system/database as db_helpers
import glot_backend/system/effect/error/db_error
import glot_core/language
import glot_core/snippet/runnability
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
) -> Result(spam_classification.StoreResult, db_error.DbCommandError) {
  use returned <- result.try(db_helpers.execute(
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
  ))
  classification_store_result(id, returned.count)
}

pub fn update_spam_classification(
  db: db_helpers.Db,
  id: Uuid,
  expected_updated_at: Timestamp,
  classification: spam_classification.ClassificationResult,
) -> Result(spam_classification.StoreResult, db_error.DbCommandError) {
  use returned <- result.try(db_helpers.execute(
    db,
    sql.update_spam_classification(
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
  ))
  classification_store_result(id, returned.count)
}

pub fn increment_spam_classification_attempts(
  db: db_helpers.Db,
  id: Uuid,
  expected_updated_at: Timestamp,
) -> Result(spam_classification.StoreResult, db_error.DbCommandError) {
  use returned <- result.try(db_helpers.execute(
    db,
    sql.increment_spam_classification_attempts(
      uuid.to_bit_array(id),
      expected_updated_at,
    ),
    command_error,
  ))
  classification_store_result(id, returned.count)
}

pub fn store_spam_classification_failure(
  db: db_helpers.Db,
  id: Uuid,
  expected_updated_at: Timestamp,
  failure: spam_classification.ClassificationFailure,
) -> Result(spam_classification.StoreResult, db_error.DbCommandError) {
  use returned <- result.try(db_helpers.execute(
    db,
    sql.store_spam_classification_failure(
      option.Some(failure.error_code),
      option.Some(failure.failed_at),
      uuid.to_bit_array(id),
      expected_updated_at,
    ),
    command_error,
  ))
  classification_store_result(id, returned.count)
}

pub fn classification_store_result(
  id: Uuid,
  affected_rows: Int,
) -> Result(spam_classification.StoreResult, db_error.DbCommandError) {
  case affected_rows {
    0 -> Ok(spam_classification.Stale)
    1 -> Ok(spam_classification.Stored)
    count ->
      Error(db_error.DbCommandError(
        "guarded spam classification update affected "
        <> string.inspect(count)
        <> " rows for snippet "
        <> uuid.to_string(id),
      ))
  }
}

pub fn increment_runnability_check_attempts(
  db: db_helpers.Db,
  id: Uuid,
  expected_updated_at: Timestamp,
) -> Result(runnability.StoreResult, db_error.DbCommandError) {
  use returned <- result.try(db_helpers.execute(
    db,
    sql.increment_snippet_runnability_check_attempts(
      uuid.to_bit_array(id),
      expected_updated_at,
    ),
    command_error,
  ))
  runnability_store_result(id, returned.count)
}

pub fn store_runnability(
  db: db_helpers.Db,
  id: Uuid,
  expected_updated_at: Timestamp,
  check_result: runnability.CheckResult,
) -> Result(runnability.StoreResult, db_error.DbCommandError) {
  use returned <- result.try(db_helpers.execute(
    db,
    sql.store_snippet_runnability(
      option.Some(check_result.is_runnable),
      option.Some(check_result.checked_at),
      uuid.to_bit_array(id),
      expected_updated_at,
    ),
    command_error,
  ))
  runnability_store_result(id, returned.count)
}

pub fn store_runnability_check_failure(
  db: db_helpers.Db,
  id: Uuid,
  expected_updated_at: Timestamp,
  failure: runnability.CheckFailure,
) -> Result(runnability.StoreResult, db_error.DbCommandError) {
  use returned <- result.try(db_helpers.execute(
    db,
    sql.store_snippet_runnability_check_failure(
      option.Some(failure.error_code),
      option.Some(failure.failed_at),
      uuid.to_bit_array(id),
      expected_updated_at,
    ),
    command_error,
  ))
  runnability_store_result(id, returned.count)
}

fn runnability_store_result(
  id: Uuid,
  affected_rows: Int,
) -> Result(runnability.StoreResult, db_error.DbCommandError) {
  case affected_rows {
    0 -> Ok(runnability.Stale)
    1 -> Ok(runnability.Stored)
    count ->
      Error(db_error.DbCommandError(
        "guarded runnability update affected "
        <> string.inspect(count)
        <> " rows for snippet "
        <> uuid.to_string(id),
      ))
  }
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

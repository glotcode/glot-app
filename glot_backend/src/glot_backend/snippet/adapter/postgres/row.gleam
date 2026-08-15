import gleam/dynamic/decode
import gleam/json
import gleam/option
import gleam/result
import gleam/string
import glot_backend/sql
import glot_backend/system/effect/error/db_error
import glot_core/auth/user_model
import glot_core/email/email_address_model
import glot_core/helpers/uuid_helpers
import glot_core/language
import glot_core/snippet/admin_snippet.{type AdminSnippet}
import glot_core/snippet/snippet_model.{type HydratedSnippet}
import glot_core/snippet/spam_classification

pub fn from_get_by_id(
  row: sql.GetSnippetById,
) -> Result(HydratedSnippet, db_error.DbQueryError) {
  from_fields(
    id: row.id,
    slug: row.slug,
    user_id: row.user_id,
    user_account_id: row.user_account_id,
    user_email: row.user_email,
    user_username: row.user_username,
    user_role: row.user_role,
    user_last_login_at: row.user_last_login_at,
    user_created_at: row.user_created_at,
    user_updated_at: row.user_updated_at,
    language_name: row.language,
    title: row.title,
    visibility_name: row.visibility,
    stdin: row.stdin,
    run_instructions: row.run_instructions,
    files: row.files,
    created_at: row.created_at,
    updated_at: row.updated_at,
  )
}

pub fn from_get_by_slug(
  row: sql.GetSnippetBySlug,
) -> Result(HydratedSnippet, db_error.DbQueryError) {
  from_fields(
    id: row.id,
    slug: row.slug,
    user_id: row.user_id,
    user_account_id: row.user_account_id,
    user_email: row.user_email,
    user_username: row.user_username,
    user_role: row.user_role,
    user_last_login_at: row.user_last_login_at,
    user_created_at: row.user_created_at,
    user_updated_at: row.user_updated_at,
    language_name: row.language,
    title: row.title,
    visibility_name: row.visibility,
    stdin: row.stdin,
    run_instructions: row.run_instructions,
    files: row.files,
    created_at: row.created_at,
    updated_at: row.updated_at,
  )
}

pub fn from_get_by_slug_for_update(
  row: sql.GetSnippetBySlugForUpdate,
) -> Result(HydratedSnippet, db_error.DbQueryError) {
  from_fields(
    id: row.id,
    slug: row.slug,
    user_id: row.user_id,
    user_account_id: row.user_account_id,
    user_email: row.user_email,
    user_username: row.user_username,
    user_role: row.user_role,
    user_last_login_at: row.user_last_login_at,
    user_created_at: row.user_created_at,
    user_updated_at: row.user_updated_at,
    language_name: row.language,
    title: row.title,
    visibility_name: row.visibility,
    stdin: row.stdin,
    run_instructions: row.run_instructions,
    files: row.files,
    created_at: row.created_at,
    updated_at: row.updated_at,
  )
}

pub fn from_list_after(
  row: sql.ListSnippetsAfter,
) -> Result(HydratedSnippet, db_error.DbQueryError) {
  from_fields(
    id: row.id,
    slug: row.slug,
    user_id: row.user_id,
    user_account_id: row.user_account_id,
    user_email: row.user_email,
    user_username: row.user_username,
    user_role: row.user_role,
    user_last_login_at: row.user_last_login_at,
    user_created_at: row.user_created_at,
    user_updated_at: row.user_updated_at,
    language_name: row.language,
    title: row.title,
    visibility_name: row.visibility,
    stdin: row.stdin,
    run_instructions: row.run_instructions,
    files: row.files,
    created_at: row.created_at,
    updated_at: row.updated_at,
  )
}

pub fn from_list_before(
  row: sql.ListSnippetsBefore,
) -> Result(HydratedSnippet, db_error.DbQueryError) {
  from_fields(
    id: row.id,
    slug: row.slug,
    user_id: row.user_id,
    user_account_id: row.user_account_id,
    user_email: row.user_email,
    user_username: row.user_username,
    user_role: row.user_role,
    user_last_login_at: row.user_last_login_at,
    user_created_at: row.user_created_at,
    user_updated_at: row.user_updated_at,
    language_name: row.language,
    title: row.title,
    visibility_name: row.visibility,
    stdin: row.stdin,
    run_instructions: row.run_instructions,
    files: row.files,
    created_at: row.created_at,
    updated_at: row.updated_at,
  )
}

pub fn from_admin_get_by_slug(
  row: sql.GetAdminSnippetBySlug,
) -> Result(AdminSnippet, db_error.DbQueryError) {
  use snippet <- result.try(from_fields(
    id: row.id,
    slug: row.slug,
    user_id: row.user_id,
    user_account_id: row.user_account_id,
    user_email: row.user_email,
    user_username: row.user_username,
    user_role: row.user_role,
    user_last_login_at: row.user_last_login_at,
    user_created_at: row.user_created_at,
    user_updated_at: row.user_updated_at,
    language_name: row.language,
    title: row.title,
    visibility_name: row.visibility,
    stdin: row.stdin,
    run_instructions: row.run_instructions,
    files: row.files,
    created_at: row.created_at,
    updated_at: row.updated_at,
  ))
  use decision <- result.try(decode_optional_enum(
    row.spam_decision,
    spam_classification.decision_from_string,
  ))
  use reason_code <- result.try(decode_optional_enum(
    row.spam_reason_code,
    spam_classification.reason_code_from_string,
  ))
  use confidence <- result.try(decode_optional_value(
    row.spam_confidence,
    spam_classification.confidence_from_int,
  ))
  use attempts <- result.try(
    row.spam_classification_attempts
    |> option.unwrap(0)
    |> spam_classification.attempts_from_int
    |> result.map_error(db_error.DbQueryError),
  )

  Ok(admin_snippet.AdminSnippet(
    snippet: snippet,
    spam_classification: spam_classification.ClassificationMetadata(
      decision: decision,
      confidence: confidence,
      reason_code: reason_code,
      classified_at: row.spam_classified_at,
      attempts: attempts,
      last_error: row.spam_classification_last_error,
      failed_at: row.spam_classification_failed_at,
    ),
  ))
}

fn decode_optional_enum(
  value: option.Option(String),
  decode_value: fn(String) -> Result(a, String),
) -> Result(option.Option(a), db_error.DbQueryError) {
  decode_optional_value(value, decode_value)
}

fn decode_optional_value(
  value: option.Option(input),
  decode_value: fn(input) -> Result(output, String),
) -> Result(option.Option(output), db_error.DbQueryError) {
  case value {
    option.None -> Ok(option.None)
    option.Some(value) ->
      decode_value(value)
      |> result.map(option.Some)
      |> result.map_error(db_error.DbQueryError)
  }
}

pub fn from_admin_list_after(
  row: sql.ListAdminSnippetsAfter,
) -> Result(HydratedSnippet, db_error.DbQueryError) {
  from_fields(
    id: row.id,
    slug: row.slug,
    user_id: row.user_id,
    user_account_id: row.user_account_id,
    user_email: row.user_email,
    user_username: row.user_username,
    user_role: row.user_role,
    user_last_login_at: row.user_last_login_at,
    user_created_at: row.user_created_at,
    user_updated_at: row.user_updated_at,
    language_name: row.language,
    title: row.title,
    visibility_name: row.visibility,
    stdin: row.stdin,
    run_instructions: row.run_instructions,
    files: row.files,
    created_at: row.created_at,
    updated_at: row.updated_at,
  )
}

pub fn from_admin_list_before(
  row: sql.ListAdminSnippetsBefore,
) -> Result(HydratedSnippet, db_error.DbQueryError) {
  from_fields(
    id: row.id,
    slug: row.slug,
    user_id: row.user_id,
    user_account_id: row.user_account_id,
    user_email: row.user_email,
    user_username: row.user_username,
    user_role: row.user_role,
    user_last_login_at: row.user_last_login_at,
    user_created_at: row.user_created_at,
    user_updated_at: row.user_updated_at,
    language_name: row.language,
    title: row.title,
    visibility_name: row.visibility,
    stdin: row.stdin,
    run_instructions: row.run_instructions,
    files: row.files,
    created_at: row.created_at,
    updated_at: row.updated_at,
  )
}

fn from_fields(
  id id: BitArray,
  slug slug: String,
  user_id user_id: BitArray,
  user_account_id user_account_id: BitArray,
  user_email user_email: String,
  user_username user_username: String,
  user_role user_role: String,
  user_last_login_at user_last_login_at,
  user_created_at user_created_at,
  user_updated_at user_updated_at,
  language_name language_name: String,
  title title: String,
  visibility_name visibility_name: String,
  stdin stdin: String,
  run_instructions run_instructions: option.Option(String),
  files files: String,
  created_at created_at,
  updated_at updated_at,
) -> Result(HydratedSnippet, db_error.DbQueryError) {
  use snippet_language <- result.try(
    language.from_string(language_name)
    |> option.to_result(db_error.DbQueryError(
      "Invalid snippet language: " <> language_name,
    )),
  )
  use visibility <- result.try(
    snippet_model.visibility_from_string(visibility_name)
    |> option.to_result(db_error.DbQueryError(
      "Invalid snippet visibility: " <> visibility_name,
    )),
  )
  use snippet_files <- result.try(
    json.parse(files, decode.list(snippet_model.file_decoder()))
    |> result.map_error(fn(decode_errors) {
      db_error.DbQueryError(
        "Invalid snippet files: " <> string.inspect(decode_errors),
      )
    }),
  )
  use snippet_run_instructions <- result.try(decode_run_instructions(
    run_instructions,
  ))
  use role <- result.try(
    user_model.role_from_string(user_role)
    |> option.to_result(db_error.DbQueryError(
      "Invalid user role: " <> user_role,
    )),
  )

  Ok(snippet_model.HydratedSnippet(
    identity: snippet_model.Snippet(
      id: uuid_helpers.from_bit_array(id),
      slug: slug,
      user_id: uuid_helpers.from_bit_array(user_id),
      title: title,
      language: snippet_language,
      visibility: visibility,
      stdin: stdin,
      run_instructions: snippet_run_instructions,
      files: snippet_files,
      created_at: created_at,
      updated_at: updated_at,
    ),
    user: user_model.User(
      id: uuid_helpers.from_bit_array(user_id),
      account_id: uuid_helpers.from_bit_array(user_account_id),
      email: email_address_model.EmailAddress(user_email),
      username: user_username,
      role: role,
      last_login_at: user_last_login_at,
      created_at: user_created_at,
      updated_at: user_updated_at,
    ),
  ))
}

fn decode_run_instructions(
  run_instructions: option.Option(String),
) -> Result(option.Option(language.RunInstructions), db_error.DbQueryError) {
  case run_instructions {
    option.Some(value) ->
      case json.parse(value, language.run_instructions_decoder()) {
        Ok(instructions) -> Ok(option.Some(instructions))
        Error(decode_errors) ->
          Error(db_error.DbQueryError(
            "Invalid snippet run instructions: "
            <> string.inspect(decode_errors),
          ))
      }
    option.None -> Ok(option.None)
  }
}

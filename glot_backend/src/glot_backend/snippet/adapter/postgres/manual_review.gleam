import gleam/list
import gleam/option
import gleam/result
import gleam/string
import gleam/time/timestamp.{type Timestamp}
import glot_backend/snippet/adapter/postgres/row
import glot_backend/sql
import glot_backend/system/database as db
import glot_backend/system/effect/error/db_error
import glot_core/admin/snippet_dto
import glot_core/admin/spam_review_dto.{
  type ListRequest, type ReviewSnippet, type SaveRequest,
}
import glot_core/helpers/uuid_helpers
import glot_core/language
import glot_core/pagination_model
import glot_core/snippet/manual_review.{type ManualReview}
import glot_core/snippet/spam_classification
import glot_core/snippet/spam_review_filter
import youid/uuid.{type Uuid}

pub fn list(
  connection: db.Db,
  request: ListRequest,
) -> Result(List(ReviewSnippet), db_error.DbQueryError) {
  let filter = request.filter
  let #(cursor, backwards, limit) = case request.pagination {
    pagination_model.InitialPage(limit) -> #(option.None, False, limit)
    pagination_model.AfterPage(cursor, limit) -> #(
      option.Some(pagination_model.to_string(cursor)),
      False,
      limit,
    )
    pagination_model.BeforePage(cursor, limit) -> #(
      option.Some(pagination_model.to_string(cursor)),
      True,
      limit,
    )
  }
  use returned <- result.try(db.query(
    connection,
    sql.list_spam_review(
      spam_review_filter.decision_to_string(filter.decision),
      option.map(filter.reason, spam_classification.reason_code_to_string),
      filter.confidence_min,
      filter.confidence_max,
      spam_review_filter.manual_to_string(filter.manual),
      filter.username,
      option.map(filter.language, language.to_string),
      cursor,
      backwards,
      request.inclusive,
      request.focus,
      limit,
    ),
    query_error,
  ))
  use items <- result.try(returned.rows |> list.map(from_row) |> result.all)
  Ok(case backwards {
    True -> list.reverse(items)
    False -> items
  })
}

fn from_row(
  value: sql.ListSpamReview,
) -> Result(ReviewSnippet, db_error.DbQueryError) {
  use snippet <- result.try(
    row.from_admin_get_by_slug(sql.GetAdminSnippetBySlug(
      id: value.id,
      slug: value.slug,
      language: value.language,
      title: value.title,
      visibility: value.visibility,
      stdin: value.stdin,
      run_instructions: value.run_instructions,
      files: value.files,
      created_at: value.created_at,
      updated_at: value.updated_at,
      spam_decision: value.spam_decision,
      spam_confidence: value.spam_confidence,
      spam_reason_code: value.spam_reason_code,
      spam_classified_at: value.spam_classified_at,
      spam_classification_attempts: value.spam_classification_attempts,
      spam_classification_last_error: value.spam_classification_last_error,
      spam_classification_failed_at: value.spam_classification_failed_at,
      spam_explanation: value.spam_explanation,
      is_runnable: value.is_runnable,
      runnability_checked_at: value.runnability_checked_at,
      runnability_check_attempts: value.runnability_check_attempts,
      runnability_check_last_error: value.runnability_check_last_error,
      runnability_check_failed_at: value.runnability_check_failed_at,
      user_id: value.user_id,
      user_account_id: value.user_account_id,
      user_email: value.user_email,
      user_username: value.user_username,
      user_role: value.user_role,
      user_last_login_at: value.user_last_login_at,
      user_created_at: value.user_created_at,
      user_updated_at: value.user_updated_at,
    )),
  )
  use review <- result.try(from_fields(
    value.manual_verdict,
    value.manual_reviewer_id,
    value.manual_reviewed_at,
    value.manual_review_version,
  ))
  Ok(spam_review_dto.ReviewSnippet(
    snippet_dto.from_admin_snippet(snippet).snippet,
    review,
  ))
}

pub fn save(
  connection: db.Db,
  request: SaveRequest,
  reviewer: Uuid,
  reviewed_at: Timestamp,
) -> Result(option.Option(ManualReview), db_error.DbQueryError) {
  use returned <- result.try(db.query(
    connection,
    sql.save_manual_review(
      request.slug,
      option.map(request.verdict, manual_review.to_string),
      option.Some(uuid.to_bit_array(reviewer)),
      option.Some(reviewed_at),
      request.expected_version,
      request.revision,
    ),
    query_error,
  ))
  case returned.rows {
    [] -> Ok(option.None)
    [value] ->
      from_fields(
        value.manual_verdict,
        value.manual_reviewer_id,
        value.manual_reviewed_at,
        value.manual_review_version,
      )
      |> result.map(option.Some)
    _ -> Error(db_error.DbQueryError("Expected at most one manual review"))
  }
}

fn from_fields(
  verdict,
  reviewer,
  reviewed_at,
  version,
) -> Result(ManualReview, db_error.DbQueryError) {
  use verdict <- result.try(case verdict {
    option.None -> Ok(option.None)
    option.Some(value) ->
      manual_review.from_string(value)
      |> result.map(option.Some)
      |> result.map_error(db_error.DbQueryError)
  })
  Ok(manual_review.ManualReview(
    verdict,
    option.map(reviewer, uuid_helpers.from_bit_array),
    reviewed_at,
    version,
  ))
}

fn query_error(value) -> db_error.DbQueryError {
  db_error.DbQueryError(string.inspect(value))
}

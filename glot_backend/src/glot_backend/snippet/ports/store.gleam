import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_backend/system/effect/error/db_error
import glot_core/pagination_model.{type CursorPagination}
import glot_core/snippet/admin_snippet.{type AdminSnippet}
import glot_core/snippet/runnability
import glot_core/snippet/snippet_model.{
  type HydratedSnippet, type ListSnippetsFilter, type Snippet,
}
import glot_core/snippet/spam_classification
import youid/uuid.{type Uuid}

pub type Store {
  Store(
    get_snippet_by_id: fn(Uuid) ->
      Result(option.Option(HydratedSnippet), db_error.DbQueryError),
    get_snippet_by_slug: fn(String) ->
      Result(option.Option(HydratedSnippet), db_error.DbQueryError),
    get_snippet_by_slug_for_update: fn(String) ->
      Result(option.Option(HydratedSnippet), db_error.DbQueryError),
    get_admin_snippet_by_slug: fn(String) ->
      Result(option.Option(AdminSnippet), db_error.DbQueryError),
    list_snippets: fn(ListSnippetsFilter, CursorPagination) ->
      Result(List(HydratedSnippet), db_error.DbQueryError),
    list_admin_snippets: fn(
      option.Option(String),
      option.Option(spam_classification.Filter),
      CursorPagination,
    ) -> Result(List(HydratedSnippet), db_error.DbQueryError),
    delete_snippet: fn(Uuid) -> Result(Nil, db_error.DbCommandError),
    delete_snippets_by_account_id: fn(Uuid) ->
      Result(Nil, db_error.DbCommandError),
    create_snippet: fn(Snippet) -> Result(Nil, db_error.DbCommandError),
    update_snippet: fn(Snippet) -> Result(Nil, db_error.DbCommandError),
    get_newest_unclassified_snippet: fn() ->
      Result(
        option.Option(spam_classification.Candidate),
        db_error.DbQueryError,
      ),
    increment_spam_classification_attempts: fn(Uuid, Timestamp) ->
      Result(spam_classification.StoreResult, db_error.DbCommandError),
    store_spam_classification: fn(
      Uuid,
      Timestamp,
      spam_classification.ClassificationResult,
    ) -> Result(spam_classification.StoreResult, db_error.DbCommandError),
    update_spam_classification: fn(
      Uuid,
      Timestamp,
      spam_classification.ClassificationResult,
    ) -> Result(spam_classification.StoreResult, db_error.DbCommandError),
    store_spam_classification_failure: fn(
      Uuid,
      Timestamp,
      spam_classification.ClassificationFailure,
    ) -> Result(spam_classification.StoreResult, db_error.DbCommandError),
    get_newest_unchecked_runnability: fn() ->
      Result(option.Option(runnability.Candidate), db_error.DbQueryError),
    increment_runnability_check_attempts: fn(Uuid, Timestamp) ->
      Result(runnability.StoreResult, db_error.DbCommandError),
    store_runnability: fn(Uuid, Timestamp, runnability.CheckResult) ->
      Result(runnability.StoreResult, db_error.DbCommandError),
    store_runnability_check_failure: fn(
      Uuid,
      Timestamp,
      runnability.CheckFailure,
    ) -> Result(runnability.StoreResult, db_error.DbCommandError),
  )
}

import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_backend/system/effect/error/db_error
import glot_core/pagination_model.{type CursorPagination}
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
      Result(option.Option(HydratedSnippet), db_error.DbQueryError),
    list_snippets: fn(ListSnippetsFilter, CursorPagination) ->
      Result(List(HydratedSnippet), db_error.DbQueryError),
    list_admin_snippets: fn(option.Option(String), CursorPagination) ->
      Result(List(HydratedSnippet), db_error.DbQueryError),
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
    store_spam_classification: fn(
      Uuid,
      Timestamp,
      spam_classification.ClassificationResult,
    ) -> Result(Nil, db_error.DbCommandError),
    store_spam_classification_failure: fn(
      Uuid,
      Timestamp,
      spam_classification.ClassificationFailure,
    ) -> Result(Nil, db_error.DbCommandError),
  )
}

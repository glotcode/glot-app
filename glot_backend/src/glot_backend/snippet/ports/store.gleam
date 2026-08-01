import gleam/option
import glot_backend/system/effect/error/db_error
import glot_core/pagination_model.{type CursorPagination}
import glot_core/snippet/snippet_model.{
  type HydratedSnippet, type ListSnippetsFilter, type Snippet,
}
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
  )
}

import gleam/option
import glot_backend/system/effect/error/db_error
import glot_core/pagination_model.{type CursorPagination}
import glot_core/snippet/snippet_model.{
  type HydratedSnippet, type ListSnippetsFilter, type Snippet,
}
import youid/uuid.{type Uuid}

pub type SnippetEffect(next) {
  GetSnippetById(
    id: Uuid,
    next: fn(Result(option.Option(HydratedSnippet), db_error.DbQueryError)) ->
      next,
  )
  GetSnippetBySlug(
    slug: String,
    next: fn(Result(option.Option(HydratedSnippet), db_error.DbQueryError)) ->
      next,
  )
  GetSnippetBySlugForUpdate(
    slug: String,
    next: fn(Result(option.Option(HydratedSnippet), db_error.DbQueryError)) ->
      next,
  )
  GetAdminSnippetBySlug(
    slug: String,
    next: fn(Result(option.Option(HydratedSnippet), db_error.DbQueryError)) ->
      next,
  )
  ListSnippets(
    filter: ListSnippetsFilter,
    pagination: CursorPagination,
    next: fn(Result(List(HydratedSnippet), db_error.DbQueryError)) -> next,
  )
  ListAdminSnippets(
    username: option.Option(String),
    pagination: CursorPagination,
    next: fn(Result(List(HydratedSnippet), db_error.DbQueryError)) -> next,
  )
  DeleteSnippet(
    id: Uuid,
    next: fn(Result(Nil, db_error.DbCommandError)) -> next,
  )
  DeleteSnippetsByAccountId(
    account_id: Uuid,
    next: fn(Result(Nil, db_error.DbCommandError)) -> next,
  )
  CreateSnippet(
    snippet: Snippet,
    next: fn(Result(Nil, db_error.DbCommandError)) -> next,
  )
  UpdateSnippet(
    snippet: Snippet,
    next: fn(Result(Nil, db_error.DbCommandError)) -> next,
  )
}

pub fn map(effect: SnippetEffect(a), f: fn(a) -> b) -> SnippetEffect(b) {
  case effect {
    GetSnippetById(id, next) ->
      GetSnippetById(id, next: fn(value) { f(next(value)) })
    GetSnippetBySlug(slug, next) ->
      GetSnippetBySlug(slug, next: fn(value) { f(next(value)) })
    GetSnippetBySlugForUpdate(slug, next) ->
      GetSnippetBySlugForUpdate(slug, next: fn(value) { f(next(value)) })
    GetAdminSnippetBySlug(slug, next) ->
      GetAdminSnippetBySlug(slug, next: fn(value) { f(next(value)) })
    ListSnippets(filter:, pagination:, next:) ->
      ListSnippets(filter: filter, pagination: pagination, next: fn(value) {
        f(next(value))
      })
    ListAdminSnippets(username:, pagination:, next:) ->
      ListAdminSnippets(
        username: username,
        pagination: pagination,
        next: fn(value) { f(next(value)) },
      )
    DeleteSnippet(id, next) ->
      DeleteSnippet(id, next: fn(value) { f(next(value)) })
    DeleteSnippetsByAccountId(account_id: account_id, next: next) ->
      DeleteSnippetsByAccountId(account_id: account_id, next: fn(value) {
        f(next(value))
      })
    CreateSnippet(snippet, next) ->
      CreateSnippet(snippet, next: fn(value) { f(next(value)) })
    UpdateSnippet(snippet, next) ->
      UpdateSnippet(snippet, next: fn(value) { f(next(value)) })
  }
}

pub type EffectName {
  GetSnippetByIdEffectName
  GetSnippetBySlugEffectName
  GetSnippetBySlugForUpdateEffectName
  GetAdminSnippetBySlugEffectName
  ListSnippetsEffectName
  ListAdminSnippetsEffectName
  DeleteSnippetEffectName
  DeleteSnippetsByAccountIdEffectName
  CreateSnippetEffectName
  UpdateSnippetEffectName
}

pub fn effect_name_to_string(name: EffectName) -> String {
  case name {
    GetSnippetByIdEffectName -> "get_snippet_by_id"
    GetSnippetBySlugEffectName -> "get_snippet_by_slug"
    GetSnippetBySlugForUpdateEffectName -> "get_snippet_by_slug_for_update"
    GetAdminSnippetBySlugEffectName -> "get_admin_snippet_by_slug"
    ListSnippetsEffectName -> "list_snippets"
    ListAdminSnippetsEffectName -> "list_admin_snippets"
    DeleteSnippetEffectName -> "delete_snippet"
    DeleteSnippetsByAccountIdEffectName -> "delete_snippets_by_account_id"
    CreateSnippetEffectName -> "create_snippet"
    UpdateSnippetEffectName -> "update_snippet"
  }
}

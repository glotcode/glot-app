import gleam/option
import glot_backend/snippet/effect/algebra as snippet_algebra
import glot_backend/system/effect/error
import glot_backend/system/effect/error/db_error
import glot_backend/system/effect/program_types
import glot_core/pagination_model.{type CursorPagination}
import glot_core/snippet/snippet_model.{
  type HydratedSnippet, type ListSnippetsFilter, type Snippet,
}
import youid/uuid

pub fn get_by_id(
  id: uuid.Uuid,
) -> program_types.Program(option.Option(HydratedSnippet)) {
  program_types.Impure(program_types.DbEffect(get_by_id_effect(id, query_next)))
}

pub fn get_by_slug(
  slug: String,
) -> program_types.Program(option.Option(HydratedSnippet)) {
  program_types.Impure(
    program_types.DbEffect(get_by_slug_effect(slug, query_next)),
  )
}

pub fn get_admin_by_slug(
  slug: String,
) -> program_types.Program(option.Option(HydratedSnippet)) {
  program_types.Impure(
    program_types.DbEffect(get_admin_by_slug_effect(slug, query_next)),
  )
}

pub fn list(
  filter filter: ListSnippetsFilter,
  pagination pagination: CursorPagination,
) -> program_types.Program(List(HydratedSnippet)) {
  program_types.Impure(
    program_types.DbEffect(list_effect(filter, pagination, list_next)),
  )
}

pub fn list_admin(
  username username: option.Option(String),
  pagination pagination: CursorPagination,
) -> program_types.Program(List(HydratedSnippet)) {
  program_types.Impure(
    program_types.DbEffect(list_admin_effect(username, pagination, list_next)),
  )
}

pub fn create(snippet snippet: Snippet) -> program_types.Program(Nil) {
  program_types.Impure(
    program_types.DbEffect(create_effect(snippet, command_next)),
  )
}

fn query_next(
  result: Result(option.Option(HydratedSnippet), db_error.DbQueryError),
) -> program_types.Program(option.Option(HydratedSnippet)) {
  case result {
    Ok(value) -> program_types.Pure(value)
    Error(err) -> program_types.Fail(error.database_query_error(err))
  }
}

fn list_next(
  result: Result(List(HydratedSnippet), db_error.DbQueryError),
) -> program_types.Program(List(HydratedSnippet)) {
  case result {
    Ok(value) -> program_types.Pure(value)
    Error(err) -> program_types.Fail(error.database_query_error(err))
  }
}

pub fn delete(id: uuid.Uuid) -> program_types.Program(Nil) {
  program_types.Impure(program_types.DbEffect(delete_effect(id, command_next)))
}

pub fn delete_by_account_id(id id: uuid.Uuid) -> program_types.Program(Nil) {
  program_types.Impure(
    program_types.DbEffect(delete_by_account_id_effect(id, command_next)),
  )
}

fn command_next(
  result: Result(Nil, db_error.DbCommandError),
) -> program_types.Program(Nil) {
  case result {
    Ok(_) -> program_types.Pure(Nil)
    Error(err) -> program_types.Fail(error.database_command_error(err))
  }
}

pub fn update(snippet snippet: Snippet) -> program_types.Program(Nil) {
  program_types.Impure(
    program_types.DbEffect(update_effect(snippet, command_next)),
  )
}

pub fn get_by_id_tx(
  id: uuid.Uuid,
) -> program_types.TransactionProgram(option.Option(HydratedSnippet)) {
  program_types.TxImpure(get_by_id_effect(id, tx_query_next))
}

pub fn get_by_slug_for_update_tx(
  slug: String,
) -> program_types.TransactionProgram(option.Option(HydratedSnippet)) {
  program_types.TxImpure(get_by_slug_for_update_effect(slug, tx_query_next))
}

pub fn create_tx(
  snippet snippet: Snippet,
) -> program_types.TransactionProgram(Nil) {
  program_types.TxImpure(create_effect(snippet, tx_command_next))
}

pub fn delete_tx(id: uuid.Uuid) -> program_types.TransactionProgram(Nil) {
  program_types.TxImpure(delete_effect(id, tx_command_next))
}

pub fn delete_by_account_id_tx(
  id id: uuid.Uuid,
) -> program_types.TransactionProgram(Nil) {
  program_types.TxImpure(delete_by_account_id_effect(id, tx_command_next))
}

pub fn update_tx(
  snippet snippet: Snippet,
) -> program_types.TransactionProgram(Nil) {
  program_types.TxImpure(update_effect(snippet, tx_command_next))
}

fn tx_query_next(
  result: Result(option.Option(HydratedSnippet), db_error.DbQueryError),
) -> program_types.TransactionProgram(option.Option(HydratedSnippet)) {
  case result {
    Ok(value) -> program_types.TxPure(value)
    Error(err) -> program_types.TxFail(error.database_query_error(err))
  }
}

fn tx_command_next(
  result: Result(Nil, db_error.DbCommandError),
) -> program_types.TransactionProgram(Nil) {
  case result {
    Ok(_) -> program_types.TxPure(Nil)
    Error(err) -> program_types.TxFail(error.database_command_error(err))
  }
}

fn get_by_id_effect(
  id: uuid.Uuid,
  next: fn(Result(option.Option(HydratedSnippet), db_error.DbQueryError)) ->
    next,
) -> program_types.DbEffect(next) {
  program_types.SnippetEffect(snippet_algebra.GetSnippetById(id: id, next: next))
}

fn get_by_slug_effect(
  slug: String,
  next: fn(Result(option.Option(HydratedSnippet), db_error.DbQueryError)) ->
    next,
) -> program_types.DbEffect(next) {
  program_types.SnippetEffect(snippet_algebra.GetSnippetBySlug(
    slug:,
    next: next,
  ))
}

fn get_by_slug_for_update_effect(
  slug: String,
  next: fn(Result(option.Option(HydratedSnippet), db_error.DbQueryError)) ->
    next,
) -> program_types.DbEffect(next) {
  program_types.SnippetEffect(snippet_algebra.GetSnippetBySlugForUpdate(
    slug:,
    next: next,
  ))
}

fn get_admin_by_slug_effect(
  slug: String,
  next: fn(Result(option.Option(HydratedSnippet), db_error.DbQueryError)) ->
    next,
) -> program_types.DbEffect(next) {
  program_types.SnippetEffect(snippet_algebra.GetAdminSnippetBySlug(
    slug:,
    next: next,
  ))
}

fn list_effect(
  filter: ListSnippetsFilter,
  pagination: CursorPagination,
  next: fn(Result(List(HydratedSnippet), db_error.DbQueryError)) -> next,
) -> program_types.DbEffect(next) {
  program_types.SnippetEffect(snippet_algebra.ListSnippets(
    filter: filter,
    pagination: pagination,
    next: next,
  ))
}

fn list_admin_effect(
  username: option.Option(String),
  pagination: CursorPagination,
  next: fn(Result(List(HydratedSnippet), db_error.DbQueryError)) -> next,
) -> program_types.DbEffect(next) {
  program_types.SnippetEffect(snippet_algebra.ListAdminSnippets(
    username: username,
    pagination: pagination,
    next: next,
  ))
}

fn create_effect(
  snippet: Snippet,
  next: fn(Result(Nil, db_error.DbCommandError)) -> next,
) -> program_types.DbEffect(next) {
  program_types.SnippetEffect(snippet_algebra.CreateSnippet(
    snippet:,
    next: next,
  ))
}

fn delete_effect(
  id: uuid.Uuid,
  next: fn(Result(Nil, db_error.DbCommandError)) -> next,
) -> program_types.DbEffect(next) {
  program_types.SnippetEffect(snippet_algebra.DeleteSnippet(id: id, next: next))
}

fn delete_by_account_id_effect(
  id: uuid.Uuid,
  next: fn(Result(Nil, db_error.DbCommandError)) -> next,
) -> program_types.DbEffect(next) {
  program_types.SnippetEffect(snippet_algebra.DeleteSnippetsByAccountId(
    account_id: id,
    next: next,
  ))
}

fn update_effect(
  snippet: Snippet,
  next: fn(Result(Nil, db_error.DbCommandError)) -> next,
) -> program_types.DbEffect(next) {
  program_types.SnippetEffect(snippet_algebra.UpdateSnippet(
    snippet:,
    next: next,
  ))
}

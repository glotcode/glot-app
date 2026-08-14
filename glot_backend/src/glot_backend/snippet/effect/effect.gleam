import gleam/option
import glot_backend/snippet/effect/algebra as snippet_algebra
import glot_backend/system/effect/error
import glot_backend/system/effect/error/db_error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types
import glot_backend/system/effect/transaction/transaction_program
import glot_core/pagination_model.{type CursorPagination}
import glot_core/snippet/snippet_model.{
  type HydratedSnippet, type ListSnippetsFilter, type Snippet,
}
import youid/uuid

pub fn get_by_id(
  id: uuid.Uuid,
) -> program_types.Program(option.Option(HydratedSnippet)) {
  program.perform_db(
    get_by_id_effect(id, program.from_mapped_result(
      _,
      map_error: error.database_query_error,
    )),
  )
}

pub fn get_by_slug(
  slug: String,
) -> program_types.Program(option.Option(HydratedSnippet)) {
  program.perform_db(
    get_by_slug_effect(slug, program.from_mapped_result(
      _,
      map_error: error.database_query_error,
    )),
  )
}

pub fn get_admin_by_slug(
  slug: String,
) -> program_types.Program(option.Option(HydratedSnippet)) {
  program.perform_db(
    get_admin_by_slug_effect(slug, program.from_mapped_result(
      _,
      map_error: error.database_query_error,
    )),
  )
}

pub fn list(
  filter filter: ListSnippetsFilter,
  pagination pagination: CursorPagination,
) -> program_types.Program(List(HydratedSnippet)) {
  program.perform_db(
    list_effect(filter, pagination, program.from_mapped_result(
      _,
      map_error: error.database_query_error,
    )),
  )
}

pub fn list_admin(
  username username: option.Option(String),
  pagination pagination: CursorPagination,
) -> program_types.Program(List(HydratedSnippet)) {
  program.perform_db(
    list_admin_effect(username, pagination, program.from_mapped_result(
      _,
      map_error: error.database_query_error,
    )),
  )
}

pub fn create(snippet snippet: Snippet) -> program_types.Program(Nil) {
  program.perform_db(
    create_effect(snippet, program.from_mapped_result(
      _,
      map_error: error.database_command_error,
    )),
  )
}

pub fn delete(id: uuid.Uuid) -> program_types.Program(Nil) {
  program.perform_db(
    delete_effect(id, program.from_mapped_result(
      _,
      map_error: error.database_command_error,
    )),
  )
}

pub fn delete_by_account_id(id id: uuid.Uuid) -> program_types.Program(Nil) {
  program.perform_db(
    delete_by_account_id_effect(id, program.from_mapped_result(
      _,
      map_error: error.database_command_error,
    )),
  )
}

pub fn update(snippet snippet: Snippet) -> program_types.Program(Nil) {
  program.perform_db(
    update_effect(snippet, program.from_mapped_result(
      _,
      map_error: error.database_command_error,
    )),
  )
}

pub fn get_by_id_tx(
  id: uuid.Uuid,
) -> program_types.TransactionProgram(option.Option(HydratedSnippet)) {
  transaction_program.perform(
    get_by_id_effect(id, transaction_program.from_mapped_result(
      _,
      map_error: error.database_query_error,
    )),
  )
}

pub fn get_by_slug_for_update_tx(
  slug: String,
) -> program_types.TransactionProgram(option.Option(HydratedSnippet)) {
  transaction_program.perform(
    get_by_slug_for_update_effect(slug, transaction_program.from_mapped_result(
      _,
      map_error: error.database_query_error,
    )),
  )
}

pub fn create_tx(
  snippet snippet: Snippet,
) -> program_types.TransactionProgram(Nil) {
  transaction_program.perform(
    create_effect(snippet, transaction_program.from_mapped_result(
      _,
      map_error: error.database_command_error,
    )),
  )
}

pub fn delete_tx(id: uuid.Uuid) -> program_types.TransactionProgram(Nil) {
  transaction_program.perform(
    delete_effect(id, transaction_program.from_mapped_result(
      _,
      map_error: error.database_command_error,
    )),
  )
}

pub fn delete_by_account_id_tx(
  id id: uuid.Uuid,
) -> program_types.TransactionProgram(Nil) {
  transaction_program.perform(
    delete_by_account_id_effect(id, transaction_program.from_mapped_result(
      _,
      map_error: error.database_command_error,
    )),
  )
}

pub fn update_tx(
  snippet snippet: Snippet,
) -> program_types.TransactionProgram(Nil) {
  transaction_program.perform(
    update_effect(snippet, transaction_program.from_mapped_result(
      _,
      map_error: error.database_command_error,
    )),
  )
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

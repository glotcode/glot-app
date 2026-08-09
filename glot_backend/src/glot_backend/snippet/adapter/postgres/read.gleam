import gleam/list
import gleam/option
import gleam/result
import gleam/string
import glot_backend/snippet/adapter/postgres/row
import glot_backend/sql
import glot_backend/system/database as db_helpers
import glot_backend/system/effect/error/db_error
import glot_core/auth/account_model
import glot_core/language
import glot_core/pagination_model.{type CursorPagination}
import glot_core/snippet/snippet_model.{
  type HydratedSnippet, type ListSnippetsFilter,
}
import youid/uuid.{type Uuid}

pub fn get_by_id(
  db: db_helpers.Db,
  id: Uuid,
) -> Result(option.Option(HydratedSnippet), db_error.DbQueryError) {
  use returned <- result.try(
    db_helpers.query(db, sql.get_snippet_by_id(uuid.to_bit_array(id)), fn(err) {
      db_error.DbQueryError(string.inspect(err))
    }),
  )

  decode_optional(returned.rows, row.from_get_by_id)
}

pub fn get_by_slug(
  db: db_helpers.Db,
  slug: String,
) -> Result(option.Option(HydratedSnippet), db_error.DbQueryError) {
  use returned <- result.try(
    db_helpers.query(db, sql.get_snippet_by_slug(slug), fn(err) {
      db_error.DbQueryError(string.inspect(err))
    }),
  )

  decode_optional(returned.rows, row.from_get_by_slug)
}

pub fn get_by_slug_for_update(
  db: db_helpers.Db,
  slug: String,
) -> Result(option.Option(HydratedSnippet), db_error.DbQueryError) {
  use returned <- result.try(
    db_helpers.query(db, sql.get_snippet_by_slug_for_update(slug), fn(err) {
      db_error.DbQueryError(string.inspect(err))
    }),
  )

  decode_optional(returned.rows, row.from_get_by_slug_for_update)
}

pub fn get_admin_by_slug(
  db: db_helpers.Db,
  slug: String,
) -> Result(option.Option(HydratedSnippet), db_error.DbQueryError) {
  use returned <- result.try(
    db_helpers.query(db, sql.get_admin_snippet_by_slug(slug), fn(err) {
      db_error.DbQueryError(string.inspect(err))
    }),
  )

  decode_optional(returned.rows, row.from_admin_get_by_slug)
}

pub fn list(
  db: db_helpers.Db,
  filter: ListSnippetsFilter,
  pagination: CursorPagination,
) -> Result(List(HydratedSnippet), db_error.DbQueryError) {
  let visibility_strings =
    filter.visibilities
    |> list.map(snippet_model.visibility_to_string)
  let skip_user_id_bits = filter.skip_user_ids |> list.map(uuid.to_bit_array)
  let user_id_bits = filter.user_ids |> list.map(uuid.to_bit_array)
  let excluded_titles = filter.excluded_titles |> list.map(string.lowercase)
  let excluded_languages =
    filter.excluded_languages |> list.map(language.to_string)
  let languages = filter.languages |> list.map(language.to_string)
  let account_states =
    filter.account_states |> list.map(account_model.account_state_to_string)

  case pagination {
    pagination_model.BeforePage(before_slug, limit) ->
      db_helpers.query(
        db,
        sql.list_snippets_before(
          visibility_strings,
          filter.usernames,
          languages,
          user_id_bits,
          skip_user_id_bits,
          account_states,
          filter.user_created_before,
          excluded_titles,
          excluded_languages,
          option.Some(pagination_model.to_string(before_slug)),
          limit,
        ),
        query_error,
      )
      |> result.try(fn(returned) {
        returned.rows
        |> list.map(row.from_list_before)
        |> result.all
        |> result.map(list.reverse)
      })
    pagination_model.InitialPage(limit)
    | pagination_model.AfterPage(_, limit) -> {
      let after_slug = case pagination {
        pagination_model.AfterPage(cursor, _) ->
          option.Some(pagination_model.to_string(cursor))
        pagination_model.InitialPage(_) -> option.None
        pagination_model.BeforePage(_, _) -> option.None
      }
      db_helpers.query(
        db,
        sql.list_snippets_after(
          visibility_strings,
          filter.usernames,
          languages,
          user_id_bits,
          skip_user_id_bits,
          account_states,
          filter.user_created_before,
          excluded_titles,
          excluded_languages,
          after_slug,
          limit,
        ),
        query_error,
      )
      |> result.try(fn(returned) {
        returned.rows
        |> list.map(row.from_list_after)
        |> result.all
      })
    }
  }
}

pub fn list_admin(
  db: db_helpers.Db,
  username: option.Option(String),
  pagination: CursorPagination,
) -> Result(List(HydratedSnippet), db_error.DbQueryError) {
  case pagination {
    pagination_model.BeforePage(before_slug, limit) ->
      db_helpers.query(
        db,
        sql.list_admin_snippets_before(
          username,
          option.Some(pagination_model.to_string(before_slug)),
          limit,
        ),
        query_error,
      )
      |> result.try(fn(returned) {
        returned.rows
        |> list.map(row.from_admin_list_before)
        |> result.all
        |> result.map(list.reverse)
      })
    pagination_model.InitialPage(limit)
    | pagination_model.AfterPage(_, limit) -> {
      let after_slug = case pagination {
        pagination_model.AfterPage(cursor, _) ->
          option.Some(pagination_model.to_string(cursor))
        pagination_model.InitialPage(_) -> option.None
        pagination_model.BeforePage(_, _) -> option.None
      }
      db_helpers.query(
        db,
        sql.list_admin_snippets_after(username, after_slug, limit),
        query_error,
      )
      |> result.try(fn(returned) {
        returned.rows
        |> list.map(row.from_admin_list_after)
        |> result.all
      })
    }
  }
}

fn decode_optional(
  rows: List(row),
  decoder: fn(row) -> Result(HydratedSnippet, db_error.DbQueryError),
) -> Result(option.Option(HydratedSnippet), db_error.DbQueryError) {
  case rows {
    [] -> Ok(option.None)
    [row] -> decoder(row) |> result.map(option.Some)
    _ -> Error(db_error.DbQueryError("Expected at most one snippet row"))
  }
}

fn query_error(error) -> db_error.DbQueryError {
  db_error.DbQueryError(string.inspect(error))
}

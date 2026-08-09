import gleam/option
import gleam/regexp
import gleam/result
import gleam/string
import glot_backend/auth/adapter/postgres/user/row
import glot_backend/auth/model/user_list_filters.{type UserListFilters}
import glot_backend/sql
import glot_backend/system/database as db_helpers
import glot_backend/system/effect/error/db_error
import glot_core/auth/account_model
import glot_core/auth/user_model
import glot_core/email/email_address_model
import glot_core/pagination_model.{type CursorPagination}
import youid/uuid.{type Uuid}

pub fn get_by_email(
  db: db_helpers.Db,
  is_email: regexp.Regexp,
  user_email: email_address_model.EmailAddress,
) -> Result(option.Option(user_model.HydratedUser), db_error.DbQueryError) {
  db_helpers.query(
    db,
    sql.get_user_by_email(email_address_model.to_string(user_email)),
    query_error,
  )
  |> result.try(fn(returned) {
    row.hydrated_from_email_rows(is_email, returned.rows)
  })
}

pub fn get_by_id(
  db: db_helpers.Db,
  is_email: regexp.Regexp,
  id: Uuid,
) -> Result(option.Option(user_model.HydratedUser), db_error.DbQueryError) {
  db_helpers.query(db, sql.get_user_by_id(uuid.to_bit_array(id)), query_error)
  |> result.try(fn(returned) {
    row.hydrated_from_id_rows(is_email, returned.rows)
  })
}

pub fn get_by_id_for_update(
  db: db_helpers.Db,
  is_email: regexp.Regexp,
  id: Uuid,
) -> Result(option.Option(user_model.HydratedUser), db_error.DbQueryError) {
  db_helpers.query(
    db,
    sql.get_user_by_id_for_update(uuid.to_bit_array(id)),
    query_error,
  )
  |> result.try(fn(returned) {
    row.hydrated_from_id_for_update_rows(is_email, returned.rows)
  })
}

pub fn list(
  db: db_helpers.Db,
  is_email: regexp.Regexp,
  pagination: CursorPagination,
  filters: UserListFilters,
) -> Result(List(user_model.HydratedUser), db_error.DbQueryError) {
  let role = option.map(filters.role, user_model.role_to_string)
  let account_state =
    option.map(filters.account_state, account_model.account_state_to_string)
  let account_tier =
    option.map(filters.account_tier, account_model.account_tier_to_string)

  case pagination {
    pagination_model.InitialPage(limit) ->
      db_helpers.query(
        db,
        sql.list_users_after(
          after_id: option.None,
          email: filters.email,
          username: filters.username,
          id: option.map(filters.id, uuid.to_bit_array),
          role: role,
          account_state: account_state,
          account_tier: account_tier,
          page_limit: limit,
        ),
        query_error,
      )
      |> result.try(fn(returned) {
        row.hydrated_from_after_rows(is_email, returned.rows)
      })
    pagination_model.AfterPage(cursor, limit) -> {
      use id <- result.try(cursor_to_uuid(cursor))
      db_helpers.query(
        db,
        sql.list_users_after(
          after_id: option.Some(uuid.to_bit_array(id)),
          email: filters.email,
          username: filters.username,
          id: option.map(filters.id, uuid.to_bit_array),
          role: role,
          account_state: account_state,
          account_tier: account_tier,
          page_limit: limit,
        ),
        query_error,
      )
      |> result.try(fn(returned) {
        row.hydrated_from_after_rows(is_email, returned.rows)
      })
    }
    pagination_model.BeforePage(cursor, limit) -> {
      use id <- result.try(cursor_to_uuid(cursor))
      db_helpers.query(
        db,
        sql.list_users_before(
          before_id: option.Some(uuid.to_bit_array(id)),
          email: filters.email,
          username: filters.username,
          id: option.map(filters.id, uuid.to_bit_array),
          role: role,
          account_state: account_state,
          account_tier: account_tier,
          page_limit: limit,
        ),
        query_error,
      )
      |> result.try(fn(returned) {
        row.hydrated_from_before_rows(is_email, returned.rows)
      })
    }
  }
}

fn cursor_to_uuid(
  cursor: pagination_model.Cursor,
) -> Result(Uuid, db_error.DbQueryError) {
  cursor
  |> pagination_model.to_string
  |> uuid.from_string
  |> result.map_error(fn(_) { db_error.DbQueryError("Invalid user cursor") })
}

fn query_error(error) -> db_error.DbQueryError {
  db_error.DbQueryError(string.inspect(error))
}

import gleam/option
import gleam/regexp
import gleam/result
import gleam/string
import gleam/time/timestamp.{type Timestamp}
import glot_backend/auth/ports/email_change_token_store
import glot_backend/sql
import glot_backend/system/database as db_helpers
import glot_backend/system/effect/error/db_error
import glot_core/auth/email_change_token_model
import glot_core/email/email_address_model
import glot_core/helpers/uuid_helpers
import youid/uuid

pub fn new(
  db: db_helpers.Db,
) -> email_change_token_store.EmailChangeTokenStore {
  email_change_token_store.EmailChangeTokenStore(
    list_by_user_id: fn(user_id, created_since, limit) {
      list_by_user_id(db, user_id, created_since, limit)
    },
    list_by_user_id_for_update: fn(user_id, created_since, limit) {
      list_by_user_id_for_update(db, user_id, created_since, limit)
    },
    create: fn(token) { create(db, token) },
    update: fn(token) { update(db, token) },
    delete_before: fn(before) { delete_before(db, before) },
  )
}

fn list_by_user_id_for_update(db, user_id, created_since, limit) {
  db_helpers.query(
    db,
    sql.list_email_change_tokens_by_user_id_for_update(
      user_id: uuid.to_bit_array(user_id),
      created_at: created_since,
      limit: limit,
    ),
    query_error,
  )
  |> result.try(fn(returned) { tokens_from_update_rows(returned.rows) })
}

fn list_by_user_id(db, user_id, created_since, limit) {
  db_helpers.query(
    db,
    sql.list_email_change_tokens_by_user_id(
      user_id: uuid.to_bit_array(user_id),
      created_at: created_since,
      limit: limit,
    ),
    query_error,
  )
  |> result.try(fn(returned) { tokens_from_rows(returned.rows) })
}

fn create(db, token: email_change_token_model.EmailChangeToken) {
  db_helpers.execute(
    db,
    sql.insert_email_change_token(
      id: uuid.to_bit_array(token.id),
      user_id: uuid.to_bit_array(token.user_id),
      old_email: email_address_model.to_string(token.old_email),
      new_email: email_address_model.to_string(token.new_email),
      token: token.token,
      attempt_count: token.attempt_count,
      created_at: token.created_at,
      used_at: token.used_at,
    ),
    command_error,
  )
  |> result.map(fn(_) { Nil })
}

fn update(db, token: email_change_token_model.EmailChangeToken) {
  db_helpers.execute(
    db,
    sql.update_email_change_token(
      old_email: email_address_model.to_string(token.old_email),
      new_email: email_address_model.to_string(token.new_email),
      token: token.token,
      attempt_count: token.attempt_count,
      created_at: token.created_at,
      used_at: token.used_at,
      id: uuid.to_bit_array(token.id),
    ),
    command_error,
  )
  |> result.map(fn(_) { Nil })
}

fn delete_before(db, before: Timestamp) {
  db_helpers.execute(
    db,
    sql.delete_email_change_tokens_before(before),
    command_error,
  )
  |> result.map(fn(_) { Nil })
}

fn tokens_from_rows(rows: List(sql.ListEmailChangeTokensByUserId)) {
  case rows {
    [] -> Ok([])
    [first, ..rest] -> {
      use token <- result.try(token_from_row(first))
      use tokens <- result.try(tokens_from_rows(rest))
      Ok([token, ..tokens])
    }
  }
}

fn tokens_from_update_rows(
  rows: List(sql.ListEmailChangeTokensByUserIdForUpdate),
) {
  case rows {
    [] -> Ok([])
    [first, ..rest] -> {
      use token <- result.try(token_from_update_row(first))
      use tokens <- result.try(tokens_from_update_rows(rest))
      Ok([token, ..tokens])
    }
  }
}

fn token_from_row(row: sql.ListEmailChangeTokensByUserId) {
  token_from_values(
    row.id,
    row.user_id,
    row.old_email,
    row.new_email,
    row.token,
    row.attempt_count,
    row.created_at,
    row.used_at,
  )
}

fn token_from_update_row(row: sql.ListEmailChangeTokensByUserIdForUpdate) {
  token_from_values(
    row.id,
    row.user_id,
    row.old_email,
    row.new_email,
    row.token,
    row.attempt_count,
    row.created_at,
    row.used_at,
  )
}

fn token_from_values(
  id,
  user_id,
  old_email_value,
  new_email_value,
  token,
  attempt_count,
  created_at,
  used_at,
) {
  let assert Ok(is_email) = regexp.from_string(email_address_model.pattern)
  use old_email <- result.try(option.to_result(
    email_address_model.from_string(is_email, old_email_value),
    db_error.DbQueryError("Invalid old email in email change token"),
  ))
  use new_email <- result.try(option.to_result(
    email_address_model.from_string(is_email, new_email_value),
    db_error.DbQueryError("Invalid new email in email change token"),
  ))
  Ok(email_change_token_model.EmailChangeToken(
    id: uuid_helpers.from_bit_array(id),
    user_id: uuid_helpers.from_bit_array(user_id),
    old_email:,
    new_email:,
    token:,
    attempt_count:,
    created_at:,
    used_at:,
  ))
}

fn query_error(error) -> db_error.DbQueryError {
  db_error.DbQueryError(string.inspect(error))
}

fn command_error(error) -> db_error.DbCommandError {
  db_error.DbCommandError(string.inspect(error))
}

import gleam/option
import gleam/regexp
import gleam/result
import gleam/string
import gleam/time/timestamp.{type Timestamp}
import glot_backend/auth/ports/login_token_store
import glot_backend/sql
import glot_backend/system/database as db_helpers
import glot_backend/system/effect/error/db_error
import glot_core/auth/login_token_model
import glot_core/email/email_address_model
import glot_core/helpers/uuid_helpers
import youid/uuid

pub fn new(db: db_helpers.Db) -> login_token_store.LoginTokenStore {
  login_token_store.LoginTokenStore(
    list_by_email: fn(email, created_since, limit) {
      list_by_email(db, email, created_since, limit)
    },
    create: fn(token) { create(db, token) },
    update: fn(token) { update(db, token) },
    delete_before: fn(before) { delete_before(db, before) },
    invalidate_by_emails: fn(old_email, new_email, timestamp) {
      db_helpers.execute(
        db,
        sql.invalidate_login_tokens_by_emails(
          used_at: option.Some(timestamp),
          old_email: email_address_model.to_string(old_email),
          new_email: email_address_model.to_string(new_email),
        ),
        fn(err) { db_error.DbCommandError(string.inspect(err)) },
      )
      |> result.map(fn(_) { Nil })
    },
  )
}

fn list_by_email(
  db: db_helpers.Db,
  email: email_address_model.EmailAddress,
  created_since: Timestamp,
  limit: Int,
) -> Result(List(login_token_model.LoginToken), db_error.DbQueryError) {
  db_helpers.query(
    db,
    sql.list_login_tokens_by_email(
      email: email_address_model.to_string(email),
      created_at: created_since,
      limit: limit,
    ),
    fn(err) { db_error.DbQueryError(string.inspect(err)) },
  )
  |> result.try(fn(returned) { login_tokens_from_rows(returned.rows) })
}

fn create(
  db: db_helpers.Db,
  login_token: login_token_model.LoginToken,
) -> Result(Nil, db_error.DbCommandError) {
  let to_error = fn(err) { db_error.DbCommandError(string.inspect(err)) }

  db_helpers.execute(
    db,
    sql.insert_login_token(
      id: uuid.to_bit_array(login_token.id),
      email: email_address_model.to_string(login_token.email),
      token: login_token.token,
      attempt_count: login_token.attempt_count,
      created_at: login_token.created_at,
      used_at: login_token.used_at,
    ),
    to_error,
  )
  |> result.map(fn(_) { Nil })
}

fn update(
  db: db_helpers.Db,
  login_token: login_token_model.LoginToken,
) -> Result(Nil, db_error.DbCommandError) {
  let to_error = fn(err) { db_error.DbCommandError(string.inspect(err)) }

  db_helpers.execute(
    db,
    sql.update_login_token(
      email: email_address_model.to_string(login_token.email),
      token: login_token.token,
      attempt_count: login_token.attempt_count,
      created_at: login_token.created_at,
      used_at: login_token.used_at,
      id: uuid.to_bit_array(login_token.id),
    ),
    to_error,
  )
  |> result.map(fn(_) { Nil })
}

fn delete_before(
  db: db_helpers.Db,
  before: Timestamp,
) -> Result(Nil, db_error.DbCommandError) {
  let to_error = fn(err) { db_error.DbCommandError(string.inspect(err)) }

  db_helpers.execute(db, sql.delete_login_tokens_before(before), to_error)
  |> result.map(fn(_) { Nil })
}

fn login_tokens_from_rows(
  rows: List(sql.ListLoginTokensByEmail),
) -> Result(List(login_token_model.LoginToken), db_error.DbQueryError) {
  case rows {
    [] -> Ok([])
    [first, ..rest] -> {
      use token <- result.try(login_token_from_row(first))
      use tokens <- result.try(login_tokens_from_rows(rest))
      Ok([token, ..tokens])
    }
  }
}

fn login_token_from_row(
  row: sql.ListLoginTokensByEmail,
) -> Result(login_token_model.LoginToken, db_error.DbQueryError) {
  let assert Ok(is_email) = regexp.from_string(email_address_model.pattern)

  case email_address_model.from_string(is_email, row.email) {
    option.Some(valid_email) ->
      Ok(login_token_model.LoginToken(
        id: uuid_helpers.from_bit_array(row.id),
        email: valid_email,
        token: row.token,
        attempt_count: row.attempt_count,
        created_at: row.created_at,
        used_at: row.used_at,
      ))
    option.None ->
      Error(db_error.DbQueryError(
        "Invalid email format in login token row: " <> row.email,
      ))
  }
}

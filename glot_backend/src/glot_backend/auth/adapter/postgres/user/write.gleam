import gleam/result
import gleam/string
import gleam/time/timestamp.{type Timestamp}
import glot_backend/sql
import glot_backend/system/database as db_helpers
import glot_backend/system/effect/error/db_error
import glot_core/auth/user_model.{type User}
import glot_core/email/email_address_model
import youid/uuid.{type Uuid}

pub fn create(
  db: db_helpers.Db,
  user: User,
) -> Result(Nil, db_error.DbCommandError) {
  db_helpers.execute(
    db,
    sql.insert_user(
      id: uuid.to_bit_array(user.id),
      account_id: uuid.to_bit_array(user.account_id),
      email: email_address_model.to_string(user.email),
      username: user.username,
      role: user_model.role_to_string(user.role),
      last_login_at: user.last_login_at,
      created_at: user.created_at,
      updated_at: user.updated_at,
    ),
    command_error,
  )
  |> result.map(fn(_) { Nil })
}

pub fn delete_by_account_id(
  db: db_helpers.Db,
  account_id: Uuid,
) -> Result(Nil, db_error.DbCommandError) {
  db_helpers.execute(
    db,
    sql.delete_users_by_account_id(uuid.to_bit_array(account_id)),
    command_error,
  )
  |> result.map(fn(_) { Nil })
}

fn command_error(error) -> db_error.DbCommandError {
  db_error.DbCommandError(string.inspect(error))
}

pub fn update_last_login(
  db: db_helpers.Db,
  id: Uuid,
  timestamp: Timestamp,
) -> Result(Nil, db_error.DbCommandError) {
  db_helpers.execute(
    db,
    sql.update_user_last_login(
      last_login_at: timestamp,
      updated_at: timestamp,
      id: uuid.to_bit_array(id),
    ),
    command_error,
  )
  |> result.map(fn(_) { Nil })
}

pub fn lock_email(
  db: db_helpers.Db,
  email: email_address_model.EmailAddress,
) -> Result(Nil, db_error.DbCommandError) {
  db_helpers.execute(
    db,
    sql.lock_email(email_address_model.to_string(email)),
    command_error,
  )
  |> result.map(fn(_) { Nil })
}

pub fn update_email(
  db: db_helpers.Db,
  id: Uuid,
  email: email_address_model.EmailAddress,
  timestamp: Timestamp,
) -> Result(Nil, db_error.DbCommandError) {
  db_helpers.execute(
    db,
    sql.update_user_email(
      email: email_address_model.to_string(email),
      updated_at: timestamp,
      id: uuid.to_bit_array(id),
    ),
    command_error,
  )
  |> result.map(fn(_) { Nil })
}

pub fn update_username(
  db: db_helpers.Db,
  id: Uuid,
  username: String,
  timestamp: Timestamp,
) -> Result(Nil, db_error.DbCommandError) {
  db_helpers.execute(
    db,
    sql.update_user_username(
      username:,
      updated_at: timestamp,
      id: uuid.to_bit_array(id),
    ),
    command_error,
  )
  |> result.map(fn(_) { Nil })
}

pub fn update_role(
  db: db_helpers.Db,
  id: Uuid,
  role: user_model.UserRole,
  timestamp: Timestamp,
) -> Result(Nil, db_error.DbCommandError) {
  db_helpers.execute(
    db,
    sql.update_user_role(
      role: user_model.role_to_string(role),
      updated_at: timestamp,
      id: uuid.to_bit_array(id),
    ),
    command_error,
  )
  |> result.map(fn(_) { Nil })
}

import gleam/list
import gleam/option
import gleam/regexp
import gleam/result
import gleam/time/timestamp.{type Timestamp}
import glot_backend/sql
import glot_backend/system/effect/error/db_error
import glot_core/auth/account_model
import glot_core/auth/user_model
import glot_core/email/email_address_model
import glot_core/helpers/uuid_helpers

pub fn hydrated_from_email_rows(
  is_email: regexp.Regexp,
  rows: List(sql.GetUserByEmail),
) -> Result(option.Option(user_model.HydratedUser), db_error.DbQueryError) {
  decode_optional(rows, fn(row) { from_email_row(is_email, row) })
}

pub fn hydrated_from_id_rows(
  is_email: regexp.Regexp,
  rows: List(sql.GetUserById),
) -> Result(option.Option(user_model.HydratedUser), db_error.DbQueryError) {
  decode_optional(rows, fn(row) { from_id_row(is_email, row) })
}

pub fn hydrated_from_id_for_update_rows(
  is_email: regexp.Regexp,
  rows: List(sql.GetUserByIdForUpdate),
) -> Result(option.Option(user_model.HydratedUser), db_error.DbQueryError) {
  decode_optional(rows, fn(row) { from_id_for_update_row(is_email, row) })
}

pub fn hydrated_from_after_rows(
  is_email: regexp.Regexp,
  rows: List(sql.ListUsersAfter),
) -> Result(List(user_model.HydratedUser), db_error.DbQueryError) {
  rows
  |> list.map(fn(row) { from_after_row(is_email, row) })
  |> result.all
}

pub fn hydrated_from_before_rows(
  is_email: regexp.Regexp,
  rows: List(sql.ListUsersBefore),
) -> Result(List(user_model.HydratedUser), db_error.DbQueryError) {
  rows
  |> list.map(fn(row) { from_before_row(is_email, row) })
  |> result.all
}

fn decode_optional(
  rows: List(row),
  decoder: fn(row) -> Result(user_model.HydratedUser, db_error.DbQueryError),
) -> Result(option.Option(user_model.HydratedUser), db_error.DbQueryError) {
  case rows {
    [] -> Ok(option.None)
    [row] -> decoder(row) |> result.map(option.Some)
    _ -> Error(db_error.DbQueryError("Expected at most one user row"))
  }
}

fn from_email_row(
  is_email: regexp.Regexp,
  row: sql.GetUserByEmail,
) -> Result(user_model.HydratedUser, db_error.DbQueryError) {
  from_fields(
    is_email: is_email,
    id: row.id,
    account_id: row.account_id,
    email: row.email,
    username: row.username,
    role_name: row.role,
    account_state_name: row.account_state,
    account_state_reason: row.account_state_reason,
    account_tier_name: row.account_tier,
    delete_job_id: row.delete_job_id,
    delete_scheduled_at: row.delete_scheduled_at,
    last_login_at: row.last_login_at,
    created_at: row.created_at,
    updated_at: row.updated_at,
  )
}

fn from_id_row(
  is_email: regexp.Regexp,
  row: sql.GetUserById,
) -> Result(user_model.HydratedUser, db_error.DbQueryError) {
  from_fields(
    is_email: is_email,
    id: row.id,
    account_id: row.account_id,
    email: row.email,
    username: row.username,
    role_name: row.role,
    account_state_name: row.account_state,
    account_state_reason: row.account_state_reason,
    account_tier_name: row.account_tier,
    delete_job_id: row.delete_job_id,
    delete_scheduled_at: row.delete_scheduled_at,
    last_login_at: row.last_login_at,
    created_at: row.created_at,
    updated_at: row.updated_at,
  )
}

fn from_id_for_update_row(
  is_email: regexp.Regexp,
  row: sql.GetUserByIdForUpdate,
) -> Result(user_model.HydratedUser, db_error.DbQueryError) {
  from_fields(
    is_email:,
    id: row.id,
    account_id: row.account_id,
    email: row.email,
    username: row.username,
    role_name: row.role,
    account_state_name: row.account_state,
    account_state_reason: row.account_state_reason,
    account_tier_name: row.account_tier,
    delete_job_id: row.delete_job_id,
    delete_scheduled_at: row.delete_scheduled_at,
    last_login_at: row.last_login_at,
    created_at: row.created_at,
    updated_at: row.updated_at,
  )
}

fn from_after_row(
  is_email: regexp.Regexp,
  row: sql.ListUsersAfter,
) -> Result(user_model.HydratedUser, db_error.DbQueryError) {
  from_fields(
    is_email: is_email,
    id: row.id,
    account_id: row.account_id,
    email: row.email,
    username: row.username,
    role_name: row.role,
    account_state_name: row.account_state,
    account_state_reason: row.account_state_reason,
    account_tier_name: row.account_tier,
    delete_job_id: row.delete_job_id,
    delete_scheduled_at: row.delete_scheduled_at,
    last_login_at: row.last_login_at,
    created_at: row.created_at,
    updated_at: row.updated_at,
  )
}

fn from_before_row(
  is_email: regexp.Regexp,
  row: sql.ListUsersBefore,
) -> Result(user_model.HydratedUser, db_error.DbQueryError) {
  from_fields(
    is_email: is_email,
    id: row.id,
    account_id: row.account_id,
    email: row.email,
    username: row.username,
    role_name: row.role,
    account_state_name: row.account_state,
    account_state_reason: row.account_state_reason,
    account_tier_name: row.account_tier,
    delete_job_id: row.delete_job_id,
    delete_scheduled_at: row.delete_scheduled_at,
    last_login_at: row.last_login_at,
    created_at: row.created_at,
    updated_at: row.updated_at,
  )
}

fn from_fields(
  is_email is_email: regexp.Regexp,
  id id: BitArray,
  account_id account_id: BitArray,
  email email: String,
  username username: String,
  role_name role_name: String,
  account_state_name account_state_name: String,
  account_state_reason account_state_reason: option.Option(String),
  account_tier_name account_tier_name: String,
  delete_job_id delete_job_id: option.Option(BitArray),
  delete_scheduled_at delete_scheduled_at: option.Option(Timestamp),
  last_login_at last_login_at: Timestamp,
  created_at created_at: Timestamp,
  updated_at updated_at: Timestamp,
) -> Result(user_model.HydratedUser, db_error.DbQueryError) {
  use valid_email <- result.try(
    email_address_model.from_string(is_email, email)
    |> option.to_result(db_error.DbQueryError(
      "Invalid email format in user row: " <> email,
    )),
  )
  use role <- result.try(
    user_model.role_from_string(role_name)
    |> option.to_result(db_error.DbQueryError(
      "Invalid user role: " <> role_name,
    )),
  )
  use account_state <- result.try(
    account_model.account_state_from_string(account_state_name)
    |> option.to_result(db_error.DbQueryError(
      "Invalid account state: " <> account_state_name,
    )),
  )
  use account_tier <- result.try(
    account_model.account_tier_from_string(account_tier_name)
    |> option.to_result(db_error.DbQueryError(
      "Invalid account tier: " <> account_tier_name,
    )),
  )

  Ok(user_model.HydratedUser(
    identity: user_model.User(
      id: uuid_helpers.from_bit_array(id),
      account_id: uuid_helpers.from_bit_array(account_id),
      email: valid_email,
      username: username,
      role: role,
      last_login_at: last_login_at,
      created_at: created_at,
      updated_at: updated_at,
    ),
    account: account_model.HydratedAccount(
      identity: account_model.Account(
        id: uuid_helpers.from_bit_array(account_id),
        account_state: account_state,
        account_state_reason: account_state_reason,
        account_tier: account_tier,
        delete_job_id: delete_job_id |> option.map(uuid_helpers.from_bit_array),
        created_at: created_at,
        updated_at: updated_at,
      ),
      delete_scheduled_at: delete_scheduled_at,
    ),
  ))
}

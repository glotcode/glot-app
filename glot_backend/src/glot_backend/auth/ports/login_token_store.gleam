import gleam/time/timestamp.{type Timestamp}
import glot_backend/system/effect/error/db_error
import glot_core/auth/login_token_model
import glot_core/email/email_address_model

pub type LoginTokenStore {
  LoginTokenStore(
    list_by_email: fn(email_address_model.EmailAddress, Timestamp, Int) ->
      Result(List(login_token_model.LoginToken), db_error.DbQueryError),
    create: fn(login_token_model.LoginToken) ->
      Result(Nil, db_error.DbCommandError),
    update: fn(login_token_model.LoginToken) ->
      Result(Nil, db_error.DbCommandError),
    delete_before: fn(Timestamp) -> Result(Nil, db_error.DbCommandError),
    invalidate_by_emails: fn(
      email_address_model.EmailAddress,
      email_address_model.EmailAddress,
      Timestamp,
    ) -> Result(Nil, db_error.DbCommandError),
  )
}

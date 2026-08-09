import gleam/time/timestamp.{type Timestamp}
import glot_backend/system/effect/error/db_error
import glot_core/auth/email_change_token_model.{type EmailChangeToken}
import youid/uuid.{type Uuid}

pub type EmailChangeTokenStore {
  EmailChangeTokenStore(
    list_by_user_id: fn(Uuid, Timestamp, Int) ->
      Result(List(EmailChangeToken), db_error.DbQueryError),
    list_by_user_id_for_update: fn(Uuid, Timestamp, Int) ->
      Result(List(EmailChangeToken), db_error.DbQueryError),
    create: fn(EmailChangeToken) -> Result(Nil, db_error.DbCommandError),
    update: fn(EmailChangeToken) -> Result(Nil, db_error.DbCommandError),
    delete_before: fn(Timestamp) -> Result(Nil, db_error.DbCommandError),
  )
}

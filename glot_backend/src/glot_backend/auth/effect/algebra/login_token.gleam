import gleam/time/timestamp.{type Timestamp}
import glot_backend/system/effect/error/db_error
import glot_core/auth/login_token_model
import glot_core/email/email_address_model

pub type Effect(next) {
  ListLoginTokensByEmail(
    email: email_address_model.EmailAddress,
    created_since: Timestamp,
    limit: Int,
    next: fn(List(login_token_model.LoginToken)) -> next,
  )
  CreateLoginToken(
    login_token: login_token_model.LoginToken,
    next: fn(Result(Nil, db_error.DbCommandError)) -> next,
  )
  UpdateLoginToken(
    login_token: login_token_model.LoginToken,
    next: fn(Result(Nil, db_error.DbCommandError)) -> next,
  )
  DeleteLoginTokensBefore(
    before: Timestamp,
    next: fn(Result(Nil, db_error.DbCommandError)) -> next,
  )
  InvalidateLoginTokensByEmails(
    old_email: email_address_model.EmailAddress,
    new_email: email_address_model.EmailAddress,
    timestamp: Timestamp,
    next: fn(Result(Nil, db_error.DbCommandError)) -> next,
  )
}

pub type EffectName {
  ListLoginTokensByEmailEffectName
  CreateLoginTokenEffectName
  UpdateLoginTokenEffectName
  DeleteLoginTokensBeforeEffectName
  InvalidateLoginTokensByEmailsEffectName
}

pub fn map(effect: Effect(a), f: fn(a) -> b) -> Effect(b) {
  case effect {
    ListLoginTokensByEmail(email:, created_since:, limit:, next:) ->
      ListLoginTokensByEmail(
        email: email,
        created_since: created_since,
        limit: limit,
        next: fn(value) { f(next(value)) },
      )
    CreateLoginToken(login_token: login_token, next: next) ->
      CreateLoginToken(login_token: login_token, next: fn(value) {
        f(next(value))
      })
    UpdateLoginToken(login_token: login_token, next: next) ->
      UpdateLoginToken(login_token: login_token, next: fn(value) {
        f(next(value))
      })
    DeleteLoginTokensBefore(before: before, next: next) ->
      DeleteLoginTokensBefore(before: before, next: fn(value) { f(next(value)) })
    InvalidateLoginTokensByEmails(old_email:, new_email:, timestamp:, next:) ->
      InvalidateLoginTokensByEmails(
        old_email:,
        new_email:,
        timestamp:,
        next: fn(value) { f(next(value)) },
      )
  }
}

pub fn effect_name_to_string(name: EffectName) -> String {
  case name {
    ListLoginTokensByEmailEffectName -> "list_login_tokens_by_email"
    CreateLoginTokenEffectName -> "create_login_token"
    UpdateLoginTokenEffectName -> "update_login_token"
    DeleteLoginTokensBeforeEffectName -> "delete_login_tokens_before"
    InvalidateLoginTokensByEmailsEffectName ->
      "invalidate_login_tokens_by_emails"
  }
}

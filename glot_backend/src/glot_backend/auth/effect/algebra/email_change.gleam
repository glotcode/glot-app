import gleam/time/timestamp.{type Timestamp}
import glot_backend/system/effect/error/db_error
import glot_core/auth/email_change_token_model.{type EmailChangeToken}
import youid/uuid.{type Uuid}

pub type Effect(next) {
  ListEmailChangeTokensByUserId(
    user_id: Uuid,
    created_since: Timestamp,
    limit: Int,
    next: fn(List(EmailChangeToken)) -> next,
  )
  ListEmailChangeTokensByUserIdForUpdate(
    user_id: Uuid,
    created_since: Timestamp,
    limit: Int,
    next: fn(List(EmailChangeToken)) -> next,
  )
  CreateEmailChangeToken(
    token: EmailChangeToken,
    next: fn(Result(Nil, db_error.DbCommandError)) -> next,
  )
  UpdateEmailChangeToken(
    token: EmailChangeToken,
    next: fn(Result(Nil, db_error.DbCommandError)) -> next,
  )
  DeleteEmailChangeTokensBefore(
    before: Timestamp,
    next: fn(Result(Nil, db_error.DbCommandError)) -> next,
  )
}

pub type EffectName {
  ListEmailChangeTokensByUserIdEffectName
  ListEmailChangeTokensByUserIdForUpdateEffectName
  CreateEmailChangeTokenEffectName
  UpdateEmailChangeTokenEffectName
  DeleteEmailChangeTokensBeforeEffectName
}

pub fn map(effect: Effect(a), f: fn(a) -> b) -> Effect(b) {
  case effect {
    ListEmailChangeTokensByUserId(user_id:, created_since:, limit:, next:) ->
      ListEmailChangeTokensByUserId(
        user_id:,
        created_since:,
        limit:,
        next: fn(value) { f(next(value)) },
      )
    ListEmailChangeTokensByUserIdForUpdate(
      user_id:,
      created_since:,
      limit:,
      next:,
    ) ->
      ListEmailChangeTokensByUserIdForUpdate(
        user_id:,
        created_since:,
        limit:,
        next: fn(value) { f(next(value)) },
      )
    CreateEmailChangeToken(token:, next:) ->
      CreateEmailChangeToken(token:, next: fn(value) { f(next(value)) })
    UpdateEmailChangeToken(token:, next:) ->
      UpdateEmailChangeToken(token:, next: fn(value) { f(next(value)) })
    DeleteEmailChangeTokensBefore(before:, next:) ->
      DeleteEmailChangeTokensBefore(before:, next: fn(value) { f(next(value)) })
  }
}

pub fn effect_name_to_string(name: EffectName) -> String {
  case name {
    ListEmailChangeTokensByUserIdEffectName ->
      "list_email_change_tokens_by_user_id"
    ListEmailChangeTokensByUserIdForUpdateEffectName ->
      "list_email_change_tokens_by_user_id_for_update"
    CreateEmailChangeTokenEffectName -> "create_email_change_token"
    UpdateEmailChangeTokenEffectName -> "update_email_change_token"
    DeleteEmailChangeTokensBeforeEffectName ->
      "delete_email_change_tokens_before"
  }
}

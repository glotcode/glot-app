import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}
import glot_core/email/email_address_model.{type EmailAddress}
import youid/uuid.{type Uuid}

pub type EmailChangeToken {
  EmailChangeToken(
    id: Uuid,
    user_id: Uuid,
    old_email: EmailAddress,
    new_email: EmailAddress,
    token: String,
    attempt_count: Int,
    created_at: Timestamp,
    used_at: Option(Timestamp),
  )
}

pub fn increment_attempt(
  token: EmailChangeToken,
  shared_attempt_count: Int,
) -> EmailChangeToken {
  EmailChangeToken(..token, attempt_count: shared_attempt_count + 1)
}

pub fn mark_as_used(
  token: EmailChangeToken,
  timestamp: Timestamp,
) -> EmailChangeToken {
  EmailChangeToken(..token, used_at: option.Some(timestamp))
}

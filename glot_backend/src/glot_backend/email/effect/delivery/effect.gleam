import glot_backend/email/effect/delivery/algebra as email_algebra
import glot_backend/system/effect/error
import glot_backend/system/effect/program_types
import glot_core/email/email_model.{type Email, type SendEmailResult}

pub fn send_email(message: Email) -> program_types.Program(SendEmailResult) {
  program_types.Impure(
    program_types.EmailEffect(email_algebra.SendEmail(message, from_result)),
  )
}

fn from_result(
  result: Result(SendEmailResult, error.Error),
) -> program_types.Program(SendEmailResult) {
  case result {
    Ok(value) -> program_types.Pure(value)
    Error(err) -> program_types.Fail(err)
  }
}

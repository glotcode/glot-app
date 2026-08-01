import gleam/dict
import gleam/option.{type Option}
import gleam/regexp.{type Regexp}
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/email/domain/preparation as email_preparation
import glot_backend/email/model/template as email_template
import glot_backend/system/effect/error/infra_error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_core/auth/session_model.{type HydratedSession}
import glot_core/contact_dto.{type ValidatedContact}
import glot_core/email/email_address_model.{type EmailAddress}
import glot_core/email/email_model.{type Email}
import youid/uuid

pub fn prepare_contact_email(
  request_ctx: RequestContext,
  contact: ValidatedContact,
  maybe_session: Option(HydratedSession),
) -> Program(Email) {
  let ctx = request_ctx.context
  let config = dynamic_config.email_config(request_ctx.dynamic_config)

  use recipient <- program.and_then(require_contact_recipient(
    config.contact_address,
    ctx.regexes.is_email,
  ))
  use sender <- program.and_then(email_preparation.require_sender(
    config,
    ctx.regexes.is_email,
  ))

  email_preparation.render_template(
    email_template.ContactTemplate,
    sender,
    recipient,
    dict.from_list([
      #("email", email_address_model.to_string(contact.email)),
      #("topic", contact_dto.topic_label(contact.topic)),
      #("message", contact.message),
      #("user_id", authenticated_user_id(maybe_session)),
      #("request_id", uuid.to_string(ctx.request_id)),
    ]),
  )
}

fn require_contact_recipient(
  raw_address: Option(String),
  is_email: Regexp,
) -> Program(EmailAddress) {
  use address <- program.and_then(
    raw_address
    |> option.to_result(infra_error.EmailDeliveryFailed(
      "contact_address_not_configured",
      infra_error.NonRetryable,
    ))
    |> email_preparation.from_email_result,
  )

  email_address_model.from_string(is_email, address)
  |> option.to_result(infra_error.EmailDeliveryFailed(
    "invalid_contact_address",
    infra_error.NonRetryable,
  ))
  |> email_preparation.from_email_result
}

fn authenticated_user_id(maybe_session: Option(HydratedSession)) -> String {
  maybe_session
  |> option.map(fn(session) { uuid.to_string(session.user.identity.id) })
  |> option.unwrap("anonymous")
}

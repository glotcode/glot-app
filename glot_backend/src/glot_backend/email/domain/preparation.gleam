import gleam/dict.{type Dict}
import gleam/option
import gleam/regexp.{type Regexp}
import gleam/result
import glot_backend/email/effect/template/effect as email_template_effect
import glot_backend/email/model/config.{type EmailConfig}
import glot_backend/email/model/template.{
  type EmailTemplate, type EmailTemplateName,
} as email_template
import glot_backend/system/effect/basic/basic_effect
import glot_backend/system/effect/error
import glot_backend/system/effect/error/infra_error.{type EmailError}
import glot_backend/system/effect/log
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_core/email/email_address_model.{type EmailAddress}
import glot_core/email/email_model.{type Email, type EmailSender}

pub fn require_sender(
  config: EmailConfig,
  is_email: Regexp,
) -> Program(EmailSender) {
  use address <- program.and_then(
    email_address_model.from_string(is_email, config.from_address)
    |> option.to_result(infra_error.EmailDeliveryFailed(
      "invalid_sender_address",
      infra_error.NonRetryable,
    ))
    |> from_email_result,
  )

  program.succeed(email_model.EmailSender(
    address: address,
    name: config.from_name,
  ))
}

pub fn render_template(
  name: EmailTemplateName,
  sender: EmailSender,
  recipient: EmailAddress,
  variables: Dict(String, String),
) -> Program(Email) {
  use template <- program.and_then(require_template(name))

  email_template.render_email_template(template, sender, recipient, variables)
  |> result.map_error(infra_error.EmailTemplateRenderFailed)
  |> from_email_result
}

fn require_template(name: EmailTemplateName) -> Program(EmailTemplate) {
  use maybe_template <- program.and_then(
    email_template_effect.get_email_template_by_name(name),
  )

  maybe_template
  |> option.to_result(
    infra_error.EmailTemplateMissing(email_template.to_db_name(name)),
  )
  |> from_email_result
}

pub fn from_email_result(result: Result(a, EmailError)) -> Program(a) {
  case result {
    Ok(value) -> program.succeed(value)
    Error(email_error) -> {
      let app_error = infra_error.EmailError(email_error)
      use _ <- program.and_then(
        basic_effect.warn(
          log.singleton(
            log.object("send_email_error", [
              log.string("message", infra_error.to_string(app_error)),
            ]),
          ),
        ),
      )
      program.fail(error.infra(app_error))
    }
  }
}

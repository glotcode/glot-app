import gleam/option
import gleam/regexp
import gleam/string
import glot_core/auth/account_dto
import glot_core/auth/email_change_dto
import glot_core/email/email_address_model
import glot_core/loadable
import glot_frontend/account/command
import glot_frontend/account/message.{
  type Msg, BeginEmailChangeSubmitted, ConfirmEmailChangeSubmitted,
  EmailChangeBegun, EmailChangeConfirmed, EmailCodeChanged, EmailInputChanged,
}
import glot_frontend/account/model.{
  type Model, AwaitingEmailCode, ConfirmingEmailCode,
  EmailChangeConfirmationError, EmailChangeIdle, EmailChangeRequestError,
  EmailChanged, Model, SendingEmailCode,
}
import glot_frontend/api/response as api_response
import glot_frontend/app/event as app_event

pub fn update(
  model: Model,
  msg: Msg,
) -> #(Model, command.Command(Msg), app_event.AppEvent) {
  case msg {
    EmailInputChanged(value) -> #(
      Model(
        ..model,
        email_input: value,
        email_code: "",
        email_change_status: EmailChangeIdle,
      ),
      command.none(),
      app_event.NoAppEvent,
    )
    EmailCodeChanged(value) -> #(
      Model(..model, email_code: value),
      command.none(),
      app_event.NoAppEvent,
    )
    BeginEmailChangeSubmitted -> begin(model)
    EmailChangeBegun(response) -> began(model, response)
    ConfirmEmailChangeSubmitted -> confirm(model)
    EmailChangeConfirmed(response) -> confirmed(model, response)
    _ -> #(model, command.none(), app_event.NoAppEvent)
  }
}

fn begin(model: Model) {
  let assert Ok(is_email) = regexp.from_string(email_address_model.pattern)
  case email_address_model.from_string(is_email, model.email_input) {
    option.None -> request_failure(model, "Enter a valid email address.")
    option.Some(email) -> {
      let current = case model.account {
        loadable.Loaded(account) -> option.Some(account.email)
        _ -> option.None
      }
      case current == option.Some(email) {
        True ->
          request_failure(
            model,
            "Enter an email address different from your current one.",
          )
        False -> #(
          Model(
            ..model,
            email_input: email_address_model.to_string(email),
            email_change_status: SendingEmailCode,
          ),
          command.BeginEmailChange(
            email_change_dto.BeginEmailChangeRequest(email:),
            EmailChangeBegun,
          ),
          app_event.NoAppEvent,
        )
      }
    }
  }
}

fn began(model: Model, response: api_response.Response(Nil)) {
  case response {
    api_response.Success(_) -> #(
      Model(..model, email_code: "", email_change_status: AwaitingEmailCode),
      command.none(),
      app_event.NoAppEvent,
    )
    api_response.ApiFailure(error) ->
      request_failure(model, api_response.error_message(error))
    api_response.HttpFailure(_) ->
      request_failure(model, "Could not send the verification code.")
  }
}

fn confirm(model: Model) {
  let code = string.trim(model.email_code)
  case can_confirm(model.email_change_status), code == "" {
    False, _ -> request_failure(model, "Request a new verification code.")
    _, True -> confirmation_failure(model, "Enter the verification code.")
    True, False -> #(
      Model(..model, email_code: code, email_change_status: ConfirmingEmailCode),
      command.ConfirmEmailChange(
        email_change_dto.ConfirmEmailChangeRequest(token: code),
        EmailChangeConfirmed,
      ),
      app_event.NoAppEvent,
    )
  }
}

fn confirmed(
  model: Model,
  response: api_response.Response(account_dto.AccountResponse),
) {
  case response {
    api_response.Success(account) -> #(
      Model(
        ..model,
        account: loadable.Loaded(account),
        email_input: email_address_model.to_string(account.email),
        email_code: "",
        email_change_status: EmailChanged,
      ),
      command.none(),
      app_event.RefreshSession,
    )
    api_response.ApiFailure(error) ->
      confirmation_failure(model, api_response.error_message(error))
    api_response.HttpFailure(_) ->
      confirmation_failure(model, "Could not verify the email change.")
  }
}

fn can_confirm(status) {
  case status {
    AwaitingEmailCode | ConfirmingEmailCode | EmailChangeConfirmationError(_) ->
      True
    _ -> False
  }
}

fn request_failure(model, message) {
  #(
    Model(..model, email_change_status: EmailChangeRequestError(message)),
    command.none(),
    app_event.NoAppEvent,
  )
}

fn confirmation_failure(model, message) {
  #(
    Model(..model, email_change_status: EmailChangeConfirmationError(message)),
    command.none(),
    app_event.NoAppEvent,
  )
}

import glot_frontend/account/message.{
  type Msg, BeginEmailChangeSubmitted, ConfirmEmailChangeSubmitted,
  EmailCodeChanged, EmailInputChanged,
}
import glot_frontend/account/model.{
  type EmailChangeStatus, type Model, AwaitingEmailCode, ConfirmingEmailCode,
  EmailChangeConfirmationError, EmailChangeRequestError, EmailChanged,
  SendingEmailCode,
}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("account-page__form")], [
    html.form(
      [
        attribute.class("account-page__form"),
        event.on_submit(fn(_) { BeginEmailChangeSubmitted }),
      ],
      [
        html.label(
          [
            attribute.for("account-email"),
            attribute.class("account-page__label"),
          ],
          [html.text("Email")],
        ),
        html.input([
          attribute.id("account-email"),
          attribute.name("email"),
          attribute.type_("email"),
          attribute.autocomplete("email"),
          attribute.value(model.email_input),
          event.on_input(EmailInputChanged),
          attribute.disabled(is_busy(model.email_change_status)),
          attribute.class("account-page__input"),
        ]),
        html.button(
          [
            attribute.type_("submit"),
            attribute.disabled(is_busy(model.email_change_status)),
            attribute.class("account-page__button"),
          ],
          [html.text(begin_button_text(model.email_change_status))],
        ),
      ],
    ),
    verification_form(model),
    status_view(model.email_change_status),
  ])
}

fn verification_form(model: Model) -> Element(Msg) {
  case can_confirm(model.email_change_status) {
    False -> html.text("")
    True ->
      html.form(
        [
          attribute.class("account-page__form"),
          event.on_submit(fn(_) { ConfirmEmailChangeSubmitted }),
        ],
        [
          html.p([attribute.class("account-page__status")], [
            html.text("Enter the verification code sent to the new address."),
          ]),
          html.label(
            [
              attribute.for("account-email-code"),
              attribute.class("account-page__label"),
            ],
            [html.text("Verification code")],
          ),
          html.input([
            attribute.id("account-email-code"),
            attribute.name("email-code"),
            attribute.type_("text"),
            attribute.autocomplete("one-time-code"),
            attribute.attribute("inputmode", "numeric"),
            attribute.value(model.email_code),
            event.on_input(EmailCodeChanged),
            attribute.disabled(is_confirming(model.email_change_status)),
            attribute.class("account-page__input"),
          ]),
          html.button(
            [
              attribute.type_("submit"),
              attribute.disabled(is_confirming(model.email_change_status)),
              attribute.class("account-page__button"),
            ],
            [html.text(confirm_button_text(model.email_change_status))],
          ),
        ],
      )
  }
}

fn status_view(status: EmailChangeStatus) -> Element(Msg) {
  case status {
    SendingEmailCode -> render_status("Sending verification code...", False)
    AwaitingEmailCode -> render_status("Verification code sent.", False)
    ConfirmingEmailCode -> render_status("Verifying email change...", False)
    EmailChanged -> render_status("Email address updated.", False)
    EmailChangeRequestError(message) | EmailChangeConfirmationError(message) ->
      render_status(message, True)
    _ -> html.text("")
  }
}

fn render_status(message: String, is_error: Bool) -> Element(Msg) {
  let class = case is_error {
    True -> "account-page__status account-page__status--error"
    False -> "account-page__status"
  }
  html.p(
    [
      attribute.class(class),
      attribute.attribute("role", case is_error {
        True -> "alert"
        False -> "status"
      }),
      attribute.attribute("aria-atomic", "true"),
    ],
    [html.text(message)],
  )
}

fn can_confirm(status: EmailChangeStatus) -> Bool {
  case status {
    AwaitingEmailCode | ConfirmingEmailCode | EmailChangeConfirmationError(_) ->
      True
    _ -> False
  }
}

fn is_busy(status: EmailChangeStatus) -> Bool {
  case status {
    SendingEmailCode | ConfirmingEmailCode -> True
    _ -> False
  }
}

fn is_confirming(status: EmailChangeStatus) -> Bool {
  status == ConfirmingEmailCode
}

fn begin_button_text(status: EmailChangeStatus) -> String {
  case status {
    SendingEmailCode -> "Sending..."
    AwaitingEmailCode | ConfirmingEmailCode | EmailChangeConfirmationError(_) ->
      "Send a new code"
    _ -> "Change email"
  }
}

fn confirm_button_text(status: EmailChangeStatus) -> String {
  case status {
    ConfirmingEmailCode -> "Verifying..."
    _ -> "Verify and change email"
  }
}

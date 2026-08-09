import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleam/string
import gleam/time/timestamp.{type Timestamp}
import glot_core/email/email_address_model
import glot_core/email/email_model
import glot_core/validation_error

pub type EmailTemplateName {
  LoginTokenTemplate
  AccountDeletedTemplate
  ContactTemplate
  EmailChangeVerificationTemplate
  EmailChangeAddressInUseTemplate
  EmailChangedTemplate
}

pub type EmailTemplate {
  EmailTemplate(
    name: EmailTemplateName,
    subject_template: String,
    text_body_template: String,
    html_body_template: Option(String),
    updated_at: Timestamp,
  )
}

pub fn to_db_name(name: EmailTemplateName) -> String {
  case name {
    LoginTokenTemplate -> "login_token"
    AccountDeletedTemplate -> "account_deleted"
    ContactTemplate -> "contact"
    EmailChangeVerificationTemplate -> "email_change_verification"
    EmailChangeAddressInUseTemplate -> "email_change_address_in_use"
    EmailChangedTemplate -> "email_changed"
  }
}

pub fn from_db_name(
  name: String,
) -> Result(EmailTemplateName, validation_error.ValidationError) {
  case name {
    "login_token" -> Ok(LoginTokenTemplate)
    "account_deleted" -> Ok(AccountDeletedTemplate)
    "contact" -> Ok(ContactTemplate)
    "email_change_verification" -> Ok(EmailChangeVerificationTemplate)
    "email_change_address_in_use" -> Ok(EmailChangeAddressInUseTemplate)
    "email_changed" -> Ok(EmailChangedTemplate)
    _ -> Error(validation_error.UnknownEmailTemplate(name))
  }
}

pub fn supported_tokens(name: EmailTemplateName) -> List(String) {
  case name {
    LoginTokenTemplate -> ["token"]
    AccountDeletedTemplate -> []
    ContactTemplate -> [
      "email",
      "topic",
      "message",
      "user_id",
      "request_id",
    ]
    EmailChangeVerificationTemplate -> ["token"]
    EmailChangeAddressInUseTemplate -> []
    EmailChangedTemplate -> ["new_email"]
  }
}

pub fn list_names() -> List(EmailTemplateName) {
  [
    LoginTokenTemplate,
    AccountDeletedTemplate,
    ContactTemplate,
    EmailChangeVerificationTemplate,
    EmailChangeAddressInUseTemplate,
    EmailChangedTemplate,
  ]
}

pub fn are_supported_tokens(
  name: EmailTemplateName,
  tokens: List(String),
) -> Bool {
  let supported = supported_tokens(name)
  list.all(tokens, fn(token) { list.contains(supported, token) })
}

pub fn render_email_template(
  template: EmailTemplate,
  from: email_model.EmailSender,
  to: email_address_model.EmailAddress,
  variables: Dict(String, String),
) -> Result(email_model.Email, String) {
  use _ <- result.try(
    validate_template(template)
    |> result.map_error(validation_error.message),
  )
  use _ <- result.try(validate_variables(template.name, variables))
  use subject <- result.try(render_template(
    template.subject_template,
    variables,
  ))
  use text_body <- result.try(render_template(
    template.text_body_template,
    variables,
  ))
  use html_body <- result.try(case template.html_body_template {
    option.Some(html) ->
      render_template(html, variables)
      |> result.map(option.Some)
    option.None -> Ok(option.None)
  })

  Ok(email_model.Email(
    from: from,
    to: to,
    subject: subject,
    text_body: text_body,
    html_body: html_body,
  ))
}

pub fn validate_template(
  template: EmailTemplate,
) -> Result(Nil, validation_error.ValidationError) {
  let supported_tokens = supported_tokens(template.name)
  use _ <- result.try(require_non_empty(
    template.subject_template,
    validation_error.EmptyField("subject_template"),
  ))
  use _ <- result.try(require_non_empty(
    template.text_body_template,
    validation_error.EmptyField("text_body_template"),
  ))
  use subject_tokens <- result.try(collect_tokens(template.subject_template))
  use text_body_tokens <- result.try(collect_tokens(template.text_body_template))
  use html_body_tokens <- result.try(case template.html_body_template {
    option.Some(html) -> collect_tokens(html)
    option.None -> Ok([])
  })

  let template_tokens =
    subject_tokens
    |> list.append(text_body_tokens)
    |> list.append(html_body_tokens)

  case are_supported_tokens(template.name, template_tokens) {
    True -> Ok(Nil)
    False ->
      Error(validation_error.UnsupportedEmailTemplateTokens(
        template_name: to_db_name(template.name),
        supported: supported_tokens,
      ))
  }
}

fn validate_variables(
  template_name: EmailTemplateName,
  variables: Dict(String, String),
) -> Result(Nil, String) {
  let supported = supported_tokens(template_name)
  let variable_names =
    variables
    |> dict.to_list
    |> list.map(fn(entry) { entry.0 })

  case are_supported_tokens(template_name, variable_names) {
    True -> Ok(Nil)
    False ->
      Error(
        "Unexpected email template variables for "
        <> to_db_name(template_name)
        <> ". Supported tokens: "
        <> string.join(supported, with: ", "),
      )
  }
}

fn render_template(
  template: String,
  variables: Dict(String, String),
) -> Result(String, String) {
  case string.split_once(template, "{{") {
    Error(_) -> Ok(template)
    Ok(#(prefix, remainder)) ->
      case string.split_once(remainder, "}}") {
        Error(_) -> Error("Unclosed template token in email template")
        Ok(#(raw_token, suffix)) -> {
          let token = string.trim(raw_token)
          use value <- result.try(
            dict.get(variables, token)
            |> result.map_error(fn(_) {
              "Missing email template variable: " <> token
            }),
          )
          use rendered_suffix <- result.try(render_template(suffix, variables))
          Ok(prefix <> value <> rendered_suffix)
        }
      }
  }
}

fn collect_tokens(
  template: String,
) -> Result(List(String), validation_error.ValidationError) {
  case string.split_once(template, "{{") {
    Error(_) -> Ok([])
    Ok(#(_, remainder)) ->
      case string.split_once(remainder, "}}") {
        Error(_) -> Error(validation_error.UnclosedEmailTemplateToken)
        Ok(#(raw_token, suffix)) -> {
          use rest <- result.try(collect_tokens(suffix))
          Ok([string.trim(raw_token), ..rest])
        }
      }
  }
}

fn require_non_empty(
  value: String,
  err: validation_error.ValidationError,
) -> Result(Nil, validation_error.ValidationError) {
  case string.trim(value) == "" {
    True -> Error(err)
    False -> Ok(Nil)
  }
}

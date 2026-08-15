import gleam/int
import gleam/string

pub type CursorKind {
  ApiLogCursor
  RunLogCursor
  JobLogCursor
}

pub type ValidationError {
  EmptyField(field: String)
  FieldTooLong(field: String, max: Int)
  FilesMissing
  InvalidCursor(kind: CursorKind)
  InvalidUsername
  InvalidLimit
  LimitTooLarge(max: Int)
  InvalidJobType(value: String)
  InvalidJobQueue(value: String)
  UnknownEmailTemplate(name: String)
  UnsupportedEmailTemplateTokens(template_name: String, supported: List(String))
  UnclosedEmailTemplateToken
  UnknownRunLanguage(image: String)
  ReadOnlyLanguage(language: String)
  InvalidEmail(field: String)
  InvalidContactTopic
  MustBeGreaterThan(field: String, min: Int)
  MustBeGreaterThanOrEqual(field: String, min: Int)
  MustBeLessThanOrEqual(field: String, max: Int)
  MustBeGreaterThanOrEqualField(field: String, other_field: String)
  RulesMissing
  SpamDetected(message: String)
}

pub fn code(err: ValidationError) -> String {
  case err {
    EmptyField(field) -> "validation_" <> field_slug(field) <> "_empty"
    FieldTooLong(field, _) -> "validation_" <> field_slug(field) <> "_too_long"
    FilesMissing -> "validation_files_missing"
    InvalidCursor(kind) ->
      "validation_" <> cursor_kind_slug(kind) <> "_cursor_invalid"
    InvalidUsername -> "validation_username_invalid"
    InvalidLimit -> "validation_limit_invalid"
    LimitTooLarge(_) -> "validation_limit_too_large"
    InvalidJobType(_) -> "validation_job_type_invalid"
    InvalidJobQueue(_) -> "validation_job_queue_invalid"
    UnknownEmailTemplate(_) -> "validation_email_template_unknown"
    UnsupportedEmailTemplateTokens(_, _) ->
      "validation_email_template_tokens_unsupported"
    UnclosedEmailTemplateToken -> "validation_email_template_token_unclosed"
    UnknownRunLanguage(_) -> "validation_unknown_run_language"
    ReadOnlyLanguage(_) -> "validation_language_read_only"
    InvalidEmail(field) -> "validation_" <> field_slug(field) <> "_invalid"
    InvalidContactTopic -> "validation_contact_topic_invalid"
    MustBeGreaterThan(field, _) ->
      "validation_" <> field_slug(field) <> "_too_small"
    MustBeGreaterThanOrEqual(field, _) ->
      "validation_" <> field_slug(field) <> "_too_small"
    MustBeLessThanOrEqual(field, _) ->
      "validation_" <> field_slug(field) <> "_too_large"
    MustBeGreaterThanOrEqualField(field, _) ->
      "validation_" <> field_slug(field) <> "_too_small"
    RulesMissing -> "validation_rules_missing"
    SpamDetected(_) -> "validation_spam_detected"
  }
}

pub fn message(err: ValidationError) -> String {
  case err {
    EmptyField(field) -> field <> " must not be empty"
    FieldTooLong(field, max) ->
      field <> " must be at most " <> int.to_string(max) <> " characters"
    FilesMissing -> "files must contain at least one file"
    InvalidCursor(kind) -> "Invalid " <> cursor_kind_label(kind) <> " cursor"
    InvalidUsername ->
      "Invalid username: use 3-40 lowercase letters, digits, dots, or hyphens"
    InvalidLimit -> "limit must be greater than 0"
    LimitTooLarge(max) ->
      "limit must be less than or equal to " <> int.to_string(max)
    InvalidJobType(value) -> "Invalid job type: " <> value
    InvalidJobQueue(value) -> "Invalid job queue: " <> value
    UnknownEmailTemplate(name) -> "Unknown email template: " <> name
    UnsupportedEmailTemplateTokens(template_name, supported) ->
      "Email template contains unsupported tokens for "
      <> template_name
      <> ". Supported tokens: "
      <> string.join(supported, with: ", ")
    UnclosedEmailTemplateToken -> "Unclosed template token in email template"
    UnknownRunLanguage(image) -> "Unknown run language for image: " <> image
    ReadOnlyLanguage(language) -> language <> " snippets are read-only"
    InvalidEmail(field) -> field <> " must be a valid email address"
    InvalidContactTopic -> "contact topic is invalid"
    MustBeGreaterThan(field, min) ->
      field <> " must be greater than " <> int.to_string(min)
    MustBeGreaterThanOrEqual(field, min) ->
      field <> " must be greater than or equal to " <> int.to_string(min)
    MustBeLessThanOrEqual(field, max) ->
      field <> " must be less than or equal to " <> int.to_string(max)
    MustBeGreaterThanOrEqualField(field, other_field) ->
      field <> " must be greater than or equal to " <> other_field
    RulesMissing -> "rules must contain at least one rule"
    SpamDetected(message) -> message
  }
}

pub fn to_string(err: ValidationError) -> String {
  "validation_error:" <> message(err)
}

fn field_slug(field: String) -> String {
  field
  |> string.lowercase
  |> string.replace(each: ".", with: "_")
  |> string.replace(each: "[", with: "_")
  |> string.replace(each: "]", with: "")
}

fn cursor_kind_slug(kind: CursorKind) -> String {
  case kind {
    ApiLogCursor -> "api_log"
    RunLogCursor -> "run_log"
    JobLogCursor -> "job_log"
  }
}

fn cursor_kind_label(kind: CursorKind) -> String {
  case kind {
    ApiLogCursor -> "api log"
    RunLogCursor -> "run log"
    JobLogCursor -> "job log"
  }
}

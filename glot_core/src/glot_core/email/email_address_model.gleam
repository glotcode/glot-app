import gleam/dynamic/decode
import gleam/json
import gleam/option
import gleam/regexp
import gleam/string

pub const pattern = "^([\\w\\d-]+)(\\.[\\w\\d-]+)*(\\+[\\w\\d-]+)?@[\\w\\d\\.-]+$"

pub type EmailAddress {
  EmailAddress(String)
}

pub fn to_string(email: EmailAddress) -> String {
  case email {
    EmailAddress(value) -> value
  }
}

pub fn from_string(
  is_email: regexp.Regexp,
  value: String,
) -> option.Option(EmailAddress) {
  let value = normalize(value)

  case string_is_email(is_email, value) {
    True -> option.Some(EmailAddress(value))
    False -> option.None
  }
}

pub fn encode(email: EmailAddress) -> json.Json {
  json.string(to_string(email))
}

pub fn decoder(is_email: regexp.Regexp) -> decode.Decoder(EmailAddress) {
  decode.then(decode.string, fn(value) {
    case from_string(is_email, value) {
      option.Some(email) -> decode.success(email)
      option.None ->
        decode.failure(EmailAddress(""), "Invalid email format: " <> value)
    }
  })
}

fn normalize(value: String) -> String {
  value
  |> string.trim
  |> string.lowercase
}

fn string_is_email(re: regexp.Regexp, value: String) -> Bool {
  regexp.check(with: re, content: value)
}

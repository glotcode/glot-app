import gleam/dynamic/decode
import gleam/json
import gleam/regexp
import glot_core/email/email_address_model.{type EmailAddress}

pub type BeginEmailChangeRequest {
  BeginEmailChangeRequest(email: EmailAddress)
}

pub type ConfirmEmailChangeRequest {
  ConfirmEmailChangeRequest(token: String)
}

pub fn begin_request_decoder(
  is_email: regexp.Regexp,
) -> decode.Decoder(BeginEmailChangeRequest) {
  use email <- decode.field("email", email_address_model.decoder(is_email))
  decode.success(BeginEmailChangeRequest(email:))
}

pub fn encode_begin_request(request: BeginEmailChangeRequest) -> json.Json {
  json.object([#("email", email_address_model.encode(request.email))])
}

pub fn confirm_request_decoder() -> decode.Decoder(ConfirmEmailChangeRequest) {
  use token <- decode.field("token", decode.string)
  decode.success(ConfirmEmailChangeRequest(token:))
}

pub fn encode_confirm_request(request: ConfirmEmailChangeRequest) -> json.Json {
  json.object([#("token", json.string(request.token))])
}

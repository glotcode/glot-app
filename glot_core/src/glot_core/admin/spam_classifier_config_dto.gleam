import gleam/dynamic/decode
import gleam/json
import glot_core/snippet/classifier_provider.{type Provider}

pub type SpamClassifierConfigResponse {
  SpamClassifierConfigResponse(
    base_url: String,
    auth_token: String,
    provider: Provider,
  )
}

pub type UpsertSpamClassifierConfigRequest {
  UpsertSpamClassifierConfigRequest(
    base_url: String,
    auth_token: String,
    provider: Provider,
  )
}

pub fn response_decoder() -> decode.Decoder(SpamClassifierConfigResponse) {
  use provider <- decode.optional_field(
    "provider",
    classifier_provider.External,
    classifier_provider.decoder(),
  )
  use base_url <- decode.field("baseUrl", decode.string)
  use auth_token <- decode.field("authToken", decode.string)
  decode.success(SpamClassifierConfigResponse(base_url:, auth_token:, provider:))
}

pub fn decoder() -> decode.Decoder(UpsertSpamClassifierConfigRequest) {
  use provider <- decode.optional_field(
    "provider",
    classifier_provider.External,
    classifier_provider.decoder(),
  )
  use base_url <- decode.field("baseUrl", decode.string)
  use auth_token <- decode.field("authToken", decode.string)
  decode.success(UpsertSpamClassifierConfigRequest(
    base_url:,
    auth_token:,
    provider:,
  ))
}

pub fn encode_response(response: SpamClassifierConfigResponse) -> json.Json {
  json.object([
    #("provider", json.string(classifier_provider.to_string(response.provider))),
    #("baseUrl", json.string(response.base_url)),
    #("authToken", json.string(response.auth_token)),
  ])
}

pub fn encode_request(request: UpsertSpamClassifierConfigRequest) -> json.Json {
  json.object([
    #("provider", json.string(classifier_provider.to_string(request.provider))),
    #("baseUrl", json.string(request.base_url)),
    #("authToken", json.string(request.auth_token)),
  ])
}

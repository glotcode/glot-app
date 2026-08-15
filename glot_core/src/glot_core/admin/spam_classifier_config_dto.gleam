import gleam/dynamic/decode
import gleam/json

pub type SpamClassifierConfigResponse {
  SpamClassifierConfigResponse(base_url: String, auth_token: String)
}

pub type UpsertSpamClassifierConfigRequest {
  UpsertSpamClassifierConfigRequest(base_url: String, auth_token: String)
}

pub fn response_decoder() -> decode.Decoder(SpamClassifierConfigResponse) {
  use base_url <- decode.field("baseUrl", decode.string)
  use auth_token <- decode.field("authToken", decode.string)
  decode.success(SpamClassifierConfigResponse(base_url:, auth_token:))
}

pub fn decoder() -> decode.Decoder(UpsertSpamClassifierConfigRequest) {
  use base_url <- decode.field("baseUrl", decode.string)
  use auth_token <- decode.field("authToken", decode.string)
  decode.success(UpsertSpamClassifierConfigRequest(base_url:, auth_token:))
}

pub fn encode_response(response: SpamClassifierConfigResponse) -> json.Json {
  json.object([
    #("baseUrl", json.string(response.base_url)),
    #("authToken", json.string(response.auth_token)),
  ])
}

pub fn encode_request(request: UpsertSpamClassifierConfigRequest) -> json.Json {
  json.object([
    #("baseUrl", json.string(request.base_url)),
    #("authToken", json.string(request.auth_token)),
  ])
}

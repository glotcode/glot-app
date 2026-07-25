import gleam/dynamic/decode
import gleam/json

pub type HttpPoolConfigResponse {
  HttpPoolConfigResponse(
    docker_run_max_sessions: Int,
    cloudflare_email_max_sessions: Int,
    keep_alive_timeout_ms: Int,
  )
}

pub type UpsertHttpPoolConfigRequest {
  UpsertHttpPoolConfigRequest(
    docker_run_max_sessions: Int,
    cloudflare_email_max_sessions: Int,
    keep_alive_timeout_ms: Int,
  )
}

pub fn response_decoder() -> decode.Decoder(HttpPoolConfigResponse) {
  use docker_run_max_sessions <- decode.field(
    "dockerRunMaxSessions",
    decode.int,
  )
  use cloudflare_email_max_sessions <- decode.field(
    "cloudflareEmailMaxSessions",
    decode.int,
  )
  use keep_alive_timeout_ms <- decode.field("keepAliveTimeoutMs", decode.int)
  decode.success(HttpPoolConfigResponse(
    docker_run_max_sessions:,
    cloudflare_email_max_sessions:,
    keep_alive_timeout_ms:,
  ))
}

pub fn decoder() -> decode.Decoder(UpsertHttpPoolConfigRequest) {
  use docker_run_max_sessions <- decode.field(
    "dockerRunMaxSessions",
    decode.int,
  )
  use cloudflare_email_max_sessions <- decode.field(
    "cloudflareEmailMaxSessions",
    decode.int,
  )
  use keep_alive_timeout_ms <- decode.field("keepAliveTimeoutMs", decode.int)
  decode.success(UpsertHttpPoolConfigRequest(
    docker_run_max_sessions:,
    cloudflare_email_max_sessions:,
    keep_alive_timeout_ms:,
  ))
}

pub fn encode_response(response: HttpPoolConfigResponse) -> json.Json {
  json.object([
    #("dockerRunMaxSessions", json.int(response.docker_run_max_sessions)),
    #(
      "cloudflareEmailMaxSessions",
      json.int(response.cloudflare_email_max_sessions),
    ),
    #("keepAliveTimeoutMs", json.int(response.keep_alive_timeout_ms)),
  ])
}

pub fn encode_request(request: UpsertHttpPoolConfigRequest) -> json.Json {
  json.object([
    #("dockerRunMaxSessions", json.int(request.docker_run_max_sessions)),
    #(
      "cloudflareEmailMaxSessions",
      json.int(request.cloudflare_email_max_sessions),
    ),
    #("keepAliveTimeoutMs", json.int(request.keep_alive_timeout_ms)),
  ])
}

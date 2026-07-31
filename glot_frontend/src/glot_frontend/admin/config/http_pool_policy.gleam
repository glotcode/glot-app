import gleam/int
import gleam/result
import glot_core/admin/http_pool_config_dto
import glot_frontend/admin/ui/format as admin_format

pub type Fields {
  Fields(
    docker_run_max_sessions: String,
    cloudflare_email_max_sessions: String,
    keep_alive_timeout_ms: String,
  )
}

pub type Field {
  DockerRunMaxSessions
  CloudflareEmailMaxSessions
  KeepAliveTimeout
}

pub fn initial() -> Fields {
  Fields("", "", "")
}

pub fn set(fields: Fields, field: Field, value: String) -> Fields {
  case field {
    DockerRunMaxSessions -> Fields(..fields, docker_run_max_sessions: value)
    CloudflareEmailMaxSessions ->
      Fields(..fields, cloudflare_email_max_sessions: value)
    KeepAliveTimeout -> Fields(..fields, keep_alive_timeout_ms: value)
  }
}

pub fn from_response(
  response: http_pool_config_dto.HttpPoolConfigResponse,
) -> Fields {
  Fields(
    int.to_string(response.docker_run_max_sessions),
    int.to_string(response.cloudflare_email_max_sessions),
    int.to_string(response.keep_alive_timeout_ms),
  )
}

pub fn request(
  fields: Fields,
) -> Result(http_pool_config_dto.UpsertHttpPoolConfigRequest, String) {
  use docker_run_max_sessions <- result.try(
    admin_format.parse_positive_int_with_error(
      fields.docker_run_max_sessions,
      "Docker-run max sessions must be a positive integer.",
    ),
  )
  use cloudflare_email_max_sessions <- result.try(
    admin_format.parse_positive_int_with_error(
      fields.cloudflare_email_max_sessions,
      "Cloudflare email max sessions must be a positive integer.",
    ),
  )
  use keep_alive_timeout_ms <- result.try(
    admin_format.parse_positive_int_with_error(
      fields.keep_alive_timeout_ms,
      "Keep-alive timeout must be a positive integer.",
    ),
  )
  Ok(http_pool_config_dto.UpsertHttpPoolConfigRequest(
    docker_run_max_sessions: docker_run_max_sessions,
    cloudflare_email_max_sessions: cloudflare_email_max_sessions,
    keep_alive_timeout_ms: keep_alive_timeout_ms,
  ))
}

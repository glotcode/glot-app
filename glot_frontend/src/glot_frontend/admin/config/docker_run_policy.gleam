import gleam/int
import gleam/result
import glot_core/admin/docker_run_config_dto
import glot_frontend/admin/ui/format as admin_format

pub type Fields {
  Fields(base_url: String, access_token: String, default_timeout_ms: String)
}

pub type Field {
  BaseUrl
  AccessToken
  DefaultTimeout
}

pub fn empty() -> Fields {
  Fields("", "", "")
}

pub fn is_empty(fields: Fields) -> Bool {
  fields == empty()
}

pub fn set(fields: Fields, field: Field, value: String) -> Fields {
  case field {
    BaseUrl -> Fields(..fields, base_url: value)
    AccessToken -> Fields(..fields, access_token: value)
    DefaultTimeout -> Fields(..fields, default_timeout_ms: value)
  }
}

pub fn from_response(
  response: docker_run_config_dto.DockerRunConfigResponse,
) -> Fields {
  Fields(
    response.base_url,
    response.access_token,
    int.to_string(response.default_timeout_ms),
  )
}

pub fn request(
  fields: Fields,
) -> Result(docker_run_config_dto.UpsertDockerRunConfigRequest, String) {
  use default_timeout_ms <- result.try(
    admin_format.parse_positive_int_with_error(
      fields.default_timeout_ms,
      "Default timeout must be a positive integer.",
    ),
  )
  case fields.base_url, fields.access_token {
    "", _ -> Error("Base URL must not be empty.")
    _, "" -> Error("Access token must not be empty.")
    _, _ ->
      Ok(docker_run_config_dto.UpsertDockerRunConfigRequest(
        base_url: fields.base_url,
        access_token: fields.access_token,
        default_timeout_ms: default_timeout_ms,
      ))
  }
}

import gleam/int
import gleam/result
import glot_core/admin/language_version_cache_worker_config_dto
import glot_frontend/admin/ui/format as admin_format

pub type Fields {
  Fields(
    refresh_interval_ms: String,
    refresh_step_delay_ms: String,
    refresh_step_jitter_ms: String,
    default_timeout_ms: String,
  )
}

pub type Field {
  RefreshInterval
  RefreshStepDelay
  RefreshStepJitter
  DefaultTimeout
}

pub fn initial() -> Fields {
  Fields("", "", "", "")
}

pub fn set(fields: Fields, field: Field, value: String) -> Fields {
  case field {
    RefreshInterval -> Fields(..fields, refresh_interval_ms: value)
    RefreshStepDelay -> Fields(..fields, refresh_step_delay_ms: value)
    RefreshStepJitter -> Fields(..fields, refresh_step_jitter_ms: value)
    DefaultTimeout -> Fields(..fields, default_timeout_ms: value)
  }
}

pub fn from_response(
  response: language_version_cache_worker_config_dto.LanguageVersionCacheWorkerConfigResponse,
) -> Fields {
  Fields(
    int.to_string(response.refresh_interval_ms),
    int.to_string(response.refresh_step_delay_ms),
    int.to_string(response.refresh_step_jitter_ms),
    int.to_string(response.default_timeout_ms),
  )
}

pub fn request(
  fields: Fields,
) -> Result(
  language_version_cache_worker_config_dto.UpsertLanguageVersionCacheWorkerConfigRequest,
  String,
) {
  use refresh_interval_ms <- result.try(
    admin_format.parse_positive_int_with_error(
      fields.refresh_interval_ms,
      "Refresh interval must be a positive integer.",
    ),
  )
  use refresh_step_delay_ms <- result.try(
    admin_format.parse_positive_int_with_error(
      fields.refresh_step_delay_ms,
      "Refresh step delay must be a positive integer.",
    ),
  )
  let refresh_step_jitter_ms = case fields.refresh_step_jitter_ms {
    "0" -> Ok(0)
    value ->
      admin_format.parse_positive_int_with_error(
        value,
        "Refresh step jitter must be 0 or a positive integer.",
      )
  }
  use refresh_step_jitter_ms <- result.try(refresh_step_jitter_ms)
  use default_timeout_ms <- result.try(
    admin_format.parse_positive_int_with_error(
      fields.default_timeout_ms,
      "Default timeout must be a positive integer.",
    ),
  )
  Ok(
    language_version_cache_worker_config_dto.UpsertLanguageVersionCacheWorkerConfigRequest(
      refresh_interval_ms:,
      refresh_step_delay_ms:,
      refresh_step_jitter_ms:,
      default_timeout_ms:,
    ),
  )
}

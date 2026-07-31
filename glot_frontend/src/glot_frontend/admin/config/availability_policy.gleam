import gleam/int
import gleam/option
import gleam/result
import glot_core/admin/availability_config_dto
import glot_core/availability_mode
import glot_frontend/admin/ui/format as admin_format

pub type Fields {
  Fields(
    mode: availability_mode.AvailabilityMode,
    message: String,
    retry_after_seconds: String,
  )
}

pub fn initial() -> Fields {
  Fields(
    mode: availability_mode.NormalMode,
    message: "glot.io is temporarily unavailable right now.",
    retry_after_seconds: "",
  )
}

pub fn select_mode(
  fields: Fields,
  mode: availability_mode.AvailabilityMode,
) -> Fields {
  Fields(..fields, mode: mode)
}

pub fn set_message(fields: Fields, message: String) -> Fields {
  Fields(..fields, message: message)
}

pub fn set_retry_after(fields: Fields, retry_after_seconds: String) -> Fields {
  Fields(..fields, retry_after_seconds: retry_after_seconds)
}

pub fn from_response(
  response: availability_config_dto.AvailabilityConfigResponse,
) -> Fields {
  Fields(
    mode: response.mode,
    message: response.message,
    retry_after_seconds: option.map(response.retry_after_seconds, int.to_string)
      |> option.unwrap(""),
  )
}

pub fn request(
  fields: Fields,
) -> Result(availability_config_dto.UpsertAvailabilityConfigRequest, String) {
  let retry_after_seconds = case fields.retry_after_seconds {
    "" -> Ok(option.None)
    value ->
      admin_format.parse_positive_int_with_error(
        value,
        "Retry-After seconds must be a positive integer.",
      )
      |> result.map(option.Some)
  }
  use retry_after_seconds <- result.try(retry_after_seconds)
  case fields.message {
    "" -> Error("Availability message must not be empty.")
    _ ->
      Ok(availability_config_dto.UpsertAvailabilityConfigRequest(
        mode: fields.mode,
        message: fields.message,
        retry_after_seconds: retry_after_seconds,
      ))
  }
}

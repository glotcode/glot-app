import gleam/int
import gleam/result
import glot_core/admin/passkey_config_dto
import glot_frontend/admin/ui/format as admin_format

pub type Fields {
  Fields(origin: String, rp_id: String, challenge_timeout_seconds: String)
}

pub fn initial() -> Fields {
  Fields(origin: "", rp_id: "", challenge_timeout_seconds: "")
}

pub fn set_origin(fields: Fields, origin: String) -> Fields {
  Fields(..fields, origin: origin)
}

pub fn set_rp_id(fields: Fields, rp_id: String) -> Fields {
  Fields(..fields, rp_id: rp_id)
}

pub fn set_challenge_timeout(
  fields: Fields,
  challenge_timeout_seconds: String,
) -> Fields {
  Fields(..fields, challenge_timeout_seconds: challenge_timeout_seconds)
}

pub fn from_response(
  response: passkey_config_dto.PasskeyConfigResponse,
) -> Fields {
  Fields(
    origin: response.origin,
    rp_id: response.rp_id,
    challenge_timeout_seconds: int.to_string(response.challenge_timeout_seconds),
  )
}

pub fn request(
  fields: Fields,
) -> Result(passkey_config_dto.UpsertPasskeyConfigRequest, String) {
  use challenge_timeout_seconds <- result.try(
    admin_format.parse_positive_int_with_error(
      fields.challenge_timeout_seconds,
      "Challenge timeout must be a positive integer.",
    ),
  )
  case fields.origin, fields.rp_id {
    "", _ -> Error("Origin must not be empty.")
    _, "" -> Error("RP ID must not be empty.")
    _, _ ->
      Ok(passkey_config_dto.UpsertPasskeyConfigRequest(
        origin: fields.origin,
        rp_id: fields.rp_id,
        challenge_timeout_seconds: challenge_timeout_seconds,
      ))
  }
}

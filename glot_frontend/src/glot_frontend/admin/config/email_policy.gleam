import gleam/int
import gleam/option
import gleam/result
import glot_core/admin/email_config_dto
import glot_frontend/admin/ui/format as admin_format

pub type Fields {
  Fields(
    from_address: String,
    from_name: String,
    contact_address: String,
    default_timeout_ms: String,
  )
}

pub type Field {
  FromAddress
  FromName
  ContactAddress
  DefaultTimeout
}

pub fn empty() -> Fields {
  Fields("", "", "", "")
}

pub fn is_empty(fields: Fields) -> Bool {
  fields == empty()
}

pub fn set(fields: Fields, field: Field, value: String) -> Fields {
  case field {
    FromAddress -> Fields(..fields, from_address: value)
    FromName -> Fields(..fields, from_name: value)
    ContactAddress -> Fields(..fields, contact_address: value)
    DefaultTimeout -> Fields(..fields, default_timeout_ms: value)
  }
}

pub fn from_response(response: email_config_dto.EmailConfigResponse) -> Fields {
  Fields(
    response.from_address,
    option.unwrap(response.from_name, ""),
    option.unwrap(response.contact_address, ""),
    int.to_string(response.default_timeout_ms),
  )
}

pub fn request(
  fields: Fields,
) -> Result(email_config_dto.UpsertEmailConfigRequest, String) {
  use default_timeout_ms <- result.try(
    admin_format.parse_positive_int_with_error(
      fields.default_timeout_ms,
      "Default timeout must be a positive integer.",
    ),
  )
  case fields.from_address {
    "" -> Error("From address must not be empty.")
    _ ->
      Ok(email_config_dto.UpsertEmailConfigRequest(
        from_address: fields.from_address,
        from_name: optional(fields.from_name),
        contact_address: optional(fields.contact_address),
        default_timeout_ms: default_timeout_ms,
      ))
  }
}

fn optional(value: String) -> option.Option(String) {
  case value {
    "" -> option.None
    _ -> option.Some(value)
  }
}

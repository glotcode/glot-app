import glot_core/admin/cloudflare_config_dto

pub type Fields {
  Fields(account_id: String, api_token: String)
}

pub type Field {
  AccountId
  ApiToken
}

pub fn empty() -> Fields {
  Fields("", "")
}

pub fn is_empty(fields: Fields) -> Bool {
  fields == empty()
}

pub fn set(fields: Fields, field: Field, value: String) -> Fields {
  case field {
    AccountId -> Fields(..fields, account_id: value)
    ApiToken -> Fields(..fields, api_token: value)
  }
}

pub fn from_response(
  response: cloudflare_config_dto.CloudflareConfigResponse,
) -> Fields {
  Fields(response.account_id, response.api_token)
}

pub fn request(
  fields: Fields,
) -> Result(cloudflare_config_dto.UpsertCloudflareConfigRequest, String) {
  case fields.account_id, fields.api_token {
    "", _ -> Error("Account ID must not be empty.")
    _, "" -> Error("API token must not be empty.")
    _, _ ->
      Ok(cloudflare_config_dto.UpsertCloudflareConfigRequest(
        account_id: fields.account_id,
        api_token: fields.api_token,
      ))
  }
}

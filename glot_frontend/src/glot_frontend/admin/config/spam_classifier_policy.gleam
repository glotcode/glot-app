import gleam/result
import gleam/string
import glot_core/admin/spam_classifier_config_dto
import glot_core/snippet/classifier_provider.{type Provider}

pub type Fields {
  Fields(base_url: String, auth_token: String, provider: Provider)
}

pub type Field {
  BaseUrl
  AuthToken
  Provider
}

pub fn empty() -> Fields {
  Fields("", "", classifier_provider.External)
}

pub fn is_empty(fields: Fields) -> Bool {
  fields == empty()
}

pub fn set(fields: Fields, field: Field, value: String) -> Fields {
  case field {
    Provider ->
      Fields(
        ..fields,
        provider: classifier_provider.from_string(value)
          |> result.unwrap(fields.provider),
      )
    BaseUrl -> Fields(..fields, base_url: value)
    AuthToken -> Fields(..fields, auth_token: value)
  }
}

pub fn from_response(
  response: spam_classifier_config_dto.SpamClassifierConfigResponse,
) -> Fields {
  Fields(response.base_url, response.auth_token, response.provider)
}

pub fn request(
  fields: Fields,
) -> Result(
  spam_classifier_config_dto.UpsertSpamClassifierConfigRequest,
  String,
) {
  case
    fields.provider,
    string.trim(fields.base_url),
    string.trim(fields.auth_token)
  {
    classifier_provider.External, "", _ -> Error("Base URL must not be empty.")
    classifier_provider.External, _, "" ->
      Error("Auth token must not be empty.")
    _, _, _ ->
      Ok(spam_classifier_config_dto.UpsertSpamClassifierConfigRequest(
        base_url: fields.base_url,
        auth_token: fields.auth_token,
        provider: fields.provider,
      ))
  }
}

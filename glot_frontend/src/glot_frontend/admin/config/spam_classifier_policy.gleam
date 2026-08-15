import glot_core/admin/spam_classifier_config_dto

pub type Fields {
  Fields(base_url: String, auth_token: String)
}

pub type Field {
  BaseUrl
  AuthToken
}

pub fn empty() -> Fields {
  Fields("", "")
}

pub fn is_empty(fields: Fields) -> Bool {
  fields == empty()
}

pub fn set(fields: Fields, field: Field, value: String) -> Fields {
  case field {
    BaseUrl -> Fields(..fields, base_url: value)
    AuthToken -> Fields(..fields, auth_token: value)
  }
}

pub fn from_response(
  response: spam_classifier_config_dto.SpamClassifierConfigResponse,
) -> Fields {
  Fields(response.base_url, response.auth_token)
}

pub fn request(
  fields: Fields,
) -> Result(
  spam_classifier_config_dto.UpsertSpamClassifierConfigRequest,
  String,
) {
  case fields.base_url, fields.auth_token {
    "", _ -> Error("Base URL must not be empty.")
    _, "" -> Error("Auth token must not be empty.")
    _, _ ->
      Ok(spam_classifier_config_dto.UpsertSpamClassifierConfigRequest(
        base_url: fields.base_url,
        auth_token: fields.auth_token,
      ))
  }
}

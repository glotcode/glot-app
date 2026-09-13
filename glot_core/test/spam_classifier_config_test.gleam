import gleam/json
import glot_core/admin/spam_classifier_config_dto
import glot_core/snippet/classifier_provider

pub fn legacy_config_defaults_to_external_test() {
  let assert Ok(request) =
    json.parse(
      "{\"baseUrl\":\"https://classifier\",\"authToken\":\"secret\"}",
      spam_classifier_config_dto.decoder(),
    )
  assert request.provider == classifier_provider.External
  let assert Ok(response) =
    json.parse(
      "{\"baseUrl\":\"https://classifier\",\"authToken\":\"secret\"}",
      spam_classifier_config_dto.response_decoder(),
    )
  assert response.provider == classifier_provider.External
}

pub fn local_config_round_trips_without_credentials_test() {
  let request =
    spam_classifier_config_dto.UpsertSpamClassifierConfigRequest(
      "",
      "",
      classifier_provider.Local,
    )
  assert request
    |> spam_classifier_config_dto.encode_request
    |> json.to_string
    |> json.parse(spam_classifier_config_dto.decoder())
    == Ok(request)
}

pub fn unknown_provider_is_rejected_test() {
  let assert Error(_) =
    json.parse(
      "{\"baseUrl\":\"\",\"authToken\":\"\",\"provider\":\"unknown\"}",
      spam_classifier_config_dto.decoder(),
    )
}

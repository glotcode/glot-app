import gleam/dict
import gleam/int
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import glot_backend/spam_classifier/model/config
import glot_backend/spam_classifier/ports/client as classifier_client
import glot_backend/system/effect/error
import glot_backend/system/effect/error/infra_error
import glot_backend/system/http/client as http_client
import glot_backend/system/http/pool.{type Pool}
import glot_core/snippet/spam_classification
import wisp

const default_retry_delay_seconds = 30

const configuration_retry_delay_seconds = 900

pub fn new(pool: Pool) -> classifier_client.Client {
  classifier_client.Client(classify: fn(config, request, timeout_ms) {
    classify(pool, config, request, timeout_ms)
  })
}

fn classify(
  pool: Pool,
  config: config.Config,
  request: spam_classification.ServiceRequest,
  timeout_ms: Int,
) -> Result(#(spam_classification.ServiceResponse, String), error.Error) {
  let response =
    http_client.post_json_raw(
      using: pool,
      url: classify_url(config.base_url),
      headers: dict.from_list([
        #("authorization", "Bearer " <> config.auth_token),
      ]),
      body: spam_classification.encode_request(request),
      timeout_ms: timeout_ms,
    )
  case response {
    Error(http_error) ->
      Error(request_error(
        string.inspect(http_error),
        http_error_disposition(http_error),
        infra_error.ServiceFailure,
      ))
    Ok(http_client.RawResponse(status:, headers:, body:)) -> {
      let request_id =
        header(headers, "x-request-id") |> option.unwrap("missing")
      case status {
        200 ->
          json.parse(body, spam_classification.service_response_decoder())
          |> result.map(fn(value) { #(value, request_id) })
          |> result.map_error(fn(decode_error) {
            request_error(
              "invalid_response:"
                <> string.inspect(decode_error)
                <> ":request_id="
                <> request_id,
              infra_error.RetryIndefinitelyWithBackoff,
              infra_error.ServiceFailure,
            )
          })
        429 ->
          Error(request_error(
            "status=429:body=" <> body <> ":request_id=" <> request_id,
            infra_error.RetryIndefinitelyAfter(retry_after_seconds(headers)),
            infra_error.ServiceFailure,
          ))
        502 ->
          Error(request_error(
            "status=502:body=" <> body <> ":request_id=" <> request_id,
            infra_error.RetryIndefinitelyWithBackoff,
            infra_error.ServiceFailure,
          ))
        400 ->
          Error(request_error(
            "status="
              <> int.to_string(status)
              <> ":body="
              <> body
              <> ":request_id="
              <> request_id,
            infra_error.PermanentFailure,
            infra_error.SnippetFailure,
          ))
        401 ->
          Error(request_error(
            "status=401:body=" <> body <> ":request_id=" <> request_id,
            infra_error.RetryIndefinitelyAfter(
              configuration_retry_delay_seconds,
            ),
            infra_error.ServiceFailure,
          ))
        _ ->
          Error(request_error(
            "status="
              <> int.to_string(status)
              <> ":body="
              <> body
              <> ":request_id="
              <> request_id,
            retryability(status),
            infra_error.ServiceFailure,
          ))
      }
    }
  }
}

fn http_error_disposition(
  http_error: http_client.HttpError,
) -> infra_error.FailureDisposition {
  case http_error {
    http_client.BadUrl(_) ->
      infra_error.RetryIndefinitelyAfter(configuration_retry_delay_seconds)
    http_client.Timeout
    | http_client.NetworkError
    | http_client.BadStatus(_, _)
    | http_client.BadBody(_) -> infra_error.RetryIndefinitelyWithBackoff
  }
}

fn retry_after_seconds(headers: List(#(String, String))) -> Int {
  case header(headers, "retry-after") {
    option.Some(value) ->
      int.parse(value)
      |> result.unwrap(default_retry_delay_seconds)
    option.None -> default_retry_delay_seconds
  }
}

fn classify_url(base_url: String) -> String {
  let trimmed = string.trim_end(base_url)
  case string.ends_with(trimmed, "/") {
    True -> string.drop_end(trimmed, 1) <> "/classify"
    False -> trimmed <> "/classify"
  }
}

fn header(
  headers: List(#(String, String)),
  name: String,
) -> option.Option(String) {
  headers
  |> list.find(fn(header) { string.lowercase(header.0) == name })
  |> result.map(fn(header) { header.1 })
  |> option.from_result
}

fn retryability(status: Int) -> infra_error.FailureDisposition {
  case status == 429 || status == 502 || status >= 500 {
    True -> infra_error.RetryIndefinitelyWithBackoff
    False ->
      infra_error.RetryIndefinitelyAfter(configuration_retry_delay_seconds)
  }
}

fn request_error(
  detail: String,
  disposition: infra_error.FailureDisposition,
  scope: infra_error.SpamClassifierFailureScope,
) -> error.Error {
  wisp.log_error("Spam classifier request failed: " <> detail)
  error.infra(
    infra_error.SpamClassifierError(infra_error.SpamClassifierRequestFailed(
      detail,
      disposition,
      scope,
    )),
  )
}

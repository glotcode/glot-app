import gleam/dict
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/httpc
import gleam/json
import gleam/result
import gleam/string
import gleam/uri
import glot_backend/system/http/pool.{type Pool}
import glot_backend/system/http/profile_httpc

pub type HttpError {
  BadUrl(String)
  Timeout
  NetworkError
  BadStatus(status: Int, body: String)
  BadBody(String)
}

pub type RawResponse {
  RawResponse(status: Int, headers: List(#(String, String)), body: String)
}

fn map_http_error(error: httpc.HttpError) -> HttpError {
  case error {
    httpc.InvalidUtf8Response -> BadBody("Response body was not valid UTF-8")
    httpc.FailedToConnect(_ip4, _ip6) -> NetworkError
    httpc.ResponseTimeout -> Timeout
  }
}

fn ensure_good_status(
  res: response.Response(String),
) -> Result(Nil, HttpError) {
  case res.status >= 200 && res.status <= 299 {
    True -> Ok(Nil)
    False -> Error(BadStatus(status: res.status, body: res.body))
  }
}

pub fn post_json(
  using pool: Pool,
  url url: String,
  headers headers: dict.Dict(String, String),
  body body: json.Json,
  timeout_ms timeout_ms: Int,
  decoder decoder: decode.Decoder(a),
) -> Result(a, HttpError) {
  use initial_req <- result.try(url_to_request(url))

  let req =
    initial_req
    |> request.set_method(http.Post)
    |> request.set_header("content-type", "application/json")
    |> request.set_header("accept", "application/json")
    |> request.set_body(json.to_string(body))
    |> dict.fold(headers, _, fn(acc, key, value) {
      request.set_header(acc, key, value)
    })

  use res <- result.try(
    profile_httpc.dispatch(pool, timeout_ms, req)
    |> result.map_error(map_http_error),
  )
  use _ <- result.try(ensure_good_status(res))

  json.parse(res.body, decoder)
  |> result.map_error(fn(err) { BadBody(string.inspect(err)) })
}

pub fn post_json_raw(
  using pool: Pool,
  url url: String,
  headers headers: dict.Dict(String, String),
  body body: json.Json,
  timeout_ms timeout_ms: Int,
) -> Result(RawResponse, HttpError) {
  use initial_req <- result.try(url_to_request(url))
  let req =
    initial_req
    |> request.set_method(http.Post)
    |> request.set_header("content-type", "application/json")
    |> request.set_header("accept", "application/json")
    |> request.set_body(json.to_string(body))
    |> dict.fold(headers, _, fn(acc, key, value) {
      request.set_header(acc, key, value)
    })
  profile_httpc.dispatch(pool, timeout_ms, req)
  |> result.map_error(map_http_error)
  |> result.map(fn(res) { RawResponse(res.status, res.headers, res.body) })
}

fn url_to_request(url: String) -> Result(request.Request(String), HttpError) {
  let to_bad_url = fn(_) { BadUrl(url) }
  use u <- result.try(uri.parse(url) |> result.map_error(to_bad_url))

  request.from_uri(u)
  |> result.map_error(to_bad_url)
}

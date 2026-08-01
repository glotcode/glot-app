import gleam/dynamic/decode
import gleam/http/response as http_response
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import glot_core/admin_action.{type AdminAction}
import glot_core/api_error_dto
import glot_core/public_action.{type PublicAction}
import glot_frontend/api/http_error
import glot_frontend/api/response
import glot_frontend/api/transport
import lustre/effect.{type Effect}

pub fn send_public(
  action action: PublicAction,
  data data: request,
  encode encode_data: fn(request) -> json.Json,
  decode decode_data: decode.Decoder(payload),
  ownership ownership: transport.Ownership,
  then to_msg: fn(response.Response(payload)) -> msg,
) -> Effect(msg) {
  send(
    public_action.encode(action),
    data,
    encode_data,
    decode_data,
    ownership,
    to_msg,
  )
}

pub fn send_admin(
  action action: AdminAction,
  data data: request,
  encode encode_data: fn(request) -> json.Json,
  decode decode_data: decode.Decoder(payload),
  ownership ownership: transport.Ownership,
  then to_msg: fn(response.Response(payload)) -> msg,
) -> Effect(msg) {
  send(
    admin_action.encode(action),
    data,
    encode_data,
    decode_data,
    ownership,
    to_msg,
  )
}

fn send(
  action: json.Json,
  data: request,
  encode_data: fn(request) -> json.Json,
  decode_data: decode.Decoder(payload),
  ownership: transport.Ownership,
  to_msg: fn(response.Response(payload)) -> msg,
) -> Effect(msg) {
  let body =
    json.object([#("action", action), #("data", encode_data(data))])
    |> json.to_string

  transport.post_json(ownership, body, fn(result) {
    case result {
      transport.Received(status, content_type, body) -> {
        let received =
          http_response.new(status)
          |> http_response.set_header("content-type", content_type)
          |> http_response.set_body(body)
        case decode_response(received, decode_data) {
          Ok(decoded) -> to_msg(decoded)
          Error(error) -> to_msg(response.HttpFailure(error))
        }
      }
      transport.Failed(error) -> to_msg(response.HttpFailure(error))
    }
  })
}

pub fn decode_response(
  received: http_response.Response(String),
  data_decoder: decode.Decoder(a),
) -> Result(response.Response(a), http_error.Error) {
  use _ <- result.try(ensure_json_response(received))

  case received.status {
    status if status >= 200 && status < 300 ->
      json.parse(received.body, success_decoder(data_decoder))
      |> result.map_error(http_error.JsonError)
    status if status >= 400 && status < 600 ->
      json.parse(received.body, error_decoder())
      |> result.map_error(http_error.JsonError)
    status -> Error(http_error.UnexpectedResponse(status))
  }
}

fn success_decoder(
  data_decoder: decode.Decoder(a),
) -> decode.Decoder(response.Response(a)) {
  use data <- decode.field("data", data_decoder)
  decode.success(response.Success(data))
}

fn error_decoder() -> decode.Decoder(response.Response(a)) {
  api_error_dto.decoder()
  |> decode.map(fn(error) {
    response.ApiFailure(response.Error(
      code: error.code,
      message: error.message,
      request_id: error.request_id,
    ))
  })
}

fn ensure_json_response(
  received: http_response.Response(String),
) -> Result(Nil, http_error.Error) {
  case http_response.get_header(received, "content-type") {
    Ok(content_type) ->
      case is_json_content_type(content_type) {
        True -> Ok(Nil)
        False -> Error(http_error.UnexpectedResponse(received.status))
      }
    _ -> Error(http_error.UnexpectedResponse(received.status))
  }
}

fn is_json_content_type(content_type: String) -> Bool {
  content_type
  |> string.lowercase
  |> string.split(";")
  |> list.first
  |> result.map(string.trim)
  == Ok("application/json")
}

pub fn nil_decoder() -> decode.Decoder(Nil) {
  decode.then(decode.optional(decode.bool), fn(value) {
    case value {
      option.None -> decode.success(Nil)
      option.Some(_) -> decode.failure(Nil, "Nil")
    }
  })
}

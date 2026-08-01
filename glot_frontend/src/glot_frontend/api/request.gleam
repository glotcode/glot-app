import gleam/dynamic/decode
import gleam/json
import glot_core/admin_action.{type AdminAction}
import glot_core/public_action.{type PublicAction}
import glot_frontend/api/client
import glot_frontend/api/ownership
import glot_frontend/api/response
import lustre/effect.{type Effect}

pub type PublicRequest(data) {
  PublicRequest(action: PublicAction, data: data)
}

pub type AdminRequest(data) {
  AdminRequest(action: AdminAction, data: data)
}

pub fn send_public(
  request: PublicRequest(request),
  encode: fn(request) -> json.Json,
  decode: decode.Decoder(payload),
  then: fn(response.Response(payload)) -> msg,
) -> Effect(msg) {
  client.send_public(
    action: request.action,
    data: request.data,
    encode:,
    decode:,
    ownership: ownership.public(request.action),
    then:,
  )
}

pub fn send_admin(
  request: AdminRequest(request),
  encode: fn(request) -> json.Json,
  decode: decode.Decoder(payload),
  then: fn(response.Response(payload)) -> msg,
) -> Effect(msg) {
  client.send_admin(
    action: request.action,
    data: request.data,
    encode:,
    decode:,
    ownership: ownership.admin(request.action),
    then:,
  )
}

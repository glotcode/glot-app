import glot_frontend/api/http_error
import lustre/effect.{type Effect}

const endpoint = "/api/mux"

pub type Ownership {
  Persistent
  Navigation
}

pub type Result {
  Received(status: Int, content_type: String, body: String)
  Failed(http_error.Error)
}

pub fn post_json(
  ownership: Ownership,
  body: String,
  then: fn(Result) -> msg,
) -> Effect(msg) {
  effect.from(fn(dispatch) {
    send(
      endpoint,
      body,
      ownership == Navigation,
      fn(kind, status, content_type, body) {
        let result = case kind {
          "response" -> Received(status:, content_type:, body:)
          "body" -> Failed(http_error.BodyReadError)
          _ -> Failed(http_error.NetworkError)
        }
        dispatch(then(result))
      },
    )
  })
}

pub fn cancel_navigation_requests() -> Nil {
  cancel_navigation()
}

@external(javascript, "./transport_ffi.mjs", "send")
fn send(
  endpoint: String,
  body: String,
  cancellable: Bool,
  callback: fn(String, Int, String, String) -> Nil,
) -> Nil

@external(javascript, "./transport_ffi.mjs", "cancelNavigationRequests")
fn cancel_navigation() -> Nil

import glot_frontend/api/http_error
import lustre/effect.{type Effect}

const endpoint = "/api/mux"

pub type Ownership {
  Persistent
  Navigation
  Run
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
      cancellation_group(ownership),
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

fn cancellation_group(ownership: Ownership) -> String {
  case ownership {
    Persistent -> "persistent"
    Navigation -> "navigation"
    Run -> "run"
  }
}

pub fn cancel_navigation_requests() -> Nil {
  cancel_navigation()
}

pub fn cancel_run_requests() -> Nil {
  cancel_run()
}

@external(javascript, "./transport_ffi.mjs", "send")
fn send(
  endpoint: String,
  body: String,
  cancellation_group: String,
  callback: fn(String, Int, String, String) -> Nil,
) -> Nil

@external(javascript, "./transport_ffi.mjs", "cancelNavigationRequests")
fn cancel_navigation() -> Nil

@external(javascript, "./transport_ffi.mjs", "cancelRunRequests")
fn cancel_run() -> Nil

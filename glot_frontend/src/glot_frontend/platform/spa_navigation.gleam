import gleam/option.{type Option, None, Some}
import gleam/uri.{type Uri}
import lustre/effect.{type Effect}

/// Observe native link clicks, history traversal, and programmatic SPA route
/// changes without scrolling the document being navigated away from.
pub fn observe(handler: fn(Uri) -> msg) -> Effect(msg) {
  effect.from(fn(dispatch) {
    observe_events(fn(location) {
      case uri.parse(location) {
        Ok(uri) -> dispatch(handler(uri))
        Error(_) -> Nil
      }
    })
  })
}

pub fn push(path: String, query: Option(String)) -> Effect(msg) {
  effect.from(fn(_dispatch) { push_state(with_query(path, query)) })
}

pub fn replace(path: String) -> Effect(msg) {
  effect.from(fn(_dispatch) { replace_state(path) })
}

/// Apply browser presentation behavior only after the destination page model
/// has been committed to the DOM.
pub fn commit() -> Effect(msg) {
  effect.from(fn(_dispatch) { commit_navigation() })
}

fn with_query(path: String, query: Option(String)) -> String {
  case query {
    Some(query) -> path <> "?" <> query
    None -> path
  }
}

@external(javascript, "./spa_navigation_ffi.mjs", "observe")
fn observe_events(handler: fn(String) -> Nil) -> Nil

@external(javascript, "./spa_navigation_ffi.mjs", "push")
fn push_state(path: String) -> Nil

@external(javascript, "./spa_navigation_ffi.mjs", "replace")
fn replace_state(path: String) -> Nil

@external(javascript, "./spa_navigation_ffi.mjs", "commit")
fn commit_navigation() -> Nil

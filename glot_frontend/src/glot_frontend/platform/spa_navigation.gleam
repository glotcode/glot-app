import gleam/option.{type Option, None, Some}
import gleam/uri.{type Uri}
import glot_frontend/navigation.{type Presentation}
import lustre/effect.{type Effect}

pub type Navigation {
  Navigation(uri: Uri, presentation: Presentation)
}

pub fn initial_uri() -> Result(Uri, Nil) {
  case initial_location() {
    "" -> Error(Nil)
    location ->
      case uri.parse(location) {
        Ok(uri) -> Ok(uri)
        Error(_) -> Error(Nil)
      }
  }
}

/// Observe native link clicks, history traversal, and programmatic SPA route
/// changes without scrolling the document being navigated away from.
pub fn observe(handler: fn(Navigation) -> msg) -> Effect(msg) {
  effect.from(fn(dispatch) {
    observe_events(fn(location, restore, x, y) {
      case uri.parse(location) {
        Ok(uri) -> {
          let presentation = case restore {
            True -> navigation.Restore(x, y)
            False -> navigation.Reset
          }
          dispatch(handler(Navigation(uri:, presentation:)))
        }
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
pub fn commit(presentation: Presentation) -> Effect(msg) {
  effect.from(fn(_dispatch) {
    case presentation {
      navigation.Reset -> commit_navigation(False, 0, 0)
      navigation.Restore(x, y) -> commit_navigation(True, x, y)
    }
  })
}

fn with_query(path: String, query: Option(String)) -> String {
  case query {
    Some(query) -> path <> "?" <> query
    None -> path
  }
}

@external(javascript, "./spa_navigation_ffi.mjs", "observe")
fn observe_events(handler: fn(String, Bool, Int, Int) -> Nil) -> Nil

@external(javascript, "./spa_navigation_ffi.mjs", "push")
fn push_state(path: String) -> Nil

@external(javascript, "./spa_navigation_ffi.mjs", "replace")
fn replace_state(path: String) -> Nil

@external(javascript, "./spa_navigation_ffi.mjs", "commit")
fn commit_navigation(restore: Bool, x: Int, y: Int) -> Nil

@external(javascript, "./spa_navigation_ffi.mjs", "initialLocation")
fn initial_location() -> String

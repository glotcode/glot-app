import lustre/effect.{type Effect}

pub fn load(path: String) -> Effect(msg) {
  effect.from(fn(_dispatch) { assign(path) })
}

pub fn replace(path: String) -> Effect(msg) {
  effect.from(fn(_dispatch) { replace_location(path) })
}

@external(javascript, "./browser_navigation_ffi.mjs", "assign")
fn assign(path: String) -> Nil

@external(javascript, "./browser_navigation_ffi.mjs", "replace")
fn replace_location(path: String) -> Nil

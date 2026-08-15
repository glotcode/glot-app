import lustre/effect.{type Effect}

pub fn open(id: String) -> Effect(msg) {
  effect.from(fn(_dispatch) { open_dialog(id) })
}

pub fn open_next_frame(id: String) -> Effect(msg) {
  effect.from(fn(_dispatch) { open_dialog_next_frame(id) })
}

pub fn close(id: String) -> Effect(msg) {
  effect.from(fn(_dispatch) { close_dialog(id) })
}

pub fn focus(id: String) -> Effect(msg) {
  effect.from(fn(_dispatch) { focus_element(id) })
}

pub fn blur(id: String) -> Effect(msg) {
  effect.from(fn(_dispatch) { blur_element(id) })
}

@external(javascript, "./app_dialog_ffi.mjs", "openDialog")
fn open_dialog(id: String) -> Nil

@external(javascript, "./app_dialog_ffi.mjs", "openDialogNextFrame")
fn open_dialog_next_frame(id: String) -> Nil

@external(javascript, "./app_dialog_ffi.mjs", "closeDialog")
fn close_dialog(id: String) -> Nil

@external(javascript, "./app_dialog_ffi.mjs", "focusElement")
fn focus_element(id: String) -> Nil

@external(javascript, "./app_dialog_ffi.mjs", "blurElement")
fn blur_element(id: String) -> Nil

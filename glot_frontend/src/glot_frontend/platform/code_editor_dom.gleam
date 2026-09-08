//// Browser interop for the code editor.
////
//// This is the only place the editor touches the DOM: the textarea's value and
//// native selection, scrolling, pointer-free geometry measurement, resize
//// observation, the clipboard, and lifecycle cleanup. None of it decides what a
//// command means; it only carries out what the reducer already decided.

/// Write the document and the selection back into the textarea without
/// disturbing focus. Skipped when the value already matches, so an ordinary
/// keystroke never rewrites the whole field and never interrupts composition.
@external(javascript, "./code_editor_dom_ffi.mjs", "setValue")
pub fn set_value(id: String, value: String, anchor: Int, head: Int) -> Nil

@external(javascript, "./code_editor_dom_ffi.mjs", "setSelection")
pub fn set_selection(id: String, anchor: Int, head: Int) -> Nil

/// `intent` is one of `keep`, `top`, `center`, or `bottom`.
@external(javascript, "./code_editor_dom_ffi.mjs", "scrollToLine")
pub fn scroll_to_line(id: String, line: Int, intent: String) -> Nil

@external(javascript, "./code_editor_dom_ffi.mjs", "scrollByLines")
pub fn scroll_by_lines(id: String, lines: Int) -> Nil

@external(javascript, "./code_editor_dom_ffi.mjs", "focusElement")
pub fn focus(id: String) -> Nil

/// Move focus to the next or previous focusable element in document order.
@external(javascript, "./code_editor_dom_ffi.mjs", "moveFocus")
pub fn move_focus(id: String, forward: Bool) -> Nil

@external(javascript, "./code_editor_dom_ffi.mjs", "writeClipboard")
pub fn write_clipboard(value: String) -> Nil

/// Measure line height, client box, and character width, and keep measuring
/// after resizes and font loads. Calling it again for the same element replaces
/// the previous observer.
@external(javascript, "./code_editor_dom_ffi.mjs", "observe")
pub fn observe(
  id: String,
  callback: fn(Int, Int, Int, Int) -> Nil,
) -> Nil

@external(javascript, "./code_editor_dom_ffi.mjs", "disconnect")
pub fn disconnect(id: String) -> Nil

@external(javascript, "./code_editor_dom_ffi.mjs", "restoreScroll")
pub fn restore_scroll(id: String, top: Int, left: Int) -> Nil

/// Keep browser event identity in step with synchronous session value writes.
@external(javascript, "./code_editor_dom_ffi.mjs", "setIdentity")
pub fn set_identity(id: String, key: String, generation: Int) -> Nil

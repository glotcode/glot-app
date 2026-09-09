//// The browser-backed editor ports.
////
//// Document, selection and scroll writes are synchronous. The editor owns the
//// textarea's value, so it does not need to wait for Lustre to reconcile, and
//// waiting would let a write land after the next keystroke and overwrite it.
//// Focus and measurement do wait for paint, because the element they address
//// may only exist after the render that this update caused.

import glot_frontend/platform/code_editor_dom
import glot_frontend/public/editor/code_editor/browser_command
import glot_frontend/public/editor/code_editor/ids
import glot_frontend/public/editor/code_editor/ports.{type Ports, Ports}
import lustre/effect

pub fn ports() -> Ports(msg) {
  Ports(
    sync_document: fn(value, start, end) {
      effect.from(fn(_) {
        code_editor_dom.set_value(ids.input, value, start, end)
      })
    },
    sync_selection: fn(start, end) {
      effect.from(fn(_) { code_editor_dom.set_selection(ids.input, start, end) })
    },
    scroll_to_line: fn(line, intent) {
      effect.from(fn(_) {
        code_editor_dom.scroll_to_line(ids.input, line, intent_name(intent))
      })
    },
    sync_session: fn(key, generation, value, anchor, head, top, left) {
      // Lustre batches do not guarantee order. Restore the viewport after
      // writing identity, value and caret within one synchronous effect.
      // Events before the next render must already identify the incoming file.
      effect.from(fn(_) {
        code_editor_dom.set_identity(ids.input, key, generation)
        code_editor_dom.set_value(ids.input, value, anchor, head)
        code_editor_dom.restore_scroll(ids.input, top, left)
      })
    },
    scroll_by: fn(lines) {
      effect.from(fn(_) { code_editor_dom.scroll_by_lines(ids.input, lines) })
    },
    focus_editor: fn() {
      effect.after_paint(fn(_, _) { code_editor_dom.focus(ids.input) })
    },
    focus_search_field: fn() {
      effect.after_paint(fn(_, _) { code_editor_dom.focus(ids.search_field) })
    },
    focus_prompt: fn() {
      effect.after_paint(fn(_, _) { code_editor_dom.focus(ids.prompt_field) })
    },
    write_clipboard: fn(value) {
      effect.from(fn(_) { code_editor_dom.write_clipboard(value) })
    },
    measure: fn(callback) {
      effect.after_paint(fn(dispatch, _) {
        code_editor_dom.observe(ids.input, fn(line_height, height, width, char_width) {
          dispatch(callback(line_height, height, width, char_width))
        })
      })
    },
  )
}

fn intent_name(intent: browser_command.ScrollIntent) -> String {
  case intent {
    browser_command.KeepCaretVisible -> "keep"
    browser_command.CaretToTop -> "top"
    browser_command.CaretToCenter -> "center"
    browser_command.CaretToBottom -> "bottom"
  }
}

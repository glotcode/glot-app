//// Runtime capabilities the editor's command interpreter needs.
////
//// Production supplies browser-backed ports; tests interpret the commands as
//// data and never reach this bundle.

import glot_frontend/public/editor/code_editor/browser_command.{
  type ScrollIntent,
}
import lustre/effect.{type Effect}

pub type Ports(msg) {
  Ports(
    sync_document: fn(String, Int, Int) -> Effect(msg),
    sync_selection: fn(Int, Int) -> Effect(msg),
    scroll_to_line: fn(Int, ScrollIntent) -> Effect(msg),
    sync_session: fn(String, Int, String, Int, Int, Int, Int) -> Effect(msg),
    scroll_by: fn(Int) -> Effect(msg),
    focus_editor: fn() -> Effect(msg),
    focus_search_field: fn() -> Effect(msg),
    focus_prompt: fn() -> Effect(msg),
    write_clipboard: fn(String) -> Effect(msg),
    measure: fn(fn(Int, Int, Int, Int) -> msg) -> Effect(msg),
  )
}

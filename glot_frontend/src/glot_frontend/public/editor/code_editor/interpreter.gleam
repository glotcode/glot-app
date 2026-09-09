//// Turns editor commands into effects.

import gleam/list
import glot_frontend/public/editor/code_editor/browser_command.{type Command}
import glot_frontend/public/editor/code_editor/ports.{type Ports}
import lustre/effect.{type Effect}

pub fn run(command: Command(msg), ports: Ports(msg)) -> Effect(msg) {
  case command {
    browser_command.None -> effect.none()
    browser_command.Batch(commands) ->
      effect.batch(list.map(commands, fn(item) { run(item, ports) }))
    browser_command.SyncDocument(value, start, end) ->
      ports.sync_document(value, start, end)
    browser_command.SyncSelection(start, end) -> ports.sync_selection(start, end)
    browser_command.ScrollToLine(line, intent) ->
      ports.scroll_to_line(line, intent)
    browser_command.SyncSession(key, generation, value, anchor, head, top, left) ->
      ports.sync_session(key, generation, value, anchor, head, top, left)
    browser_command.ScrollBy(lines) -> ports.scroll_by(lines)
    browser_command.FocusEditor -> ports.focus_editor()
    browser_command.FocusSearchField -> ports.focus_search_field()
    browser_command.FocusPrompt -> ports.focus_prompt()
    browser_command.WriteClipboard(value) -> ports.write_clipboard(value)
    browser_command.Measure(callback) -> ports.measure(callback)
  }
}

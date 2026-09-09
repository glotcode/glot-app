//// Drives the code editor the way the browser does, without a browser.
////
//// Keys go through the same reducer production uses, and the resulting browser
//// commands are returned as data so tests can assert on them.

import gleam/list
import glot_core/language.{type Language}
import glot_frontend/public/editor/code_editor/browser_command
import glot_frontend/public/editor/code_editor/keys.{type Key}
import glot_frontend/public/editor/code_editor/message.{type Msg, type Outbound}
import glot_frontend/public/editor/code_editor/model.{type Model}
import glot_frontend/public/editor/code_editor/selection
import glot_frontend/public/editor/code_editor/session
import glot_frontend/public/editor/code_editor/settings_bridge
import glot_frontend/public/editor/code_editor/state
import glot_frontend/public/editor/code_editor/text
import glot_frontend/public/editor/code_editor/update

pub type Driver {
  Driver(
    model: Model,
    commands: List(browser_command.Command(Msg)),
    outbound: List(Outbound),
  )
}

pub fn new(content: String) -> Driver {
  start(content, language.JavaScript, settings_bridge.Plain, False)
}

pub fn with_bindings(
  content: String,
  bindings: settings_bridge.BindingMode,
) -> Driver {
  start(content, language.JavaScript, bindings, False)
}

pub fn read_only(content: String) -> Driver {
  Driver(
    ..start(content, language.Plaintext, settings_bridge.Plain, False),
    model: model.new(
      session.file_key(0),
      content,
      language.Plaintext,
      True,
      settings_bridge.Plain,
      False,
    ),
  )
}

pub fn start(
  content: String,
  snippet_language: Language,
  bindings: settings_bridge.BindingMode,
  mac: Bool,
) -> Driver {
  Driver(
    model: model.new(
      session.file_key(0),
      content,
      snippet_language,
      False,
      bindings,
      mac,
    ),
    commands: [],
    outbound: [],
  )
}

pub fn send(driver: Driver, msg: Msg) -> Driver {
  let #(next, command, outbound) = update.update(driver.model, msg)
  Driver(
    model: next,
    commands: list.append(driver.commands, [command]),
    outbound: list.append(driver.outbound, outbound),
  )
}

/// Press a key the way the view does: the cancellation decision is taken from
/// the model the tests can see, exactly as the rendered handler would.
pub fn press(driver: Driver, key: Key) -> Driver {
  send(
    driver,
    message.KeyPressed(key, update.handles_key(driver.model, key)),
  )
}

/// Press a key the browser was allowed to type, even though the editor would
/// have claimed it. This is the one-frame disagreement the view can produce.
pub fn press_unprevented(driver: Driver, key: Key) -> Driver {
  send(driver, message.KeyPressed(key, False))
}

/// Press a key the browser was told not to type, even though the editor has
/// since decided it would not claim it.
pub fn press_prevented(driver: Driver, key: Key) -> Driver {
  send(driver, message.KeyPressed(key, True))
}

pub fn press_all(driver: Driver, all: List(Key)) -> Driver {
  list.fold(all, driver, press)
}

/// Type a literal string the way a keyboard would in a mode that accepts
/// native input: the textarea reports its new value and caret.
pub fn type_text(driver: Driver, value: String) -> Driver {
  let current = model.active_session(driver.model)
  let caret = text.width(value)
  send(
    driver,
    message.InputReceived(message.NativeInput(
      session: session.key_to_string(current.key),
      generation: current.generation,
      value: value,
      selection_anchor: caret,
      selection_head: caret,
    )),
  )
}

/// Move the caret the way a click or a drag would.
pub fn place_caret(driver: Driver, offset: Int) -> Driver {
  select(driver, offset, offset)
}

pub fn select(driver: Driver, from: Int, to: Int) -> Driver {
  let current = model.active_session(driver.model)
  send(
    driver,
    message.SelectionMoved(message.SelectionSnapshot(
      session: session.key_to_string(current.key),
      generation: current.generation,
      selection_anchor: from,
      selection_head: to,
    )),
  )
}

pub fn text_of(driver: Driver) -> String {
  model.text(driver.model)
}

pub fn caret(driver: Driver) -> Int {
  selection.head(model.state(driver.model).selection)
}

pub fn anchor(driver: Driver) -> Int {
  selection.anchor(model.state(driver.model).selection)
}

pub fn selected(driver: Driver) -> String {
  let current = model.state(driver.model)
  let main = selection.main(current.selection)
  state.text(current)
  |> text.slice(selection.start(main), selection.end(main))
}

pub fn reset_log(driver: Driver) -> Driver {
  Driver(..driver, commands: [], outbound: [])
}

/// Reconcile a native insertion at the current selection, preserving suffixes.
pub fn type_at_selection(driver: Driver, value: String) -> Driver {
  let current = model.active_session(driver.model)
  let range = selection.main(current.state.selection)
  let from = selection.start(range)
  let to = selection.end(range)
  let before = model.text(driver.model)
  let content = text.slice(before, 0, from) <> value <> text.slice(before, to, text.width(before))
  let caret = from + text.width(value)
  send(driver, message.InputReceived(message.NativeInput(
    session: session.key_to_string(current.key), generation: current.generation,
    value: content, selection_anchor: caret, selection_head: caret,
  )))
}

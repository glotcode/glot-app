//// The Emacs keybinding state machine.
////
//// It owns the mark, the `C-x` prefix, and the universal argument; the kill
//// ring itself lives with the editor model because killing needs the document.
//// Coverage follows the compatibility matrix captured from
//// `@replit/codemirror-emacs`, with its demonstrable bugs corrected rather than
//// reproduced.

import gleam/int
import gleam/option.{type Option}
import gleam/string
import glot_frontend/public/editor/code_editor/command.{type EditorCommand}
import glot_frontend/public/editor/code_editor/keys.{type Key}

pub type Prefix {
  NoPrefix
  CtrlXPrefix
}

pub type Emacs {
  Emacs(
    mark: Option(Int),
    prefix: Prefix,
    argument: Option(Int),
    collecting_argument: Bool,
  )
}

pub type Response {
  /// The key produced commands. The repeat count is already resolved.
  Handled(commands: List(EditorCommand), repeat: Int)
  /// A prefix or argument is in progress; the label is shown as feedback.
  Pending(label: String)
  /// Not an Emacs binding — fall through to the default keymap.
  Unhandled
}

pub fn new() -> Emacs {
  Emacs(
    mark: option.None,
    prefix: NoPrefix,
    argument: option.None,
    collecting_argument: False,
  )
}

pub fn mark(state: Emacs) -> Option(Int) {
  state.mark
}

pub fn set_mark(state: Emacs, offset: Option(Int)) -> Emacs {
  Emacs(..state, mark: offset)
}

/// The status line shows the pending prefix, the universal argument, or the
/// active mark, so the mode is never invisible.
pub fn status(state: Emacs) -> Option(String) {
  case state.prefix, state.argument, state.mark {
    CtrlXPrefix, _, _ -> option.Some("C-x-")
    _, option.Some(value), _ -> option.Some("C-u " <> int.to_string(value))
    _, _, option.Some(_) -> option.Some("Mark set")
    _, _, _ -> option.None
  }
}

pub fn handle(state: Emacs, key: Key, mac: Bool) -> #(Emacs, Response) {
  case keys.is_modifier(key) {
    True -> #(state, Pending(""))
    False ->
      case state.prefix {
        CtrlXPrefix -> handle_ctrl_x(state, key)
        NoPrefix -> handle_root(state, key, mac)
      }
  }
}

fn reset(state: Emacs) -> Emacs {
  Emacs(..state, prefix: NoPrefix, argument: option.None, collecting_argument: False)
}

fn repeat_of(state: Emacs) -> Int {
  case state.argument {
    option.Some(value) -> value
    option.None -> 1
  }
}

fn done(state: Emacs, commands: List(EditorCommand)) -> #(Emacs, Response) {
  #(reset(state), Handled(commands: commands, repeat: repeat_of(state)))
}

fn extending(state: Emacs) -> Bool {
  state.mark != option.None
}

fn handle_root(state: Emacs, key: Key, mac: Bool) -> #(Emacs, Response) {
  let extend = extending(state)
  let meta = key.alt || { mac && key.ctrl && key.alt }

  case state.collecting_argument, digit_of(key) {
    True, option.Some(digit) -> {
      let next = case state.argument {
        option.Some(value) -> value * 10 + digit
        option.None -> digit
      }
      #(
        Emacs(..state, argument: option.Some(next)),
        Pending("C-u " <> int.to_string(next)),
      )
    }
    _, _ -> handle_binding(state, key, meta, extend)
  }
}

fn handle_binding(
  state: Emacs,
  key: Key,
  meta: Bool,
  extend: Bool,
) -> #(Emacs, Response) {
  let name = normalize(key.key)

  case key.ctrl, meta, name {
    // Movement
    True, False, "p" -> done(state, [command.MoveLine(False, extend)])
    True, False, "n" -> done(state, [command.MoveLine(True, extend)])
    True, False, "b" -> done(state, [command.MoveChar(False, extend)])
    True, False, "f" -> done(state, [command.MoveChar(True, extend)])
    True, False, "a" -> done(state, [command.MoveLineEdge(False, extend)])
    True, False, "e" -> done(state, [command.MoveLineEdge(True, extend)])
    False, True, "b" -> done(state, [command.MoveGroup(False, extend)])
    False, True, "f" -> done(state, [command.MoveGroup(True, extend)])
    True, False, "ArrowLeft" -> done(state, [command.MoveGroup(False, extend)])
    True, False, "ArrowRight" -> done(state, [command.MoveGroup(True, extend)])
    True, False, "Home" -> done(state, [command.MoveDocBoundary(False, extend)])
    True, False, "End" -> done(state, [command.MoveDocBoundary(True, extend)])
    False, True, "," -> done(state, [command.MoveDocBoundary(False, extend)])
    False, True, "." -> done(state, [command.MoveDocBoundary(True, extend)])
    True, False, "v" -> done(state, [command.MovePage(True, extend)])
    False, True, "v" -> done(state, [command.MovePage(False, extend)])
    True, False, "ArrowDown" -> done(state, [command.MovePage(True, extend)])
    // Upstream bound the selecting branch of `PageUp` to `selectPageDown`;
    // moving up is what the binding is for.
    True, False, "ArrowUp" -> done(state, [command.MovePage(False, extend)])

    // Selection
    False, True, "h" -> done(state, [command.SelectParagraph])
    False, True, "@" -> done(state, [command.SelectWord])
    // Upstream registered `markWord` as an empty function.
    False, True, "2" if key.shift -> done(state, [command.SelectWord])

    // Search
    True, False, "s" -> done(state, [command.OpenSearchPanel])
    True, False, "r" -> done(state, [command.OpenSearchPanel])
    True, True, "s" -> done(state, [command.FindNext])
    True, True, "r" -> done(state, [command.FindPrevious])
    False, True, "5" if key.shift -> done(state, [command.ReplaceNext])

    // Editing
    True, False, "d" -> done(state, [command.DeleteChar(True)])
    True, False, "m" -> done(state, [command.InsertNewlineAndIndent])
    True, False, "o" -> done(state, [command.SplitLine])
    True, False, "k" -> done(state, [command.KillLine])
    False, True, "d" -> done(state, [command.KillWord(True)])
    True, False, "Delete" -> done(state, [command.KillWord(True)])
    True, False, "Backspace" -> done(state, [command.KillWord(False)])
    False, True, "Backspace" -> done(state, [command.KillWord(False)])
    False, True, "Delete" -> done(state, [command.KillWord(False)])
    True, False, "y" -> done(state, [command.Yank])
    False, True, "y" -> done(state, [command.YankRotate])
    True, False, "w" -> done(state, [command.KillRegion(save_only: False)])
    False, True, "w" -> done(state, [command.KillRegion(save_only: True)])
    True, False, "t" -> done(state, [command.TransposeChars])
    False, True, "u" -> done(state, [command.ChangeWordCase(to_upper: True)])
    False, True, "l" -> done(state, [command.ChangeWordCase(to_upper: False)])
    False, True, ";" -> done(state, [command.ToggleComment])
    True, False, "/" -> done(state, [command.Undo])
    True, False, "z" -> done(state, [command.Undo])
    True, False, "_" -> done(state, [command.Undo])
    True, False, "-" -> done(state, [command.Redo])
    True, False, "?" -> done(state, [command.Redo])

    // Mark and quit
    True, False, " " -> done(state, [command.SetMark])
    True, False, "g" -> done(state, [command.KeyboardQuit])
    False, False, "Escape" -> done(state, [command.ClearMark])

    // View and prompts
    True, False, "l" -> done(state, [command.RecenterTopBottom])
    False, True, "s" -> done(state, [command.CenterSelection])
    False, True, "g" -> done(state, [command.OpenGotoLinePrompt])
    False, True, "x" -> done(state, [command.OpenCommandPrompt("M-x ")])

    // Prefix and argument
    True, False, "x" -> #(
      Emacs(..state, prefix: CtrlXPrefix),
      Pending("C-x-"),
    )
    True, False, "u" -> #(
      Emacs(..state, collecting_argument: True, argument: option.None),
      Pending("C-u"),
    )

    _, _, _ -> #(state, Unhandled)
  }
}

fn handle_ctrl_x(state: Emacs, key: Key) -> #(Emacs, Response) {
  let name = normalize(key.key)
  case key.ctrl, name {
    True, "x" -> done(state, [command.ExchangePointAndMark])
    True, "p" -> done(state, [command.SelectAll])
    False, "h" -> done(state, [command.SelectAll])
    True, "u" -> done(state, [command.ChangeCase(to_upper: True)])
    // Upstream mapped `C-x C-l` to upcase, duplicating `C-x C-u`.
    True, "l" -> done(state, [command.ChangeCase(to_upper: False)])
    False, "u" -> done(state, [command.Undo])
    False, "r" -> done(state, [command.SelectRectangularRegion])
    True, "g" -> done(state, [command.KeyboardQuit])
    _, _ -> #(reset(state), Handled(commands: [], repeat: 1))
  }
}

fn digit_of(key: Key) -> Option(Int) {
  case key.key {
    "0" -> option.Some(0)
    "1" -> option.Some(1)
    "2" -> option.Some(2)
    "3" -> option.Some(3)
    "4" -> option.Some(4)
    "5" -> option.Some(5)
    "6" -> option.Some(6)
    "7" -> option.Some(7)
    "8" -> option.Some(8)
    "9" -> option.Some(9)
    _ -> option.None
  }
}

fn normalize(key: String) -> String {
  case string.length(key) == 1 {
    True -> string.lowercase(key)
    False -> key
  }
}

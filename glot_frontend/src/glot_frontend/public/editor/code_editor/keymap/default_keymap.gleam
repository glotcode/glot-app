//// The default keymap.
////
//// This reproduces what Glot actually enabled: CodeMirror's `standardKeymap`
//// and `defaultKeymap`, the `searchKeymap`, the `historyKeymap`, and
//// `indentWithTab`. Bindings that were inert in Glot's configuration — syntax
//// movement without a syntax tree, extra cursors without multiple selections —
//// resolve to nothing rather than pretending to work.
////
//// `Mod-Enter` is Glot's Run shortcut and always wins.

import gleam/option.{type Option}
import glot_frontend/public/editor/code_editor/command.{type EditorCommand}
import glot_frontend/public/editor/code_editor/keys.{type Key}

pub fn resolve(key: Key, mac: Bool) -> Option(EditorCommand) {
  let mod = keys.has_mod(key, mac)
  let extend = key.shift

  case key.key {
    "ArrowLeft" -> option.Some(horizontal(key, mac, mod, extend, False))
    "ArrowRight" -> option.Some(horizontal(key, mac, mod, extend, True))
    "ArrowUp" -> vertical(key, mac, mod, extend, False)
    "ArrowDown" -> vertical(key, mac, mod, extend, True)

    "PageUp" -> option.Some(command.MovePage(forward: False, extend: extend))
    "PageDown" -> option.Some(command.MovePage(forward: True, extend: extend))

    "Home" ->
      case mod {
        True -> option.Some(command.MoveDocBoundary(forward: False, extend: extend))
        False ->
          option.Some(command.MoveLineBoundary(forward: False, extend: extend))
      }
    "End" ->
      case mod {
        True -> option.Some(command.MoveDocBoundary(forward: True, extend: extend))
        False ->
          option.Some(command.MoveLineBoundary(forward: True, extend: extend))
      }

    "Enter" ->
      case mod {
        True -> option.Some(command.RunSnippet)
        False -> option.Some(command.InsertNewlineAndIndent)
      }

    "Backspace" -> option.Some(backspace(key, mac, mod))
    "Delete" -> option.Some(forward_delete(key, mac, mod))

    "Tab" ->
      case extend {
        True -> option.Some(command.IndentLess)
        False -> option.Some(command.IndentMore)
      }

    "Escape" -> option.Some(command.SimplifySelection)

    "F3" ->
      case extend {
        True -> option.Some(command.FindPrevious)
        False -> option.Some(command.FindNext)
      }

    _ -> letter(key, mac, mod, extend)
  }
}

fn horizontal(
  key: Key,
  mac: Bool,
  mod: Bool,
  extend: Bool,
  forward: Bool,
) -> EditorCommand {
  case mac {
    True ->
      case key.meta, key.alt {
        True, _ -> command.MoveLineBoundary(forward: forward, extend: extend)
        _, True -> command.MoveGroup(forward: forward, extend: extend)
        _, _ -> command.MoveChar(forward: forward, extend: extend)
      }
    False ->
      case mod {
        True -> command.MoveGroup(forward: forward, extend: extend)
        False -> command.MoveChar(forward: forward, extend: extend)
      }
  }
}

fn vertical(
  key: Key,
  mac: Bool,
  mod: Bool,
  extend: Bool,
  forward: Bool,
) -> Option(EditorCommand) {
  case mod && key.alt {
    // `addCursorAbove` / `addCursorBelow` were inert without multiple
    // selections, so they stay unbound.
    True -> option.None
    False ->
      case key.alt, extend {
        True, True ->
          option.Some(case forward {
            True -> command.CopyLineDown
            False -> command.CopyLineUp
          })
        True, False ->
          option.Some(case forward {
            True -> command.MoveLineDown
            False -> command.MoveLineUp
          })
        False, _ ->
          case mac, key.meta, key.ctrl {
            True, True, _ ->
              option.Some(command.MoveDocBoundary(
                forward: forward,
                extend: extend,
              ))
            True, _, True ->
              option.Some(command.MovePage(forward: forward, extend: extend))
            _, _, _ ->
              option.Some(command.MoveLine(forward: forward, extend: extend))
          }
      }
  }
}

fn backspace(key: Key, mac: Bool, mod: Bool) -> EditorCommand {
  case mac, key.meta, key.alt {
    True, True, _ -> command.DeleteLineBoundary(forward: False)
    True, _, True -> command.DeleteGroup(forward: False)
    False, _, _ ->
      case mod {
        True -> command.DeleteGroup(forward: False)
        False -> command.DeleteChar(forward: False)
      }
    _, _, _ -> command.DeleteChar(forward: False)
  }
}

fn forward_delete(key: Key, mac: Bool, mod: Bool) -> EditorCommand {
  case mac, key.meta, key.alt {
    True, True, _ -> command.DeleteLineBoundary(forward: True)
    True, _, True -> command.DeleteGroup(forward: True)
    False, _, _ ->
      case mod {
        True -> command.DeleteGroup(forward: True)
        False -> command.DeleteChar(forward: True)
      }
    _, _, _ -> command.DeleteChar(forward: True)
  }
}

fn letter(
  key: Key,
  mac: Bool,
  mod: Bool,
  extend: Bool,
) -> Option(EditorCommand) {
  case lower(key.key), mod, key.alt, extend {
    "a", True, False, False -> option.Some(command.SelectAll)
    "z", True, False, False -> option.Some(command.Undo)
    "z", True, False, True -> option.Some(command.Redo)
    "y", True, False, False -> option.Some(command.Redo)
    "u", True, False, False -> option.Some(command.UndoSelection)
    "u", True, False, True -> option.Some(command.RedoSelection)
    "u", False, True, False -> option.Some(command.RedoSelection)
    "f", True, False, False -> option.Some(command.OpenSearchPanel)
    "g", True, False, False -> option.Some(command.FindNext)
    "g", True, False, True -> option.Some(command.FindPrevious)
    "g", True, True, False -> option.Some(command.OpenGotoLinePrompt)
    "d", True, False, False -> option.Some(command.SelectNextOccurrence)
    "l", True, False, True -> option.Some(command.SelectSelectionMatches)
    "l", False, True, False -> option.Some(command.SelectLine)
    "l", True, False, False ->
      case mac {
        True -> option.Some(command.SelectLine)
        False -> option.None
      }
    "[", True, False, False -> option.Some(command.IndentLess)
    "]", True, False, False -> option.Some(command.IndentMore)
    "\\", True, True, False -> option.Some(command.IndentSelection)
    "\\", True, False, True -> option.Some(command.MoveToMatchingBracket(False))
    "k", True, False, True -> option.Some(command.DeleteLine)
    "/", True, False, False -> option.Some(command.ToggleComment)
    "a", False, True, True -> option.Some(command.ToggleBlockComment)
    // Upstream bound `Ctrl-m` everywhere but macOS and `Shift-Alt-m` there.
    // `Ctrl-m` is free on macOS too, and the Tab escape is easier to document
    // when it is the same chord everywhere, so both are accepted.
    "m", _, False, False ->
      case key.ctrl && !key.meta {
        True -> option.Some(command.ToggleTabFocusMode)
        False -> option.None
      }
    "m", False, True, True ->
      case mac {
        True -> option.Some(command.ToggleTabFocusMode)
        False -> option.None
      }
    _, _, _, _ -> mac_control(key, mac)
  }
}

/// The macOS `emacsStyleKeymap` that `standardKeymap` folds in.
fn mac_control(key: Key, mac: Bool) -> Option(EditorCommand) {
  case mac && key.ctrl && !key.meta && !key.alt {
    False -> option.None
    True ->
      case lower(key.key) {
        "b" -> option.Some(command.MoveChar(forward: False, extend: key.shift))
        "f" -> option.Some(command.MoveChar(forward: True, extend: key.shift))
        "p" -> option.Some(command.MoveLine(forward: False, extend: key.shift))
        "n" -> option.Some(command.MoveLine(forward: True, extend: key.shift))
        "a" ->
          option.Some(command.MoveLineEdge(forward: False, extend: key.shift))
        "e" ->
          option.Some(command.MoveLineEdge(forward: True, extend: key.shift))
        "d" -> option.Some(command.DeleteChar(forward: True))
        "h" -> option.Some(command.DeleteChar(forward: False))
        "k" -> option.Some(command.DeleteToLineEnd)
        "o" -> option.Some(command.SplitLine)
        "t" -> option.Some(command.TransposeChars)
        "v" -> option.Some(command.MovePage(forward: True, extend: key.shift))
        _ -> option.None
      }
  }
}

fn lower(key: String) -> String {
  case key {
    "A" -> "a"
    "B" -> "b"
    "D" -> "d"
    "E" -> "e"
    "F" -> "f"
    "G" -> "g"
    "H" -> "h"
    "K" -> "k"
    "L" -> "l"
    "M" -> "m"
    "N" -> "n"
    "O" -> "o"
    "P" -> "p"
    "T" -> "t"
    "U" -> "u"
    "V" -> "v"
    "Y" -> "y"
    "Z" -> "z"
    other -> other
  }
}

//// Keyboard events as a value.
////
//// `key` holds the browser's `KeyboardEvent.key`, so it is already
//// layout-aware and IME-aware; the modifiers are kept separately. Nothing here
//// touches the DOM, which is what lets keymap traces be tested as data.

import gleam/string

pub type Key {
  Key(key: String, ctrl: Bool, alt: Bool, shift: Bool, meta: Bool)
}

pub fn plain(key: String) -> Key {
  Key(key: key, ctrl: False, alt: False, shift: False, meta: False)
}

pub fn ctrl(key: String) -> Key {
  Key(..plain(key), ctrl: True)
}

pub fn alt(key: String) -> Key {
  Key(..plain(key), alt: True)
}

pub fn shift(key: String) -> Key {
  Key(..plain(key), shift: True)
}

pub fn meta(key: String) -> Key {
  Key(..plain(key), meta: True)
}

/// `Mod` is Cmd on macOS and Ctrl everywhere else, matching CodeMirror.
pub fn has_mod(key: Key, mac: Bool) -> Bool {
  case mac {
    True -> key.meta
    False -> key.ctrl
  }
}

/// True when the key would insert a character if nothing intercepted it.
pub fn is_printable(key: Key) -> Bool {
  !key.ctrl && !key.meta && string.length(key.key) == 1
}

pub fn is_modifier(key: Key) -> Bool {
  case key.key {
    "Shift" | "Control" | "Alt" | "Meta" | "CapsLock" | "NumLock"
    | "ScrollLock" | "AltGraph" | "Fn" | "FnLock" | "Hyper" | "Super" -> True
    _ -> False
  }
}

/// Combinations the browser or the operating system keeps for itself. These are
/// the ones a page cannot cancel — opening a tab or window, closing one,
/// quitting, and the reserved function keys — so the editor never claims them
/// and never turns them into a fallback edit.
///
/// Combinations a page *can* cancel are not listed here even when a browser
/// also uses them, because Vim needs `Ctrl-R` for redo and Emacs needs `Ctrl-R`
/// and `Ctrl-P`; the default keymap binds neither, so nothing changes for
/// people who never choose those modes.
pub fn is_browser_reserved(key: Key, mac: Bool) -> Bool {
  let mod = has_mod(key, mac)
  case key.key {
    "F1" | "F5" | "F11" | "F12" -> True
    "n" | "N" | "t" | "T" | "w" | "W" | "q" | "Q" -> mod && !key.alt
    "Tab" -> mod || key.alt
    _ -> False
  }
}

/// A stable printable description, used by the mode and prefix status line.
pub fn describe(key: Key) -> String {
  let parts =
    modifier_label(key.ctrl, "Ctrl")
    <> modifier_label(key.alt, "Alt")
    <> modifier_label(key.shift, "Shift")
    <> modifier_label(key.meta, "Cmd")
  parts <> key_label(key.key)
}

fn modifier_label(active: Bool, label: String) -> String {
  case active {
    True -> label <> "-"
    False -> ""
  }
}

fn key_label(key: String) -> String {
  case key {
    " " -> "Space"
    _ -> key
  }
}

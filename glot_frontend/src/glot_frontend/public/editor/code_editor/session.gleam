//// Per-file editing sessions.
////
//// A session is identified by a stable key that the editor page mints once per
//// file (and once for stdin). The key is independent of the filename and of the
//// file's position in the list, so renaming a file or inserting one before it
//// keeps its history, cursor, selection, and scroll intact. Deleting a file
//// removes its session.
////
//// Each session also carries a document generation. Browser callbacks and
//// scheduled highlighting work quote the session key and generation they were
//// issued for, and anything quoting a stale pair is dropped.

import gleam/int
import glot_frontend/public/editor/code_editor/highlight_state
import glot_frontend/public/editor/code_editor/state.{type State}

pub type Key {
  Key(String)
}

pub fn key_to_string(key: Key) -> String {
  let Key(value) = key
  value
}

/// Keys minted by the editor page. `file` keys carry an opaque counter, never
/// a filename or an index.
pub fn file_key(counter: Int) -> Key {
  Key("file-" <> int.to_string(counter))
}

pub fn stdin_key() -> Key {
  Key("stdin")
}

pub type Session {
  Session(
    key: Key,
    generation: Int,
    state: State,
    scroll_top: Int,
    scroll_left: Int,
    highlight: highlight_state.Cache,
  )
}

pub fn new(key: Key, content: String) -> Session {
  Session(
    key: key,
    generation: 0,
    state: state.new(content),
    scroll_top: 0,
    scroll_left: 0,
    highlight: highlight_state.new(),
  )
}

/// Explicit document replacement: a fresh generation and a fresh history, which
/// is what makes every in-flight callback for the old document stale.
pub fn replace(session: Session, content: String) -> Session {
  Session(
    key: session.key,
    generation: session.generation + 1,
    state: state.new(content),
    scroll_top: 0,
    scroll_left: 0,
    highlight: highlight_state.new(),
  )
}

pub fn is_current(session: Session, key: Key, generation: Int) -> Bool {
  session.key == key && session.generation == generation
}

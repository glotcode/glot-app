//// The editor workspace: which tab is selected, and the code editor sessions
//// behind the files and stdin.
////
//// Session keys are minted here and never derived from a filename or a list
//// index, so the editing state of a file survives renames, reordering, and the
//// deletion of other files.

import gleam/list
import gleam/option
import glot_core/language
import glot_core/snippet/snippet_model
import glot_frontend/public/editor/code_editor/model as code_editor_model
import glot_frontend/public/editor/code_editor/session.{type Key}
import glot_frontend/public/editor/code_editor/settings_bridge
import glot_frontend/public/editor/environment.{type Environment}
import glot_frontend/public/editor/settings
import glot_frontend/public/editor/model.{
  type EditorTab, type Workspace, FileTab, StdinTab, Workspace,
}

pub fn build(
  files: List(snippet_model.File),
  stdin: option.Option(String),
  selected_tab: EditorTab,
  snippet_language: language.Language,
  found: Environment,
) -> Workspace {
  let keys = list.index_map(files, fn(_, index) { session.file_key(index) })
  let active = key_for(keys, selected_tab)
  let editor =
    code_editor_model.new(
      active,
      content_for(files, stdin, selected_tab),
      snippet_language,
      !language.is_writable(snippet_language),
      settings_bridge.from_settings(found.settings.keyboard_bindings),
      found.mac,
    )

  Workspace(
    selected_tab: selected_tab,
    editor: open_all(editor, keys, files, stdin),
    file_sessions: keys,
    next_session: list.length(files),
  )
}

fn open_all(
  editor: code_editor_model.Model,
  keys: List(Key),
  files: List(snippet_model.File),
  stdin: option.Option(String),
) -> code_editor_model.Model {
  let with_files =
    list.zip(keys, files)
    |> list.fold(editor, fn(current, entry) {
      let #(key, file) = entry
      code_editor_model.open_session(current, key, file.content)
    })

  case stdin {
    option.Some(content) ->
      code_editor_model.open_session(with_files, session.stdin_key(), content)
    option.None -> with_files
  }
}

pub fn key_for(keys: List(Key), tab: EditorTab) -> Key {
  case tab {
    StdinTab -> session.stdin_key()
    FileTab(index) ->
      case list.drop(keys, index) {
        [found, ..] -> found
        [] -> session.file_key(index)
      }
  }
}

pub fn active_key(current: Workspace) -> Key {
  key_for(current.file_sessions, current.selected_tab)
}


fn content_for(
  files: List(snippet_model.File),
  stdin: option.Option(String),
  tab: EditorTab,
) -> String {
  case tab {
    StdinTab ->
      case stdin {
        option.Some(content) -> content
        option.None -> ""
      }
    FileTab(index) ->
      case list.drop(files, index) {
        [found, ..] -> found.content
        [] -> ""
      }
  }
}

/// Switch tabs. The outgoing session keeps everything; the incoming one is
/// restored exactly as it was left.
pub fn select(current: Workspace, tab: EditorTab) -> Workspace {
  Workspace(
    ..current,
    selected_tab: tab,
    editor: code_editor_model.activate(
      current.editor,
      key_for(current.file_sessions, tab),
    ),
  )
}

pub fn add_file(current: Workspace, index: Int) -> Workspace {
  let key = session.file_key(current.next_session)
  Workspace(
    selected_tab: FileTab(index),
    file_sessions: list.append(current.file_sessions, [key]),
    next_session: current.next_session + 1,
    editor: code_editor_model.activate(
      code_editor_model.open_session(current.editor, key, ""),
      key,
    ),
  )
}

pub fn add_stdin(current: Workspace) -> Workspace {
  let key = session.stdin_key()
  Workspace(
    ..current,
    selected_tab: StdinTab,
    editor: code_editor_model.activate(
      code_editor_model.open_session(current.editor, key, ""),
      key,
    ),
  )
}

/// Deleting a file removes its session; the editing state of every other file
/// is untouched because nothing is keyed by position.
pub fn remove_file(
  current: Workspace,
  index: Int,
  next_tab: EditorTab,
) -> Workspace {
  let removed = key_for(current.file_sessions, FileTab(index))
  let keys =
    list.index_map(current.file_sessions, fn(key, position) {
      #(position, key)
    })
    |> list.filter(fn(entry) { entry.0 != index })
    |> list.map(fn(entry) { entry.1 })

  Workspace(
    ..current,
    selected_tab: next_tab,
    file_sessions: keys,
    editor: code_editor_model.activate(
      code_editor_model.close_session(current.editor, removed),
      key_for(keys, next_tab),
    ),
  )
}

pub fn remove_stdin(current: Workspace, next_tab: EditorTab) -> Workspace {
  Workspace(
    ..current,
    selected_tab: next_tab,
    editor: code_editor_model.activate(
      code_editor_model.close_session(current.editor, session.stdin_key()),
      key_for(current.file_sessions, next_tab),
    ),
  )
}

/// Explicit document replacement — a restored draft, or a snippet reloaded into
/// the same page. Every session restarts with a new generation, which is what
/// makes callbacks queued for the previous document detectably stale.
pub fn replace_documents(
  current current: Workspace,
  files files: List(snippet_model.File),
  stdin stdin: option.Option(String),
  selected_tab selected_tab: EditorTab,
) -> Workspace {
  let keys = case list.length(files) == list.length(current.file_sessions) {
    True -> current.file_sessions
    False ->
      list.index_map(files, fn(_, index) {
        session.file_key(current.next_session + index)
      })
  }
  let next_counter = case keys == current.file_sessions {
    True -> current.next_session
    False -> current.next_session + list.length(files)
  }

  let replaced =
    list.zip(keys, files)
    |> list.fold(current.editor, fn(current, entry) {
      let #(key, file) = entry
      code_editor_model.replace_document(current, key, file.content)
    })

  let with_stdin = case stdin {
    option.Some(content) ->
      code_editor_model.replace_document(
        replaced,
        session.stdin_key(),
        content,
      )
    option.None ->
      code_editor_model.close_session(replaced, session.stdin_key())
  }

  Workspace(
    selected_tab: selected_tab,
    file_sessions: keys,
    next_session: next_counter,
    editor: code_editor_model.activate(with_stdin, key_for(keys, selected_tab)),
  )
}

/// Switch keyboard bindings, resetting the modal state machines.
pub fn set_bindings(
  current: Workspace,
  bindings: settings.KeyboardBindings,
) -> Workspace {
  Workspace(
    ..current,
    editor: code_editor_model.set_bindings(
      current.editor,
      settings_bridge.from_settings(bindings),
    ),
  )
}

/// Keep the editor's language and read-only state in step with the snippet.
pub fn set_language(
  current: Workspace,
  snippet_language: language.Language,
) -> Workspace {
  Workspace(
    ..current,
    editor: code_editor_model.set_read_only(
      code_editor_model.set_language(current.editor, snippet_language),
      !language.is_writable(snippet_language),
    ),
  )
}

/// The text of the active session, always current with the last edit.
pub fn selected_text(current: Workspace) -> String {
  code_editor_model.text(current.editor)
}

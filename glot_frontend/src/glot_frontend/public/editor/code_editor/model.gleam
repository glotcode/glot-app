//// The code editor's model.
////
//// One model holds every open file's session, so switching tabs is a change of
//// the active key rather than a document reload, and each file keeps its own
//// history, cursor, selection, and scroll.

import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option}
import glot_core/language.{type Language}
import glot_frontend/public/editor/code_editor/document
import glot_frontend/public/editor/code_editor/editing
import glot_frontend/public/editor/code_editor/highlight_state
import glot_frontend/public/editor/code_editor/keymap/emacs.{type Emacs}
import glot_frontend/public/editor/code_editor/keymap/vim.{type Vim}
import glot_frontend/public/editor/code_editor/search
import glot_frontend/public/editor/code_editor/selection
import glot_frontend/public/editor/code_editor/session.{type Key, type Session}
import glot_frontend/public/editor/code_editor/state.{type State}
import glot_frontend/public/editor/code_editor/syntax/language_rules
import glot_frontend/public/editor/code_editor/syntax/rules
import glot_frontend/public/editor/code_editor/settings_bridge.{type BindingMode}

/// The search-and-replace panel.
pub type SearchPanel {
  SearchPanel(open: Bool, query: search.Query, focus_field: Bool)
}

/// An accessible one-line prompt: Vim's `:` and `/`, Emacs' `M-x` and goto-line.
pub type Prompt {
  Prompt(kind: PromptKind, label: String, value: String)
}

pub type PromptKind {
  ExPrompt
  SearchPrompt(forward: Bool)
  CommandPrompt
  GotoLinePrompt
}

/// Measured geometry. Defaults are used until the first measurement arrives, so
/// the first paint is still correct, just conservatively large.
pub type Viewport {
  Viewport(
    line_height: Int,
    height: Int,
    width: Int,
    char_width: Int,
    scroll_top: Int,
    scroll_left: Int,
  )
}

pub fn default_viewport() -> Viewport {
  Viewport(
    line_height: 26,
    height: 640,
    width: 800,
    char_width: 10,
    scroll_top: 0,
    scroll_left: 0,
  )
}

pub type Model {
  Model(
    /// Initial textarea content; kept stable so renders never rewrite its DOM text.
    initial_content: String,
    active: Key,
    sessions: Dict(String, Session),
    order: List(String),
    language: Language,
    read_only: Bool,
    mac: Bool,
    bindings: BindingMode,
    vim: Vim,
    emacs: Emacs,
    kill_ring: List(String),
    kill_index: Int,
    /// The range the most recent yank inserted, so `M-y` can replace it.
    last_yank: Option(#(Int, Int)),
    search: SearchPanel,
    prompt: Option(Prompt),
    status: Option(String),
    tab_focus_mode: Bool,
    composing: Bool,
    focused: Bool,
    viewport: Viewport,
    rendered: List(highlight_state.HighlightedLine),
    rendered_from: Int,
  )
}

pub fn new(
  key: Key,
  content: String,
  language: Language,
  read_only: Bool,
  bindings: BindingMode,
  mac: Bool,
) -> Model {
  let name = session.key_to_string(key)
  refresh(Model(
    initial_content: content,
    active: key,
    sessions: dict.from_list([#(name, session.new(key, content))]),
    order: [name],
    language: language,
    read_only: read_only,
    mac: mac,
    bindings: bindings,
    vim: vim.new(),
    emacs: emacs.new(),
    kill_ring: [],
    kill_index: 0,
    last_yank: option.None,
    search: SearchPanel(
      open: False,
      query: search.empty_query(),
      focus_field: False,
    ),
    prompt: option.None,
    status: option.None,
    tab_focus_mode: False,
    composing: False,
    focused: False,
    viewport: default_viewport(),
    rendered: [],
    rendered_from: 0,
  ))
}

// -- Sessions ----------------------------------------------------------------

pub fn session_for(model: Model, key: Key) -> Option(Session) {
  dict.get(model.sessions, session.key_to_string(key))
  |> option.from_result
}

pub fn active_session(model: Model) -> Session {
  case session_for(model, model.active) {
    option.Some(found) -> found
    option.None -> session.new(model.active, "")
  }
}

pub fn state(model: Model) -> State {
  active_session(model).state
}

pub fn text(model: Model) -> String {
  state.text(state(model))
}

pub fn text_of(model: Model, key: Key) -> Option(String) {
  case session_for(model, key) {
    option.Some(found) -> option.Some(state.text(found.state))
    option.None -> option.None
  }
}

pub fn put_session(model: Model, updated: Session) -> Model {
  let name = session.key_to_string(updated.key)
  Model(
    ..model,
    sessions: dict.insert(model.sessions, name, updated),
    order: case list.contains(model.order, name) {
      True -> model.order
      False -> list.append(model.order, [name])
    },
  )
}

/// Open a file, keeping its existing session when it already has one.
pub fn open_session(model: Model, key: Key, content: String) -> Model {
  case session_for(model, key) {
    option.Some(_) -> model
    option.None -> put_session(model, session.new(key, content))
  }
}

pub fn activate(model: Model, key: Key) -> Model {
  let model = case key == model.active {
    True -> model
    False -> Model(..model, vim: vim.Vim(..model.vim, mode: vim.NormalMode, pending: [], search_operator: option.None, search_count: 1, pending_register: option.None, insertion: option.None, block_insertion: option.None, last_visual: option.None))
  }
  refresh(case session_for(model, key) {
    option.Some(_) -> Model(..model, active: key)
    option.None ->
      Model(..put_session(model, session.new(key, "")), active: key)
  })
}

pub fn close_session(model: Model, key: Key) -> Model {
  let name = session.key_to_string(key)
  Model(
    ..model,
    sessions: dict.delete(model.sessions, name),
    order: list.filter(model.order, fn(item) { item != name }),
  )
}

/// Explicit document replacement — a restored draft, or a newly loaded snippet.
/// The session gets a new generation and an empty history.
pub fn replace_document(model: Model, key: Key, content: String) -> Model {
  let model = case key == model.active {
    True -> Model(..model, vim: vim.Vim(..model.vim, mode: vim.NormalMode, pending: [], search_operator: option.None, search_count: 1, pending_register: option.None, insertion: option.None, block_insertion: option.None, last_visual: option.None))
    False -> model
  }
  case session_for(model, key) {
    option.Some(found) -> put_session(model, session.replace(found, content))
    option.None -> put_session(model, session.new(key, content))
  }
}

/// Changing the language invalidates every cached lexical state, because the
/// rules that produced them no longer apply.
pub fn set_language(model: Model, language: Language) -> Model {
  case model.language == language {
    True -> model
    False ->
      Model(
        ..model,
        language: language,
        sessions: dict.map_values(model.sessions, fn(_, item) {
          session.Session(..item, highlight: highlight_state.new())
        }),
      )
  }
}

pub fn set_read_only(model: Model, read_only: Bool) -> Model {
  Model(..model, read_only: read_only)
}

pub fn set_bindings(model: Model, bindings: BindingMode) -> Model {
  case model.bindings == bindings {
    True -> model
    False ->
      Model(
        ..model,
        bindings: bindings,
        vim: vim.new(),
        emacs: emacs.new(),
        status: option.None,
      )
  }
}

// -- Derived -----------------------------------------------------------------

/// Editing settings for the current language.
pub fn context(model: Model) -> editing.Context {
  editing.Context(
    indent_unit: "  ",
    line_comment: language_rules.line_comment(model.language),
    block_comment: language_rules.block_comment(model.language),
    page_lines: page_lines(model),
  )
}

/// Extra lines rendered above and below the viewport so that scrolling does not
/// expose unhighlighted text before the next frame.
pub const overscan = 20

/// The lines the highlighting layer renders.
pub fn visible_range(model: Model) -> #(Int, Int) {
  let current = active_session(model)
  let total = document.line_count(current.state.doc)
  let first =
    int_max(0, current.scroll_top / int_max(1, model.viewport.line_height) - overscan)
  let last = int_min(total, first + page_lines(model) + 2 * overscan)
  #(first, last)
}

/// Re-tokenise the viewport, reusing and extending the per-line lexical state
/// cache. Called after anything that can change what is on screen.
pub fn refresh(model: Model) -> Model {
  let current = active_session(model)
  let #(first, last) = visible_range(model)
  let #(lines, cache) =
    highlight_state.lines(
      rules_for(model, current),
      current.highlight,
      current.state.doc,
      first,
      last,
    )
  Model(
    ..put_session(model, session.Session(..current, highlight: cache)),
    rendered: lines,
    rendered_from: first,
  )
}

/// Source files are highlighted with the snippet's language. Stdin is not code,
/// so it is rendered as plain text no matter what the snippet's language is.
fn rules_for(model: Model, current: session.Session) -> rules.Rules {
  case current.key == session.stdin_key() {
    True -> rules.plain()
    False -> language_rules.for_language(model.language)
  }
}

fn int_min(a: Int, b: Int) -> Int {
  case a < b {
    True -> a
    False -> b
  }
}

pub fn page_lines(model: Model) -> Int {
  case model.viewport.line_height <= 0 {
    True -> 20
    False -> int_max(1, model.viewport.height / model.viewport.line_height)
  }
}

fn int_max(a: Int, b: Int) -> Int {
  case a > b {
    True -> a
    False -> b
  }
}

/// True while typed characters should reach the textarea directly.
pub fn accepts_native_input(model: Model) -> Bool {
  case model.read_only {
    True -> False
    False ->
      case model.bindings {
        settings_bridge.VimLike -> vim.accepts_native_input(model.vim)
        _ -> True
      }
  }
}

/// Browser endpoints differ from Vim's inclusive cursor positions.
pub fn browser_selection(model: Model) -> selection.Selection {
  case model.bindings {
    settings_bridge.VimLike -> vim.browser_selection(model.vim, state(model))
    _ -> state(model).selection
  }
}

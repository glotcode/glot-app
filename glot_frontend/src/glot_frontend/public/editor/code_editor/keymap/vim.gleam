//// The Vim keybinding state machine.
////
//// Keys are turned into Vim tokens, accumulated until they form a complete
//// command, and then resolved against the current document into ordinary editor
//// commands. Modes, counts, registers, marks, macros, repeat, and the text
//// objects all live here; nothing about Vim leaks into the editing operations
//// themselves.
////
//// Coverage follows the compatibility matrix captured from
//// `@replit/codemirror-vim-core`.

import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleam/string
import glot_frontend/public/editor/code_editor/command.{type EditorCommand}
import glot_frontend/public/editor/code_editor/document
import glot_frontend/public/editor/code_editor/keymap/vim_block
import glot_frontend/public/editor/code_editor/keymap/vim_ex
import glot_frontend/public/editor/code_editor/keymap/vim_object
import glot_frontend/public/editor/code_editor/keymap/vim_pattern
import glot_frontend/public/editor/code_editor/keymap/vim_sentence
import glot_frontend/public/editor/code_editor/keymap/vim_tag
import glot_frontend/public/editor/code_editor/keys.{type Key}
import glot_frontend/public/editor/code_editor/movement
import glot_frontend/public/editor/code_editor/search as editor_search
import glot_frontend/public/editor/code_editor/selection
import glot_frontend/public/editor/code_editor/state.{type State}
import glot_frontend/public/editor/code_editor/text
import glot_frontend/public/editor/code_editor/transaction

pub type VisualKind {
  CharacterWise
  LineWise
  BlockWise
}

pub type Mode {
  NormalMode
  InsertMode
  ReplaceMode
  VisualMode(kind: VisualKind)
}

pub type Register {
  Register(text: String, linewise: Bool, block_width: Option(Int))
}

pub type Stroke {
  KeyStroke(token: String)
  EditStroke(from_delta: Int, to_delta: Int, insert: String)
  VisualStroke(kind: VisualKind, lines: Int, columns: Int)
  SearchStroke(pattern: String, forward: Bool)
}

pub type ReplaceUndo {
  ReplaceUndo(from: Int, to: Int, value: String)
}

pub type BlockInsertion {
  BlockInsertion(first: Int, last: Int, column: Int, append: Bool, change: Bool, return_to: Int, line_end: Bool)
}

pub type InsertSession {
  InsertSession(before: State, opened: State, strokes: List(Stroke), started: Bool, opener_length: Int)
}

pub type Vim {
  Vim(
    mode: Mode,
    pending: List(String),
    registers: Dict(String, Register),
    marks: Dict(String, Int),
    recording: Option(#(String, List(Stroke))),
    macros: Dict(String, List(Stroke)),
    last_edit: Option(List(Stroke)),
    last_search: Option(String),
    search_query: editor_search.Query,
    search_forward: Bool,
    search_count: Int,
    search_operator: Option(#(String, Int)),
    last_char_search: Option(#(String, String)),
    visual_anchor: Int,
    goal_column: Option(Int),
    goal_line_end: Bool,
    last_visual: Option(#(VisualKind, Int, Int)),
    pending_register: Option(String),
    insert_repeat: Int,
    expanding_insert: Bool,
    replace_undo: List(ReplaceUndo),
    insertion: Option(InsertSession),
    block_insertion: Option(BlockInsertion),
  )
}

pub type PromptKind {
  ExPrompt
  SearchPrompt(forward: Bool)
}

pub type Response {
  Handled(commands: List(EditorCommand))
  Pending(label: String)
  Unhandled
  Prompt(kind: PromptKind)
  /// Feed these tokens back through the state machine, applying each command
  /// batch to the document in turn. Used by `.` and by macro playback.
  Replay(tokens: List(Stroke))
}

pub fn new() -> Vim {
  Vim(
    mode: NormalMode,
    pending: [],
    registers: dict.new(),
    marks: dict.new(),
    recording: option.None,
    macros: dict.new(),
    last_edit: option.None,
    last_search: option.None,
    search_query: editor_search.Query(..editor_search.empty_query(), case_sensitive: True),
    search_forward: True,
    search_count: 1,
    search_operator: option.None,
    last_char_search: option.None,
    visual_anchor: 0,
    goal_column: option.None,
    goal_line_end: False,
    last_visual: option.None,
    pending_register: option.None,
    insert_repeat: 1,
    expanding_insert: False,
    replace_undo: [],
    insertion: option.None,
    block_insertion: option.None,
  )
}

pub fn mode(vim: Vim) -> Mode {
  vim.mode
}

/// True while native typing should reach the textarea.
pub fn accepts_native_input(vim: Vim) -> Bool {
  case vim.mode {
    InsertMode | ReplaceMode -> True
    NormalMode | VisualMode(_) -> False
  }
}

/// The mode and any pending keys, shown in the status line.
pub fn status(vim: Vim) -> String {
  let base = case vim.mode {
    NormalMode -> "NORMAL"
    InsertMode -> "INSERT"
    ReplaceMode -> "REPLACE"
    VisualMode(CharacterWise) -> "VISUAL"
    VisualMode(LineWise) -> "VISUAL LINE"
    VisualMode(BlockWise) -> "VISUAL BLOCK"
  }
  let recording = case vim.recording {
    option.Some(#(register, _)) -> " recording @" <> register
    option.None -> ""
  }
  let pending = case vim.pending {
    [] -> ""
    tokens -> " " <> string.concat(tokens)
  }
  base <> recording <> pending
}

pub fn set_mode(vim: Vim, next: Mode) -> Vim {
  Vim(..vim, mode: next, pending: [])
}

pub fn store_register(
  vim: Vim,
  name: String,
  value: String,
  linewise: Bool,
) -> Vim {
  Vim(
    ..vim,
    registers: dict.insert(
      vim.registers,
      name,
      Register(text: value, linewise: linewise, block_width: option.None),
    ),
  )
}

// -- Entry point -------------------------------------------------------------

pub fn handle(vim: Vim, state: State, key: Key) -> #(Vim, Response) {
  case keys.is_modifier(key) {
    True -> #(vim, Pending(status(vim)))
    False -> {
      let token = token_of(key)
      let vim = case accepts_native_input(vim) && !string.starts_with(token, "<") {
        True -> vim
        False -> record(vim, KeyStroke(token))
      }
      case vim.mode {
        InsertMode | ReplaceMode -> handle_insert(vim, state, token)
        NormalMode | VisualMode(_) -> handle_command(vim, state, token)
      }
    }
  }
}

fn record(vim: Vim, token: Stroke) -> Vim {
  case vim.recording, vim.expanding_insert {
    option.Some(#(register, tokens)), False ->
      Vim(..vim, recording: option.Some(#(register, [token, ..tokens])))
    _, _ -> vim
  }
}

fn handle_insert(vim: Vim, state: State, token: String) -> #(Vim, Response) {
  let vim = case string.starts_with(token, "<") { True -> append_insert_stroke(vim, KeyStroke(token)) False -> vim }
  case token {
    "<Esc>" | "<C-c>" | "<C-[>" -> finish_insert(vim, state)
    "<BS>" | "<C-h>" -> case vim.mode {
      ReplaceMode -> replace_backspace(vim, state)
      _ -> #(vim, Unhandled)
    }
    "<C-w>" -> #(vim, Handled([command.DeleteGroup(forward: False)]))
    "<C-u>" -> #(vim, Handled([command.DeleteToLineStart]))
    "<C-t>" -> #(vim, Handled([command.IndentMore]))
    "<C-d>" -> #(vim, Handled([command.IndentLess]))
    "<C-o>" -> #(
      Vim(..vim, mode: NormalMode),
      Pending("INSERT (pending normal)"),
    )
    _ -> {
      let _ = state
      #(vim, Unhandled)
    }
  }
}

fn handle_command(vim: Vim, state: State, token: String) -> #(Vim, Response) {
  // Escape cancels the entire pending command, including counts and registers.
  let tokens = case key_to_key(vim, token) {
    "<Esc>" -> ["<Esc>"]
    mapped -> list.append(vim.pending, [mapped])
  }
  case interpret(Vim(..vim, pending: tokens), state, tokens) {
    option.Some(#(next, response)) -> {
      let next = case in_visual(vim) && !in_visual(next) {
        True ->
          Vim(
            ..next,
            last_visual: option.Some(#(
              visual_kind(vim),
              vim.visual_anchor,
              cursor(state),
            )),
          )
        False -> next
      }
      let next = case accepts_native_input(next) && !accepts_native_input(vim) {
        True -> {
          let before = case next.block_insertion {
            option.Some(block) -> state.State(..state, selection: selection.from(block.return_to))
            option.None -> case vim.mode, list.reverse(tokens) {
              VisualMode(CharacterWise), ["C", ..] | VisualMode(LineWise), ["C", ..]
              | VisualMode(CharacterWise), ["S", ..] | VisualMode(LineWise), ["S", ..]
              | VisualMode(CharacterWise), ["R", ..] | VisualMode(LineWise), ["R", ..] ->
                state.State(..state, selection: selection.from(movement.line_start(state.doc, cursor(state))))
              _, _ -> state
            }
          }
          let #(count, opener) = insertion_opener(vim, tokens)
          let strokes = edit_strokes(vim, state, opener)
          Vim(..next, insert_repeat: count, replace_undo: [], insertion: option.Some(InsertSession(before, state, list.reverse(strokes), False, list.length(strokes))))
        }
        False -> next
      }
      #(
        remember_edit(
          remember_char_search(
            remember_column(vim, next, state, tokens),
            tokens,
          ),
          edit_strokes(vim, state, tokens),
          response,
        ),
        response,
      )
    }
    option.None -> #(
      Vim(..vim, pending: tokens),
      Pending(status(Vim(..vim, pending: tokens))),
    )
  }
}

/// `;` and `,` repeat the most recent `f`, `F`, `t` or `T`.
fn remember_char_search(vim: Vim, tokens: List(String)) -> Vim {
  case list.reverse(tokens) {
    [character, kind, ..] ->
      case kind {
        "f" | "F" | "t" | "T" ->
          Vim(..vim, last_char_search: option.Some(#(kind, character)))
        _ -> vim
      }
    _ -> vim
  }
}

/// `.` repeats the last command that changed the document.
fn remember_edit(vim: Vim, strokes: List(Stroke), response: Response) -> Vim {
  case response {
    Handled(commands) ->
      case strokes != [KeyStroke(".")] && list.any(commands, mutates) {
        True -> Vim(..vim, last_edit: option.Some(strokes))
        False -> vim
      }
    _ -> vim
  }
}

fn mutates(item: EditorCommand) -> Bool {
  case item {
    command.MoveChar(..)
    | command.MoveGroup(..)
    | command.MoveSubword(..)
    | command.MoveLine(..)
    | command.MovePage(..)
    | command.MoveLineBoundary(..)
    | command.MoveLineEdge(..)
    | command.MoveDocBoundary(..)
    | command.MoveParagraph(..)
    | command.MoveToFirstNonWhitespace(..)
    | command.MoveToColumn(..)
    | command.MoveToLineNumber(..)
    | command.MoveToMatchingBracket(..)
    | command.MoveToOffset(..)
    | command.SelectRange(..)
    | command.SelectAll
    | command.SelectLine
    | command.SelectWord
    | command.SelectParagraph
    | command.SimplifySelection
    | command.ScrollCaret(..)
    | command.ScrollLines(..)
    | command.RecenterTopBottom
    | command.CenterSelection
    | command.FindNext
    | command.FindPrevious
    | command.OpenSearchPanel
    | command.CloseSearchPanel
    | command.Noop -> False
    _ -> True
  }
}

/// The upstream `keyToKey` layer, applied before anything else so that later
/// bindings can be written once.
fn key_to_key(vim: Vim, token: String) -> String {
  case token, vim.mode {
    "<Left>", _ -> "h"
    "<Right>", _ -> "l"
    "<Up>", _ -> "k"
    "<Down>", _ -> "j"
    "<Space>", _ -> "l"
    "<BS>", _ -> "h"
    "<Del>", _ -> "x"
    "<C-Space>", _ -> "W"
    "<C-BS>", _ -> "B"
    "<S-Space>", _ -> "w"
    "<S-BS>", _ -> "b"
    "<C-n>", _ -> "j"
    "<C-p>", _ -> "k"
    "<C-[>", _ -> "<Esc>"
    "<C-c>", _ -> "<Esc>"
    "<C-Esc>", _ -> "<Esc>"
    "<Home>", _ -> "0"
    "<End>", _ -> "$"
    "<PageUp>", _ -> "<C-b>"
    "<PageDown>", _ -> "<C-f>"
    other, _ -> other
  }
}

// -- Interpretation ----------------------------------------------------------

fn interpret(
  vim: Vim,
  state: State,
  tokens: List(String),
) -> Option(#(Vim, Response)) {
  case tokens {
    ["\"", name, ..rest] ->
      case rest {
        [] -> option.None
        _ ->
          interpret(
            Vim(..vim, pending_register: option.Some(name)),
            state,
            rest,
          )
      }
    ["\""] -> option.None
    _ -> {
      let #(count, rest) = split_count(tokens)
      dispatch(vim, state, count, rest)
    }
  }
}

fn split_count(tokens: List(String)) -> #(Option(Int), List(String)) {
  split_count_loop(tokens, "")
}

fn split_count_loop(
  tokens: List(String),
  digits: String,
) -> #(Option(Int), List(String)) {
  case tokens {
    [first, ..rest] ->
      case is_count_digit(first, digits) {
        True -> split_count_loop(rest, digits <> first)
        False -> #(parse_count(digits), tokens)
      }
    [] -> #(parse_count(digits), [])
  }
}

fn is_count_digit(token: String, digits: String) -> Bool {
  case token {
    "0" -> digits != ""
    "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" -> True
    _ -> False
  }
}

fn parse_count(digits: String) -> Option(Int) {
  case digits {
    "" -> option.None
    _ ->
      case int.parse(digits) {
        Ok(value) -> option.Some(value)
        Error(_) -> option.None
      }
  }
}

fn repeat_of(count: Option(Int)) -> Int {
  case count {
    option.Some(value) -> value
    option.None -> 1
  }
}

fn done(vim: Vim, commands: List(EditorCommand)) -> Option(#(Vim, Response)) {
  option.Some(#(
    Vim(..vim, pending: [], pending_register: option.None),
    Handled(commands),
  ))
}

fn abandon(vim: Vim) -> Option(#(Vim, Response)) {
  option.Some(#(
    Vim(..vim, pending: [], pending_register: option.None),
    Handled([]),
  ))
}

fn dispatch(
  vim: Vim,
  state: State,
  count: Option(Int),
  tokens: List(String),
) -> Option(#(Vim, Response)) {
  case tokens {
    [] -> option.None
    ["<Esc>"] -> escape(vim)
    _ ->
      case operator_of(tokens) {
        option.Some(#(operator, rest)) ->
          apply_operator(vim, state, operator, count, rest)
        option.None -> action(vim, state, count, tokens)
      }
  }
}

fn escape(vim: Vim) -> Option(#(Vim, Response)) {
  case vim.mode {
    VisualMode(_) ->
      option.Some(#(
        Vim(..vim, mode: NormalMode, pending: []),
        Handled([command.SimplifySelection]),
      ))
    _ -> abandon(vim)
  }
}

// -- Operators ---------------------------------------------------------------

fn operator_of(tokens: List(String)) -> Option(#(String, List(String))) {
  case tokens {
    ["g", "u", ..rest] -> option.Some(#("gu", rest))
    ["g", "U", ..rest] -> option.Some(#("gU", rest))
    ["g", "~", ..rest] -> option.Some(#("g~", rest))
    ["g", "c", ..rest] -> option.Some(#("gc", rest))
    ["g", "q", ..rest] -> option.Some(#("gq", rest))
    ["g", "w", ..rest] -> option.Some(#("gq", rest))
    ["d", ..rest] -> option.Some(#("d", rest))
    ["y", ..rest] -> option.Some(#("y", rest))
    ["c", ..rest] -> option.Some(#("c", rest))
    [">", ..rest] -> option.Some(#(">", rest))
    ["<", ..rest] -> option.Some(#("<", rest))
    ["=", ..rest] -> option.Some(#("=", rest))
    _ -> option.None
  }
}

fn apply_operator(
  vim: Vim,
  state: State,
  operator: String,
  count: Option(Int),
  rest: List(String),
) -> Option(#(Vim, Response)) {
  case vim.mode {
    VisualMode(kind) -> case rest {
      [] -> {
        case kind == BlockWise && { operator == ">" || operator == "<" } {
          True -> shift_block(vim, state, repeat_of(count), operator == ">")
          False -> {
        let #(from, to, linewise) = visual_span(vim, state, kind)
        run_operator(vim, state, operator, from, to, linewise, True)
          }
        }
      }
      _ -> abandon(vim)
    }
    _ -> {
      let #(inner_count, motion_tokens) = split_count(rest)
      let total = repeat_of(count) * repeat_of(inner_count)
      case motion_tokens {
        [] -> option.None
        ["/"] | ["?"] -> option.Some(#(
          Vim(..vim, pending: [], search_operator: option.Some(#(operator, total)), search_count: total),
          Prompt(SearchPrompt(forward: motion_tokens == ["/"])),
        ))
        _ -> apply_operator_motion(vim, state, operator, total, motion_tokens)
      }
    }
  }
}

fn apply_operator_motion(vim: Vim, state: State, operator: String, total: Int, tokens: List(String)) -> Option(#(Vim, Response)) {
  let tokens = case operator, tokens {
    // cw keeps following whitespace, as ce does.
    "c", ["w"] -> ["e"]
    "c", ["W"] -> ["E"]
    _, _ -> tokens
  }
  case doubled(operator, tokens) {
    True -> {
      let first = document.line_index_at(state.doc, cursor(state))
      let last = first + total - 1
      run_operator(vim, state, operator, document.line_start(state.doc, first),
        document.line_end(state.doc, last), True, False)
    }
    False -> case resolve_target(vim, state, tokens, total) {
      TargetNeedMore -> option.None
      TargetFailed -> abandon(vim)
      TargetFailedAt(offset) -> done(vim, [command.MoveToOffset(offset, False)])
      TargetFound(from, to, linewise) -> run_operator(vim, state, operator, from, to, linewise, False)
    }
  }
}

fn doubled(operator: String, tokens: List(String)) -> Bool {
  case tokens {
    [single] ->
      single == operator
      || { operator == "gu" && single == "u" }
      || { operator == "gU" && single == "U" }
      || { operator == "g~" && single == "~" }
      || { operator == "gc" && single == "c" }
      || { operator == "gq" && single == "q" }
    _ -> False
  }
}

fn run_linear_operator(
  vim: Vim,
  state: State,
  operator: String,
  from: Int,
  to: Int,
  linewise: Bool,
  from_visual: Bool,
) -> Option(#(Vim, Response)) {
  let selected = document.slice(state.doc, from, to)
  let vim = case operator {
    "d" | "c" | "y" -> yank_into(vim, selected, linewise, operator)
    _ -> vim
  }
  // A linewise delete takes the line separator with it; a linewise change does
  // not, because `cc` leaves an empty line behind to type into.
  let #(cut_from, cut_to) = case linewise && operator == "d" {
    True -> linewise_cut(state, from, to)
    False -> #(from, to)
  }
  let leave_visual = case from_visual {
    True -> Vim(..vim, mode: NormalMode)
    False -> vim
  }

  case operator {
    "y" ->
      done(leave_visual, [
        command.SelectRange(from: from, to: from),
      ])
    "d" ->
      done(leave_visual, [
        command.SelectRange(from: cut_from, to: cut_to),
        command.DeleteSelection,
        ..case linewise {
          True -> [command.MoveToFirstNonWhitespace(False)]
          False -> [
            command.MoveToOffset(
              delete_caret(state.doc, cut_from, cut_to),
              False,
            ),
          ]
        }
      ])
    "c" ->
      option.Some(#(
        Vim(..leave_visual, mode: InsertMode, pending: []),
        Handled([
          command.SelectRange(from: from, to: to),
          command.DeleteSelection,
        ]),
      ))
    ">" ->
      done(leave_visual, [
        command.SelectRange(from: from, to: to),
        command.IndentMore,
      ])
    "<" ->
      done(leave_visual, [
        command.SelectRange(from: from, to: to),
        command.IndentLess,
      ])
    "=" ->
      done(leave_visual, [
        command.SelectRange(from: from, to: to),
        command.IndentSelection,
      ])
    "gu" ->
      done(leave_visual, [
        command.SelectRange(from: from, to: to),
        command.ChangeCase(to_upper: False),
        command.SelectRange(from: from, to: from),
      ])
    "gU" ->
      done(leave_visual, [
        command.SelectRange(from: from, to: to),
        command.ChangeCase(to_upper: True),
        command.SelectRange(from: from, to: from),
      ])
    "g~" ->
      done(leave_visual, [
        command.SelectRange(from: from, to: to),
        command.InsertText(swap_case(selected)),
        command.SelectRange(from: from, to: from),
      ])
    "gc" ->
      done(leave_visual, [
        command.SelectRange(from: from, to: to),
        command.ToggleComment,
      ])
    "gq" ->
      done(leave_visual, [
        command.SelectRange(from: from, to: to),
        command.IndentSelection,
      ])
    _ -> abandon(vim)
  }
}

/// Widen a linewise range so that deleting it removes the whole line, keeping
/// the surrounding lines joined correctly at both ends of the document.
fn linewise_cut(state: State, from: Int, to: Int) -> #(Int, Int) {
  let first = document.line_index_at(state.doc, from)
  let last = document.line_index_at(state.doc, to)
  case last + 1 < document.line_count(state.doc) {
    True -> #(
      document.line_start(state.doc, first),
      document.line_start(state.doc, last + 1),
    )
    False ->
      case first > 0 {
        True -> #(
          document.line_end(state.doc, first - 1),
          document.length(state.doc),
        )
        False -> #(0, document.length(state.doc))
      }
  }
}

fn swap_case(value: String) -> String {
  value
  |> string.to_graphemes
  |> list.map(fn(grapheme) {
    case grapheme == string.uppercase(grapheme) {
      True -> string.lowercase(grapheme)
      False -> string.uppercase(grapheme)
    }
  })
  |> string.concat
}

fn yank_into(vim: Vim, value: String, linewise: Bool, operator: String) -> Vim {
  write_register(vim, Register(value, linewise, option.None), operator)
}

fn write_register(vim: Vim, register: Register, operator: String) -> Vim {
  let name = option.unwrap(vim.pending_register, "\"")
  case name == "_" || { register.text == "" && !register.linewise && register.block_width == option.None } {
    True -> vim
    False -> {
      let lower = string.lowercase(name)
      let stored = case name != lower, dict.get(vim.registers, lower) {
        True, Ok(previous) -> append_register(previous, register)
        _, _ -> register
      }
      let registers = case operator {
        "y" -> case name == "\"" { True -> dict.insert(vim.registers, "0", register) False -> vim.registers }
        _ -> {
          let numbered = register.linewise || string.contains(register.text, "\n") || numbered_delete(vim.pending)
          let registers = case numbered {
            True -> rotate_deletes(vim.registers) |> dict.insert("1", register)
            False -> vim.registers
          }
          case !register.linewise && !string.contains(register.text, "\n") && name == "\"" {
            True -> dict.insert(registers, "-", register)
            False -> registers
          }
        }
      }
      Vim(..vim, registers: registers |> dict.insert(lower, stored) |> dict.insert("\"", stored))
    }
  }
}

fn append_register(previous: Register, next: Register) -> Register {
  case previous.block_width, next.block_width {
    option.Some(left), option.Some(_) -> Register(previous.text <> "\n" <> next.text,
      False, option.Some(left))
    option.Some(left), option.None if !next.linewise -> {
      Register(previous.text <> "\n" <> next.text, False, option.Some(left))
    }
    _, _ -> {
      let separator = case previous.linewise || next.linewise { True -> "\n" False -> "" }
      Register(previous.text <> separator <> next.text,
        previous.linewise || next.linewise, option.None)
    }
  }
}

fn rotate_deletes(registers: Dict(String, Register)) -> Dict(String, Register) {
  list.fold([#("9", "8"), #("8", "7"), #("7", "6"), #("6", "5"),
    #("5", "4"), #("4", "3"), #("3", "2"), #("2", "1")], registers,
    fn(current, names) {
      case dict.get(registers, names.1) {
        Ok(value) -> dict.insert(current, names.0, value)
        Error(_) -> dict.delete(current, names.0)
      }
    })
}

fn numbered_delete(tokens: List(String)) -> Bool {
  let tokens = case tokens { ["\"", _, ..rest] -> rest _ -> tokens }
  let #(_, tokens) = split_count(tokens)
  case operator_of(tokens) {
    option.Some(#("d", rest)) -> {
      let #(_, motion) = split_count(rest)
      case motion {
        ["%"] | ["("] | [")"] | ["/"] | ["?"] | ["n"] | ["N"] | ["{"] | ["}"] | ["`", _] -> True
        _ -> False
      }
    }
    _ -> False
  }
}

// -- Motions and text objects ------------------------------------------------

type Target {
  TargetNeedMore
  TargetFailed
  TargetFailedAt(Int)
  TargetFound(from: Int, to: Int, linewise: Bool)
}

fn cursor(state: State) -> Int {
  selection.head(state.selection)
}

fn resolve_target(
  vim: Vim,
  state: State,
  tokens: List(String),
  count: Int,
) -> Target {
  case tokens {
    [] -> TargetNeedMore
    ["i", ..rest] -> object_target(state, rest, True, count)
    ["a", ..rest] -> object_target(state, rest, False, count)
    _ ->
      case resolve_motion(vim, state, tokens, count) {
        MotionNeedMore -> TargetNeedMore
        MotionFailed -> TargetFailed
        MotionFound(target, linewise, inclusive) -> {
          let origin = cursor(state)
          let #(from, to) = case target < origin {
            True -> #(target, origin)
            False -> #(origin, target)
          }
          let to = case inclusive && target >= origin {
            True -> movement.next_offset(state.doc, to)
            False -> to
          }
          case linewise {
            True -> {
              let first = document.line_index_at(state.doc, from)
              let last = document.line_index_at(state.doc, to)
              TargetFound(
                document.line_start(state.doc, first),
                document.line_end(state.doc, last),
                True,
              )
            }
            False -> TargetFound(from, to, False)
          }
        }
      }
  }
}

fn object_target(state: State, tokens: List(String), inner: Bool, count: Int) -> Target {
  case tokens {
    [] -> TargetNeedMore
    [name] -> {
      let offset = cursor(state)
      let span = case name {
        "w" -> vim_object.counted_word(state.doc, offset, inner, False, count)
        "W" -> vim_object.counted_word(state.doc, offset, inner, True, count)
        "p" -> vim_object.paragraph(state.doc, offset, inner)
        "s" -> vim_sentence.select(state.doc, offset, inner, count)
        "(" | ")" | "b" ->
          vim_object.brackets(state.doc, offset, "(", ")", inner)
        "[" | "]" -> vim_object.brackets(state.doc, offset, "[", "]", inner)
        "{" | "}" | "B" ->
          vim_object.brackets(state.doc, offset, "{", "}", inner)
        "<" | ">" -> vim_object.brackets(state.doc, offset, "<", ">", inner)
        "t" -> vim_tag.select(state.doc, offset, inner, count)
        "\"" -> vim_object.quotes(state.doc, offset, "\"", inner)
        "'" -> vim_object.quotes(state.doc, offset, "'", inner)
        "`" -> vim_object.quotes(state.doc, offset, "`", inner)
        _ -> option.None
      }
      case span {
        option.Some(#(from, to)) -> TargetFound(from, to, name == "p")
        option.None if count > 1 && { name == "w" || name == "W" } ->
          TargetFailedAt(movement.prev_offset(state.doc, document.length(state.doc)))
        option.None -> TargetFailed
      }
    }
    _ -> TargetFailed
  }
}

type MotionResult {
  MotionNeedMore
  MotionFailed
  MotionFound(target: Int, linewise: Bool, inclusive: Bool)
}

fn resolve_motion(
  vim: Vim,
  state: State,
  tokens: List(String),
  count: Int,
) -> MotionResult {
  let doc = state.doc
  let offset = cursor(state)

  case tokens {
    ["n"] -> search_motion(vim, state, vim.search_forward, count)
    ["N"] -> search_motion(vim, state, !vim.search_forward, count)
    ["h"] ->
      MotionFound(
        int.max(
          movement.line_start(doc, offset),
          repeat(doc, offset, count, movement.prev_offset),
        ),
        False,
        False,
      )
    ["l"] ->
      MotionFound(
        int.min(
          movement.line_end(doc, offset),
          repeat(doc, offset, count, movement.next_offset),
        ),
        False,
        False,
      )
    ["j"] -> vertical(vim, state, count, True)
    ["k"] -> vertical(vim, state, count, False)
    ["w"] -> MotionFound(repeat(doc, offset, count, word_forward), False, False)
    ["W"] ->
      MotionFound(repeat(doc, offset, count, big_word_forward), False, False)
    ["b"] ->
      MotionFound(repeat(doc, offset, count, movement.group_left), False, False)
    ["B"] ->
      MotionFound(repeat(doc, offset, count, big_word_left), False, False)
    ["e"] -> MotionFound(repeat(doc, offset, count, word_end), False, True)
    ["E"] -> MotionFound(repeat(doc, offset, count, big_word_end), False, True)
    ["0"] -> MotionFound(movement.line_start(doc, offset), False, False)
    ["^"] ->
      MotionFound(movement.first_non_whitespace(doc, offset), False, False)
    ["$"] ->
      MotionFound(
        dollar_target(vim, doc, line_end_after(doc, offset, count)),
        False,
        True,
      )
    ["+"] | ["<CR>"] -> first_char_line(state, count)
    ["-"] -> first_char_line(state, -count)
    ["_"] -> first_char_line(state, count - 1)
    ["{"] -> MotionFound(movement.paragraph_backward(doc, offset), False, False)
    ["}"] -> MotionFound(movement.paragraph_forward(doc, offset), False, False)
    ["("] -> MotionFound(movement.paragraph_backward(doc, offset), False, False)
    [")"] -> MotionFound(movement.paragraph_forward(doc, offset), False, False)
    ["|"] ->
      MotionFound(
        movement.offset_at_column(
          doc,
          document.line_index_at(doc, offset),
          count - 1,
        ),
        False,
        False,
      )
    ["G"] ->
      MotionFound(
        goto_line(state, count, !list.any(vim.pending, is_digit)),
        True,
        False,
      )
    ["g"] -> MotionNeedMore
    ["g", "g"] -> MotionFound(goto_line(state, count, False), True, False)
    ["g", "j"] -> vertical(vim, state, count, True)
    ["g", "k"] -> vertical(vim, state, count, False)
    ["g", "0"] | ["g", "^"] ->
      MotionFound(movement.line_start(doc, offset), False, False)
    ["g", "$"] ->
      MotionFound(
        dollar_target(vim, doc, movement.line_end(doc, offset)),
        False,
        True,
      )
    ["g", "e"] ->
      MotionFound(repeat(doc, offset, count, word_end_backward), False, True)
    ["g", "E"] ->
      MotionFound(repeat(doc, offset, count, word_end_backward), False, True)
    ["H"] -> MotionFound(document.line_start(doc, 0), True, False)
    ["M"] ->
      MotionFound(
        document.line_start(doc, document.line_count(doc) / 2),
        True,
        False,
      )
    ["L"] ->
      MotionFound(
        document.line_start(doc, document.line_count(doc) - 1),
        True,
        False,
      )
    ["%"] ->
      case movement.matching_bracket(doc, offset) {
        option.Some(target) -> MotionFound(target, False, True)
        option.None -> MotionFailed
      }
    ["f"] | ["F"] | ["t"] | ["T"] -> MotionNeedMore
    ["f", character] -> char_search(state, "f", character, count)
    ["F", character] -> char_search(state, "F", character, count)
    ["t", character] -> char_search(state, "t", character, count)
    ["T", character] -> char_search(state, "T", character, count)
    [";"] ->
      case vim.last_char_search {
        option.Some(#(kind, character)) ->
          repeat_char_search(state, kind, character, count)
        option.None -> MotionFailed
      }
    [","] ->
      case vim.last_char_search {
        option.Some(#(kind, character)) ->
          repeat_char_search(state, reverse_search(kind), character, count)
        option.None -> MotionFailed
      }
    ["`"] | ["'"] -> MotionNeedMore
    ["`", name] ->
      case dict.get(vim.marks, name) {
        Ok(target) -> MotionFound(target, False, False)
        Error(_) -> MotionFailed
      }
    ["'", name] ->
      case dict.get(vim.marks, name) {
        Ok(target) -> MotionFound(target, True, False)
        Error(_) -> MotionFailed
      }
    _ -> MotionFailed
  }
}

fn reverse_search(kind: String) -> String {
  case kind {
    "f" -> "F"
    "F" -> "f"
    "t" -> "T"
    _ -> "t"
  }
}

fn repeat(
  doc: document.Document,
  offset: Int,
  count: Int,
  step: fn(document.Document, Int) -> Int,
) -> Int {
  case count <= 0 {
    True -> offset
    False -> repeat(doc, step(doc, offset), count - 1, step)
  }
}

/// Vim's `w`: leave the current run, then skip the whitespace after it, so the
/// caret lands on the first character of the next word.
fn word_forward(doc: document.Document, offset: Int) -> Int {
  skip_space(doc, movement.group_right(doc, offset), True)
}

fn big_word_forward(doc: document.Document, offset: Int) -> Int {
  skip_space(doc, big_word_right(doc, offset), True)
}

fn big_word_right(doc: document.Document, offset: Int) -> Int {
  skip_non_space(doc, skip_space(doc, offset, True), True)
}

fn big_word_left(doc: document.Document, offset: Int) -> Int {
  skip_non_space(doc, skip_space(doc, offset, False), False)
}

fn skip_space(doc: document.Document, offset: Int, forward: Bool) -> Int {
  let at = case forward {
    True -> movement.grapheme_after(doc, offset)
    False -> movement.grapheme_before(doc, offset)
  }
  case at != "" && text.classify(at) == text.Whitespace {
    True ->
      skip_space(
        doc,
        case forward {
          True -> movement.next_offset(doc, offset)
          False -> movement.prev_offset(doc, offset)
        },
        forward,
      )
    False -> offset
  }
}

fn skip_non_space(doc: document.Document, offset: Int, forward: Bool) -> Int {
  let at = case forward {
    True -> movement.grapheme_after(doc, offset)
    False -> movement.grapheme_before(doc, offset)
  }
  case at != "" && text.classify(at) != text.Whitespace {
    True ->
      skip_non_space(
        doc,
        case forward {
          True -> movement.next_offset(doc, offset)
          False -> movement.prev_offset(doc, offset)
        },
        forward,
      )
    False -> offset
  }
}

fn word_end(doc: document.Document, offset: Int) -> Int {
  let start = movement.next_offset(doc, offset)
  movement.prev_offset(doc, movement.group_right(doc, start))
}

fn big_word_end(doc: document.Document, offset: Int) -> Int {
  let start = movement.next_offset(doc, offset)
  movement.prev_offset(doc, big_word_right(doc, start))
}

fn word_end_backward(doc: document.Document, offset: Int) -> Int {
  let start = movement.group_left(doc, offset)
  movement.prev_offset(doc, start)
}

fn vertical(vim: Vim, state: State, count: Int, forward: Bool) -> MotionResult {
  let delta = case forward {
    True -> count
    False -> -count
  }
  let line =
    document.clamp(
      document.line_index_at(state.doc, cursor(state)) + delta,
      0,
      document.line_count(state.doc) - 1,
    )
  let column = case vim.goal_column {
    option.Some(column) -> column
    option.None -> current_column(vim, state)
  }
  let target = case vim.goal_line_end, vim.mode {
    True, _ -> document.line_end(state.doc, line)
    False, VisualMode(BlockWise) -> vim_block.offset_at_column(state.doc, line, column)
    False, _ -> movement.offset_at_column(state.doc, line, column)
  }
  MotionFound(target, True, False)
}

fn current_column(vim: Vim, state: State) -> Int {
  case vim.mode {
    VisualMode(BlockWise) -> vim_block.column(state.doc, cursor(state))
    _ -> movement.column_at(state.doc, cursor(state))
  }
}

fn remember_column(
  previous: Vim,
  next: Vim,
  state: State,
  tokens: List(String),
) -> Vim {
  let #(_, rest) = split_count(tokens)
  case rest {
    ["j"] | ["k"] | ["g", "j"] | ["g", "k"] -> {
      let column = case previous.goal_column {
        option.Some(column) -> column
        option.None -> current_column(previous, state)
      }
      Vim(..next, goal_column: option.Some(column), goal_line_end: previous.goal_line_end)
    }
    ["$"] -> Vim(..next, goal_column: option.None, goal_line_end: True)
    ["O"] -> next
    _ -> Vim(..next, goal_column: option.None, goal_line_end: False)
  }
}

fn first_char_line(state: State, lines: Int) -> MotionResult {
  let index =
    document.line_index_at(state.doc, cursor(state))
    |> fn(current) { current + lines }
  let clamped = document.clamp(index, 0, document.line_count(state.doc) - 1)
  MotionFound(
    movement.first_non_whitespace(
      state.doc,
      document.line_start(state.doc, clamped),
    ),
    True,
    False,
  )
}

fn line_end_after(doc: document.Document, offset: Int, count: Int) -> Int {
  let index = document.line_index_at(doc, offset) + count - 1
  document.line_end(doc, document.clamp(index, 0, document.line_count(doc) - 1))
}

fn goto_line(state: State, count: Int, default_last: Bool) -> Int {
  let index = case count > 1 || !default_last {
    True -> count - 1
    False -> document.line_count(state.doc) - 1
  }
  let clamped = document.clamp(index, 0, document.line_count(state.doc) - 1)
  movement.first_non_whitespace(
    state.doc,
    document.line_start(state.doc, clamped),
  )
}

fn char_search(
  state: State,
  kind: String,
  character: String,
  count: Int,
) -> MotionResult {
  let doc = state.doc
  let index = document.line_index_at(doc, cursor(state))
  let start = document.line_start(doc, index)
  let line = document.line_text(doc, index)
  let column = cursor(state) - start
  let forward = kind == "f" || kind == "t"
  case find_in_line(line, character, column, forward, count) {
    option.None -> MotionFailed
    option.Some(found) -> {
      let target = case kind {
        "t" -> text.prev_boundary(line, found)
        "T" -> text.next_boundary(line, found)
        _ -> found
      }
      MotionFound(start + target, False, forward)
    }
  }
}

fn find_in_line(
  line: String,
  character: String,
  from: Int,
  forward: Bool,
  count: Int,
) -> Option(Int) {
  let positions =
    text.boundaries(line)
    |> list.filter(fn(offset) { text.grapheme_at(line, offset) == character })
    |> list.filter(fn(offset) {
      case forward {
        True -> offset > from
        False -> offset < from
      }
    })
  let ordered = case forward {
    True -> positions
    False -> list.reverse(positions)
  }
  ordered
  |> list.drop(count - 1)
  |> list.first
  |> option.from_result
}

// -- Actions -----------------------------------------------------------------

fn action(
  vim: Vim,
  state: State,
  count: Option(Int),
  tokens: List(String),
) -> Option(#(Vim, Response)) {
  case vim.mode, tokens {
    VisualMode(CharacterWise), ["D"] | VisualMode(LineWise), ["D"]
    | VisualMode(CharacterWise), ["X"] | VisualMode(LineWise), ["X"] ->
      visual_line_operator(vim, state, "d")
    VisualMode(CharacterWise), ["C"] | VisualMode(LineWise), ["C"]
    | VisualMode(CharacterWise), ["S"] | VisualMode(LineWise), ["S"]
    | VisualMode(CharacterWise), ["R"] | VisualMode(LineWise), ["R"] ->
      visual_line_operator(vim, state, "c")
    VisualMode(CharacterWise), ["Y"] | VisualMode(LineWise), ["Y"] ->
      visual_line_operator(vim, state, "y")
    VisualMode(BlockWise), ["X"] -> run_block_operator(vim, state, "d")
    VisualMode(BlockWise), ["Y"] -> run_block_operator(vim, state, "y")
    VisualMode(BlockWise), ["S"] | VisualMode(BlockWise), ["R"] ->
      visual_line_operator(vim, state, "c")
    VisualMode(BlockWise), ["D"] -> run_block_operator_extent(vim, state, "d", True)
    VisualMode(BlockWise), ["C"] -> begin_block_insert_extent(vim, state, False, True, True)
    _, _ -> normal_action(vim, state, count, tokens)
  }
}

fn visual_line_operator(vim: Vim, state: State, operator: String) -> Option(#(Vim, Response)) {
  let #(from, to, _) = visual_span(vim, state, LineWise)
  run_linear_operator(vim, state, operator, from, to, True, True)
}

fn normal_action(vim: Vim, state: State, count: Option(Int), tokens: List(String)) -> Option(#(Vim, Response)) {
  let total = repeat_of(count)
  let offset = cursor(state)

  case tokens {
    ["i"] ->
      case vim.mode {
        VisualMode(_) -> option.None
        _ -> enter_insert(vim, [])
      }
    ["a"] ->
      case vim.mode {
        VisualMode(_) -> option.None
        _ -> enter_insert(vim, [command.MoveChar(forward: True, extend: False)])
      }
    ["i", name] -> select_object(vim, state, name, True, total)
    ["a", name] -> select_object(vim, state, name, False, total)
    ["I"] -> case vim.mode { VisualMode(BlockWise) -> begin_block_insert(vim, state, False, False) _ -> enter_insert(vim, [command.MoveToFirstNonWhitespace(False)]) }
    ["A"] -> case vim.mode { VisualMode(BlockWise) -> begin_block_insert(vim, state, True, False) _ -> enter_insert(vim, [command.MoveLineBoundary(True, False)]) }
    ["g"] -> option.None
    ["g", "I"] -> enter_insert(vim, [command.MoveLineEdge(False, False)])
    ["g", "i"] -> enter_insert(vim, [])
    ["g", "v"] ->
      case vim.last_visual {
        option.None -> abandon(vim)
        option.Some(#(kind, anchor, head)) -> {
          let previous = case vim.mode {
            VisualMode(current) ->
              option.Some(#(current, vim.visual_anchor, offset))
            _ -> vim.last_visual
          }
          option.Some(#(
            Vim(
              ..vim,
              mode: VisualMode(kind),
              pending: [],
              visual_anchor: anchor,
              last_visual: previous,
            ),
            Handled([command.SelectRange(from: anchor, to: head)]),
          ))
        }
      }
    ["g", "J"] -> done(vim, [command.JoinLines(keep_spaces: True)])
    ["o"] ->
      case vim.mode {
        VisualMode(_) ->
          option.Some(#(
            Vim(..vim, pending: [], visual_anchor: offset),
            Handled([command.SelectRange(from: offset, to: vim.visual_anchor)]),
          ))
        _ ->
          enter_insert(vim, [
            command.MoveLineBoundary(True, False),
            command.InsertNewlineAndIndent,
          ])
      }
    ["O"] -> case vim.mode {
      VisualMode(_) -> exchange_visual_corner(vim, state)
      _ -> enter_insert(vim, [
        command.MoveLineEdge(False, False),
        command.InsertText("\n"),
        command.MoveChar(forward: False, extend: False),
      ])
    }
    ["v"] -> toggle_visual(vim, state, CharacterWise)
    ["V"] -> toggle_visual(vim, state, LineWise)
    ["<C-v>"] | ["<C-q>"] -> toggle_visual(vim, state, BlockWise)
    ["x"] ->
      case vim.mode {
        VisualMode(kind) -> {
          let #(from, to, linewise) = visual_span(vim, state, kind)
          run_operator(vim, state, "d", from, to, linewise, True)
        }
        _ -> delete_chars(vim, state, total, True)
      }
    ["X"] -> delete_chars(vim, state, total, False)
    ["D"] -> operator_to_line_end(vim, state, "d", total)
    ["C"] -> operator_to_line_end(vim, state, "c", total)
    ["Y"] -> {
      let first = document.line_index_at(state.doc, offset)
      let last = first + total - 1
      run_operator(
        vim,
        state,
        "y",
        document.line_start(state.doc, first),
        document.line_end(state.doc, last),
        True,
        False,
      )
    }
    ["s"] ->
      case vim.mode {
        VisualMode(kind) -> {
          let #(from, to, linewise) = visual_span(vim, state, kind)
          run_operator(vim, state, "c", from, to, linewise, True)
        }
        _ -> {
          let to = int.min(repeat(state.doc, offset, total, movement.next_offset), movement.line_end(state.doc, offset))
          run_operator(vim, state, "c", offset, to, False, False)
        }
      }
    ["S"] -> {
      let index = document.line_index_at(state.doc, offset)
      run_operator(
        vim,
        state,
        "c",
        document.line_start(state.doc, index),
        document.line_end(state.doc, int.min(index + total - 1, document.line_count(state.doc) - 1)),
        True,
        False,
      )
    }
    ["J"] -> done(vim, [command.JoinLines(keep_spaces: False)])
    ["p"] -> paste(vim, state, True, total)
    ["P"] -> paste(vim, state, False, total)
    ["u"] ->
      case vim.mode {
        VisualMode(kind) -> {
          let #(from, to, linewise) = visual_span(vim, state, kind)
          run_operator(vim, state, "gu", from, to, linewise, True)
        }
        _ -> done(vim, repeat_commands(command.Undo, total))
      }
    ["U"] ->
      case vim.mode {
        VisualMode(kind) -> {
          let #(from, to, linewise) = visual_span(vim, state, kind)
          run_operator(vim, state, "gU", from, to, linewise, True)
        }
        _ -> abandon(vim)
      }
    ["<C-r>"] -> done(vim, repeat_commands(command.Redo, total))
    ["<C-a>"] -> increment(vim, state, total)
    ["<C-x>"] -> increment(vim, state, -total)
    ["<C-e>"] -> done(vim, [command.ScrollLines(forward: True)])
    ["<C-y>"] -> done(vim, [command.ScrollLines(forward: False)])
    ["<C-f>"] -> done(vim, [command.MovePage(True, in_visual(vim))])
    ["<C-b>"] -> done(vim, [command.MovePage(False, in_visual(vim))])
    ["<C-d>"] -> done(vim, [command.MovePage(True, in_visual(vim))])
    ["<C-u>"] -> done(vim, [command.MovePage(False, in_visual(vim))])
    ["<C-w>"] -> abandon(vim)
    ["~"] ->
      case vim.mode {
        VisualMode(kind) -> {
          let #(from, to, linewise) = visual_span(vim, state, kind)
          run_operator(vim, state, "g~", from, to, linewise, True)
        }
        _ -> {
          let to = movement.next_offset(state.doc, offset)
          let selected = document.slice(state.doc, offset, to)
          done(vim, [
            command.SelectRange(from: offset, to: to),
            command.InsertText(swap_case(selected)),
          ])
        }
      }
    ["r"] -> option.None
    ["r", character] -> replace_characters(vim, state, character, total)
    ["R"] ->
      option.Some(#(Vim(..vim, mode: ReplaceMode, pending: []), Handled([])))
    ["m"] -> option.None
    ["m", name] ->
      option.Some(#(
        Vim(..vim, marks: dict.insert(vim.marks, name, offset), pending: []),
        Handled([]),
      ))
    ["q"] ->
      case vim.recording {
        option.Some(#(register, recorded)) ->
          option.Some(#(
            Vim(
              ..vim,
              recording: option.None,
              pending: [],
              macros: dict.insert(
                vim.macros,
                register,
                trim_recording(recorded),
              ),
            ),
            Handled([]),
          ))
        option.None -> option.None
      }
    ["q", name] ->
      option.Some(#(
        Vim(..vim, recording: option.Some(#(name, [])), pending: []),
        Handled([]),
      ))
    ["@"] -> option.None
    ["@", name] ->
      case dict.get(vim.macros, name) {
        Ok(recorded) ->
          option.Some(#(
            Vim(..vim, pending: []),
            Replay(repeat_tokens(recorded, total)),
          ))
        Error(_) -> abandon(vim)
      }
    ["z"] -> option.None
    ["z", "z"] | ["z", "."] ->
      done(vim, [command.ScrollCaret(command.ScrollCenter)])
    ["z", "t"] | ["z", "<CR>"] ->
      done(vim, [command.ScrollCaret(command.ScrollTop)])
    ["z", "b"] | ["z", "-"] ->
      done(vim, [command.ScrollCaret(command.ScrollBottom)])
    ["n"] -> search_move(vim, state, vim.search_forward, total)
    ["N"] -> search_move(vim, state, !vim.search_forward, total)
    ["*"] ->
      search_word(vim, state, True, True, total)
    ["#"] ->
      search_word(vim, state, False, True, total)
    ["g", "*"] ->
      search_word(vim, state, True, False, total)
    ["g", "#"] ->
      search_word(vim, state, False, False, total)
    ["/"] ->
      option.Some(#(
        Vim(..vim, pending: [], search_count: total),
        Prompt(SearchPrompt(forward: True)),
      ))
    ["?"] ->
      option.Some(#(
        Vim(..vim, pending: [], search_count: total),
        Prompt(SearchPrompt(forward: False)),
      ))
    [":"] -> option.Some(#(Vim(..vim, pending: []), Prompt(ExPrompt)))
    ["."] ->
      case vim.last_edit {
        option.Some(recorded) ->
          option.Some(#(Vim(..vim, pending: []), Replay(recorded)))
        option.None -> abandon(vim)
      }
    _ ->
      case resolve_motion(vim, state, tokens, total) {
        MotionNeedMore -> option.None
        MotionFailed -> abandon(vim)
        MotionFound(target, _, _) -> {
          let target = case in_visual(vim) {
            True -> target
            False -> normal_offset(state.doc, target)
          }
          done(vim, [command.MoveToOffset(target, in_visual(vim))])
        }
      }
  }
}

fn repeat_tokens(tokens: List(Stroke), count: Int) -> List(Stroke) {
  case count <= 1 {
    True -> tokens
    False -> list.append(tokens, repeat_tokens(tokens, count - 1))
  }
}

/// `<C-a>` and `<C-x>`: change the number at or after the caret.
fn increment(vim: Vim, state: State, delta: Int) -> Option(#(Vim, Response)) {
  let offset = cursor(state)
  let index = document.line_index_at(state.doc, offset)
  let start = document.line_start(state.doc, index)
  let line = document.line_text(state.doc, index)
  case number_span(line, offset - start) {
    option.None -> abandon(vim)
    option.Some(#(from, to)) -> {
      let digits = text.slice(line, from, to)
      case int.parse(digits) {
        Error(_) -> abandon(vim)
        Ok(value) ->
          done(vim, [
            command.SelectRange(from: start + from, to: start + to),
            command.InsertText(int.to_string(value + delta)),
            command.MoveChar(forward: False, extend: False),
          ])
      }
    }
  }
}

fn number_span(line: String, column: Int) -> Option(#(Int, Int)) {
  let digits =
    text.boundaries(line)
    |> list.filter(fn(offset) { is_digit(text.grapheme_at(line, offset)) })
  case list.filter(digits, fn(offset) { offset >= column }) {
    [] -> option.None
    [first, ..] -> {
      let from = extend_back(line, first)
      let to = extend_forward(line, first)
      option.Some(#(from, to))
    }
  }
}

fn extend_back(line: String, offset: Int) -> Int {
  case offset <= 0 {
    True -> 0
    False -> {
      let previous = text.prev_boundary(line, offset)
      case is_digit(text.grapheme_at(line, previous)) {
        True -> extend_back(line, previous)
        False -> offset
      }
    }
  }
}

fn extend_forward(line: String, offset: Int) -> Int {
  case is_digit(text.grapheme_at(line, offset)) {
    True -> extend_forward(line, text.next_boundary(line, offset))
    False -> offset
  }
}

fn is_digit(grapheme: String) -> Bool {
  case grapheme {
    "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" -> True
    _ -> False
  }
}

fn trim_recording(recorded: List(Stroke)) -> List(Stroke) {
  recorded
  |> list.drop(1)
  |> list.reverse
}

fn in_visual(vim: Vim) -> Bool {
  case vim.mode {
    VisualMode(_) -> True
    _ -> False
  }
}

fn visual_kind(vim: Vim) -> VisualKind {
  case vim.mode {
    VisualMode(kind) -> kind
    _ -> CharacterWise
  }
}

fn repeat_commands(item: EditorCommand, count: Int) -> List(EditorCommand) {
  case count <= 1 {
    True -> [item]
    False -> [item, ..repeat_commands(item, count - 1)]
  }
}

fn enter_insert(
  vim: Vim,
  commands: List(EditorCommand),
) -> Option(#(Vim, Response)) {
  option.Some(#(Vim(..vim, mode: InsertMode, pending: []), Handled(commands)))
}

fn toggle_visual(
  vim: Vim,
  state: State,
  kind: VisualKind,
) -> Option(#(Vim, Response)) {
  case vim.mode {
    VisualMode(current) if current == kind ->
      option.Some(#(
        Vim(..vim, mode: NormalMode, pending: []),
        Handled([command.SimplifySelection]),
      ))
    VisualMode(_) ->
      option.Some(#(
        Vim(..vim, mode: VisualMode(kind), pending: []),
        Handled([]),
      ))
    _ ->
      option.Some(#(
        Vim(
          ..vim,
          mode: VisualMode(kind),
          pending: [],
          visual_anchor: cursor(state),
        ),
        Handled([]),
      ))
  }
}

fn visual_span(vim: Vim, state: State, kind: VisualKind) -> #(Int, Int, Bool) {
  let head = cursor(state)
  let anchor = vim.visual_anchor
  let #(from, to) = case anchor <= head {
    True -> #(anchor, movement.next_offset(state.doc, head))
    False -> #(head, movement.next_offset(state.doc, anchor))
  }
  case kind {
    LineWise -> {
      let first = document.line_index_at(state.doc, from)
      // The inclusive endpoint may be an empty line; advancing it would
      // incorrectly include the following line.
      let last = document.line_index_at(state.doc, int.max(anchor, head))
      #(
        document.line_start(state.doc, first),
        document.line_end(state.doc, last),
        True,
      )
    }
    _ -> #(from, to, False)
  }
}

fn delete_chars(
  vim: Vim,
  state: State,
  count: Int,
  forward: Bool,
) -> Option(#(Vim, Response)) {
  let offset = cursor(state)
  let target = case forward {
    True -> int.min(movement.line_end(state.doc, offset),
      repeat(state.doc, offset, count, movement.next_offset))
    False -> int.max(movement.line_start(state.doc, offset),
      repeat(state.doc, offset, count, movement.prev_offset))
  }
  let #(from, to) = case forward {
    True -> #(offset, target)
    False -> #(target, offset)
  }
  case from == to {
    True -> abandon(vim)
    False -> run_operator(vim, state, "d", from, to, False, in_visual(vim))
  }
}

fn operator_to_line_end(
  vim: Vim,
  state: State,
  operator: String,
  count: Int,
) -> Option(#(Vim, Response)) {
  let offset = cursor(state)
  case vim.mode {
    VisualMode(CharacterWise) | VisualMode(LineWise) -> {
      let #(from, to, _) = visual_span(vim, state, LineWise)
      run_linear_operator(vim, state, operator, from, to, True, True)
    }
    _ -> run_operator(
      vim, state, operator, offset,
      document.line_end(state.doc, int.min(document.line_index_at(state.doc, offset) + count - 1, document.line_count(state.doc) - 1)), False, False,
    )
  }
}

fn exchange_visual_corner(vim: Vim, state: State) -> Option(#(Vim, Response)) {
  let head = cursor(state)
  case vim.mode {
    VisualMode(BlockWise) -> {
      let anchor_column = vim_block.column(state.doc, vim.visual_anchor)
      let head_column = case vim.goal_column {
        option.Some(column) -> column
        option.None -> vim_block.column(state.doc, head)
      }
      let anchor = vim_block.offset_at_column(state.doc,
        document.line_index_at(state.doc, vim.visual_anchor), head_column)
      let target = vim_block.offset_at_column(state.doc,
        document.line_index_at(state.doc, head), anchor_column)
      option.Some(#(Vim(..vim, pending: [], visual_anchor: anchor,
        goal_column: option.Some(anchor_column)),
        Handled([command.SelectRange(from: anchor, to: target)])))
    }
    _ -> option.Some(#(Vim(..vim, pending: [], visual_anchor: head),
      Handled([command.SelectRange(from: head, to: vim.visual_anchor)])))
  }
}

fn paste_linear(
  vim: Vim,
  state: State,
  after: Bool,
  count: Int,
) -> Option(#(Vim, Response)) {
  let name = case vim.pending_register {
    option.Some(register) -> register
    option.None -> "\""
  }
  case dict.get(vim.registers, string.lowercase(name)) {
    Error(_) -> abandon(vim)
    Ok(register) -> {
      let value = case register.linewise {
        True -> string.repeat(register.text <> "\n", count - 1) <> register.text
        False -> string.repeat(register.text, count)
      }
      let register = Register(..register, text: value)
      let offset = cursor(state)
      case in_visual(vim), register.linewise {
        True, True if vim.mode == VisualMode(LineWise) -> {
          let #(from, to, _) = visual_span(vim, state, LineWise)
          let vim = case after {
            True -> yank_into(Vim(..vim, pending_register: option.None), document.slice(state.doc, from, to), True, "d")
            False -> vim
          }
          done(Vim(..vim, mode: NormalMode), [
            command.EditRanges([transaction.Change(from, to, register.text)], from),
            command.MoveToFirstNonWhitespace(False),
          ])
        }
        True, False -> visual_paste(vim, state, register, after)
        _, True -> {
          let index = document.line_index_at(state.doc, offset)
          let at = case after {
            True -> document.line_end(state.doc, index)
            False -> document.line_start(state.doc, index)
          }
          let payload = case after {
            True -> "\n" <> register.text
            False -> register.text <> "\n"
          }
          done(vim, [
            command.EditRanges([transaction.Change(at, at, payload)],
              case after {
                True -> at + 1
                False -> at
              },
            ),
            command.MoveToFirstNonWhitespace(False),
          ])
        }
        False, False -> {
          let at = case after {
            True -> int.min(movement.next_offset(state.doc, offset),
              movement.line_end(state.doc, offset))
            False -> offset
          }
          done(vim, [
            command.EditRanges([transaction.Change(at, at, register.text)],
              case string.contains(register.text, "\n") {
                True -> at
                False -> at + text.prev_boundary(register.text, text.width(register.text))
              },
            ),
          ])
        }
      }
    }
  }
}

/// Vim's `:` commands, parsed from the Ex prompt.
pub fn ex_command(
  vim: Vim,
  state: State,
  input: String,
) -> #(Vim, List(EditorCommand)) {
  let current = document.line_index_at(state.doc, cursor(state))
  let #(anchor, head) = case vim.mode {
    VisualMode(_) -> #(vim.visual_anchor, cursor(state))
    _ -> case vim.last_visual {
      option.Some(#(_, anchor, head)) -> #(anchor, head)
      option.None -> #(cursor(state), cursor(state))
    }
  }
  let visual = #(document.line_index_at(state.doc, int.min(anchor, head)), document.line_index_at(state.doc, int.max(anchor, head)))
  case vim_ex.parse(input, current, document.line_count(state.doc) - 1, visual) {
    option.None -> #(vim, [])
    option.Some(range) -> {
      let range = case !range.explicit && in_visual(vim) {
        True -> vim_ex.Addressed(..range, first: visual.0, last: visual.1)
        False -> range
      }
      let vim = case vim.mode {
        VisualMode(kind) -> Vim(..vim, mode: NormalMode, last_visual: option.Some(#(kind, anchor, head)))
        _ -> vim
      }
      case range.body {
        "d" | "delete" | "y" | "yank" -> {
          let operator = case string.starts_with(range.body, "d") { True -> "d" False -> "y" }
          case run_linear_operator(vim, state, operator, document.line_start(state.doc, range.first), document.line_end(state.doc, range.last), True, False) {
            option.Some(#(next, Handled(commands))) -> #(next, case operator {
              "y" -> list.append(commands, [command.MoveToOffset(cursor(state), False)])
              _ -> commands
            })
            _ -> #(vim, [])
          }
        }
        "" if range.explicit -> #(vim, [command.MoveToLineNumber(range.last + 1, False), command.MoveToFirstNonWhitespace(False)])
        _ -> case vim_ex.is_substitute(range.body) {
          True -> case vim_ex.substitute(state.doc, range, vim.search_query) {
            option.Some(#(query, commands)) -> #(Vim(..vim, search_query: query, last_search: option.Some(query.search)), commands)
            option.None -> #(vim, [])
          }
          False -> ex_simple(vim, state, range.body)
        }
      }
    }
  }
}

fn ex_simple(vim: Vim, state: State, input: String) -> #(Vim, List(EditorCommand)) {
  let trimmed = string.trim(input)
  case trimmed {
    "w" | "write" | "w!" | "wq" | "x" -> #(vim, [command.SaveSnippet])
    "u" | "undo" -> #(vim, [command.Undo])
    "red" | "redo" -> #(vim, [command.Redo])
    "noh" | "nohl" | "nohlsearch" -> #(vim, [command.CloseSearchPanel])
    "d" | "delete" -> #(vim, [command.DeleteLine])
    "y" | "yank" -> #(vim, [command.Copy])
    "pu" | "put" -> #(vim, paste_commands(vim, state))
    "j" | "join" -> #(vim, [command.JoinLines(keep_spaces: False)])
    "sor" | "sort" -> #(vim, [command.SortLines])
    "delm" | "delmarks" -> #(Vim(..vim, marks: dict.new()), [command.ClearMarks])
    "start" | "startinsert" -> #(Vim(..vim, mode: InsertMode), [])
    _ ->
      case int.parse(trimmed) {
        Ok(line) -> #(vim, [
          command.MoveToLineNumber(line: line, extend: False),
        ])
        Error(_) -> ex_substitute(vim, state, trimmed)
      }
  }
}

fn paste_commands(vim: Vim, state: State) -> List(EditorCommand) {
  case paste(vim, state, True, 1) {
    option.Some(#(_, Handled(commands))) -> commands
    _ -> []
  }
}

/// `:s/pattern/replacement/[g]`, and the `:g`/`:v` line filters that share its
/// shape.
fn ex_substitute(
  vim: Vim,
  _state: State,
  input: String,
) -> #(Vim, List(EditorCommand)) {
  case string.split(input, "/") {
    ["s", pattern, replacement, ..flags]
    | ["substitute", pattern, replacement, ..flags]
    | ["%s", pattern, replacement, ..flags] -> {
      let all = case flags {
        [found, ..] -> string.contains(found, "g")
        [] -> False
      }
      #(vim, [
        command.Substitute(pattern: pattern, replacement: replacement, all: all),
      ])
    }
    ["g", pattern, ..] | ["global", pattern, ..] -> #(vim, [
      command.SetSearchQuery(pattern: pattern, whole_word: False, regexp: True),
      command.SelectSelectionMatches,
    ])
    ["v", pattern, ..] | ["vglobal", pattern, ..] -> #(vim, [
      command.SetSearchQuery(pattern: pattern, whole_word: False, regexp: True),
    ])
    _ -> #(vim, [])
  }
}

// -- Key tokens --------------------------------------------------------------

fn token_of(key: Key) -> String {
  let name = case key.key {
    "Escape" -> "<Esc>"
    "Enter" -> "<CR>"
    "Backspace" -> "<BS>"
    "Delete" -> "<Del>"
    "Tab" -> "<Tab>"
    "ArrowLeft" -> "<Left>"
    "ArrowRight" -> "<Right>"
    "ArrowUp" -> "<Up>"
    "ArrowDown" -> "<Down>"
    "Home" -> "<Home>"
    "End" -> "<End>"
    "PageUp" -> "<PageUp>"
    "PageDown" -> "<PageDown>"
    "Insert" -> "<Ins>"
    " " -> "<Space>"
    other -> other
  }

  case key.ctrl, string.starts_with(name, "<") {
    True, True -> "<C-" <> string.drop_start(name, 1)
    True, False -> "<C-" <> string.lowercase(name) <> ">"
    False, _ -> name
  }
}

// Vim's normal cursor occupies a character, never the gap after a nonempty line.
fn normal_offset(doc: document.Document, offset: Int) -> Int {
  let start = movement.line_start(doc, offset)
  let end = movement.line_end(doc, offset)
  case end > start && offset >= end {
    True -> movement.prev_offset(doc, end)
    False -> offset
  }
}

fn dollar_target(vim: Vim, doc: document.Document, end: Int) -> Int {
  case in_visual(vim) {
    True -> end
    False -> normal_offset(doc, end)
  }
}

fn repeat_char_search(
  state: State,
  kind: String,
  character: String,
  count: Int,
) -> MotionResult {
  // Repeating a till-search must skip the adjacent character that the previous
  // search stopped short of, rather than finding it again without moving.
  let offset = cursor(state)
  case char_search(state, kind, character, count) {
    MotionFound(target, _, _)
      if target == offset && { kind == "t" || kind == "T" }
    -> char_search(state, kind, character, count + 1)
    result -> result
  }
}

fn select_object(
  vim: Vim,
  state: State,
  name: String,
  inner: Bool,
  count: Int,
) -> Option(#(Vim, Response)) {
  case in_visual(vim) {
    False -> abandon(vim)
    True ->
      case visual_object_target(vim, state, name, inner, count) {
        TargetFailedAt(offset) -> done(vim, [command.SelectRange(from: vim.visual_anchor, to: offset)])
        TargetFound(from, to, linewise) -> {
          let kind = case linewise {
            True -> LineWise
            False -> CharacterWise
          }
          let backward = vim.visual_anchor > cursor(state)
          let replace_selection = name == "t" || vim.visual_anchor == cursor(state)
          let #(anchor, head) = case backward, replace_selection {
            True, True -> #(int.max(from, movement.prev_offset(state.doc, to)), from)
            True, False -> #(int.max(vim.visual_anchor, movement.prev_offset(state.doc, to)), from)
            False, True -> #(from, int.max(from, movement.prev_offset(state.doc, to)))
            False, False -> #(int.min(vim.visual_anchor, from), int.max(from, movement.prev_offset(state.doc, to)))
          }
          option.Some(#(
            Vim(..vim, mode: VisualMode(kind), visual_anchor: anchor, pending: []),
            Handled([command.SelectRange(from: anchor, to: head)]),
          ))
        }
        _ -> abandon(vim)
      }
  }
}

fn visual_object_target(vim: Vim, state: State, name: String, inner: Bool, count: Int) -> Target {
  case name == "s" && vim.visual_anchor != cursor(state) {
    True -> case vim_sentence.expand(state.doc, vim.visual_anchor, cursor(state), inner, count) {
      option.Some(#(from, to)) -> TargetFound(from, to, False)
      option.None -> TargetFailed
    }
    False -> visual_other_object_target(vim, state, name, inner, count)
  }
}

fn visual_other_object_target(vim: Vim, state: State, name: String, inner: Bool, count: Int) -> Target {
  case name == "t" && vim.visual_anchor != cursor(state) {
    True -> case vim_tag.expand(state.doc, vim.visual_anchor, cursor(state), inner, count) {
      option.Some(#(from, to)) -> TargetFound(from, to, False)
      option.None -> TargetFailed
    }
    False -> visual_non_tag_target(vim, state, name, inner, count)
  }
}

fn visual_non_tag_target(vim: Vim, state: State, name: String, inner: Bool, count: Int) -> Target {
  let target = object_target(state, [name], inner, count)
  case target {
    TargetFound(from, to, _) if name == "w" || name == "W" -> {
      let head = cursor(state)
      let shifted = case vim.visual_anchor < head && { !inner || movement.next_offset(state.doc, head) >= to },
        vim.visual_anchor > head && head <= from {
        True, _ -> movement.next_offset(state.doc, head)
        _, True -> movement.prev_offset(state.doc, head)
        _, _ -> head
      }
      case vim.visual_anchor > head && inner {
        True -> case vim_object.inner_words_backward(state.doc, shifted, name == "W", count) {
          option.Some(#(from, to)) -> TargetFound(from, to, False)
          option.None -> TargetFailed
        }
        False -> case shifted == head {
        True -> target
        False -> object_target(state.State(..state, selection: selection.from(shifted)), [name], inner, count)
        }
      }
    }
    _ -> target
  }
}

fn replace_linear_characters(
  vim: Vim,
  state: State,
  character: String,
  count: Int,
) -> Option(#(Vim, Response)) {
  let offset = cursor(state)
  let #(from, to) = case vim.mode {
    VisualMode(kind) -> {
      let #(from, to, _) = visual_span(vim, state, kind)
      #(from, to)
    }
    _ -> #(offset, repeat(state.doc, offset, count, movement.next_offset))
  }
  let selected = document.slice(state.doc, from, to)
  case
    !in_visual(vim)
    && {
      to > movement.line_end(state.doc, offset)
      || string.length(selected) < count
    }
  {
    True -> abandon(vim)
    False -> {
      let payload =
        selected
        |> string.to_graphemes
        |> list.map(fn(item) {
          case item {
            "\n" -> item
            _ -> character
          }
        })
        |> string.concat
      let caret = case in_visual(vim) {
        True -> from
        False -> movement.prev_offset(state.doc, to)
      }
      done(Vim(..vim, mode: NormalMode), [
        command.SelectRange(from: from, to: to),
        command.InsertText(payload),
        command.MoveToOffset(caret, False),
      ])
    }
  }
}

fn delete_caret(doc: document.Document, from: Int, to: Int) -> Int {
  case to < movement.line_end(doc, to) {
    True -> from
    False ->
      int.max(movement.line_start(doc, from), movement.prev_offset(doc, from))
  }
}

fn visual_paste(
  vim: Vim,
  state: State,
  register: Register,
  after: Bool,
) -> Option(#(Vim, Response)) {
  let #(from, to, linewise) = visual_span(vim, state, visual_kind(vim))
  let vim = case after {
    True -> yank_into(Vim(..vim, pending_register: option.None), document.slice(state.doc, from, to), linewise, "d")
    False -> vim
  }
  let caret =
    from + text.prev_boundary(register.text, text.width(register.text))
  done(Vim(..vim, mode: NormalMode), [
    command.SelectRange(from: from, to: to),
    command.InsertText(register.text),
    command.MoveToOffset(caret, False),
  ])
}

/// Convert inclusive Vim endpoints to the browser's half-open selection.
/// The reducer retains the logical cursor; selection callbacks must not feed
/// this display endpoint back into motions or operators.
pub fn browser_selection(vim: Vim, state: State) -> selection.Selection {
  case vim.mode {
    VisualMode(BlockWise) -> selection.from(cursor(state))
    VisualMode(CharacterWise) | VisualMode(LineWise) -> {
      let #(from, to, linewise) = visual_span(vim, state, visual_kind(vim))
      let to = case linewise && to < document.length(state.doc) {
        True -> movement.next_offset(state.doc, to)
        False -> to
      }
      let range = case cursor(state) >= vim.visual_anchor {
        True -> selection.range(from, to)
        False -> selection.range(to, from)
      }
      selection.single(range)
    }
    _ -> state.selection
  }
}

fn run_operator(
  vim: Vim,
  state: State,
  operator: String,
  from: Int,
  to: Int,
  linewise: Bool,
  from_visual: Bool,
) -> Option(#(Vim, Response)) {
  case vim.mode, from_visual, operator {
    VisualMode(BlockWise), True, "c" -> begin_block_insert(vim, state, False, True)
    VisualMode(BlockWise), True, "d"
    | VisualMode(BlockWise), True, "y"
    | VisualMode(BlockWise), True, "gu"
    | VisualMode(BlockWise), True, "gU"
    | VisualMode(BlockWise), True, "g~"
    -> run_block_operator(vim, state, operator)
    _, _, _ ->
      run_linear_operator(vim, state, operator, from, to, linewise, from_visual)
  }
}

fn run_block_operator(
  vim: Vim,
  state: State,
  operator: String,
) -> Option(#(Vim, Response)) {
  run_block_operator_extent(vim, state, operator, False)
}

fn shift_block(vim: Vim, state: State, count: Int, forward: Bool) -> Option(#(Vim, Response)) {
  let rows = block_rows(vim, state, False)
  let changes = list.fold(rows, [], fn(changes, row) {
    case vim_block.shift(state.doc, row, count * 2, forward) {
      option.Some(change) -> [change, ..changes]
      option.None -> changes
    }
  }) |> list.reverse
  let first = case rows {
    [row, ..] -> row.from + text.width(row.leading)
    [] -> cursor(state)
  }
  done(Vim(..vim, mode: NormalMode), [
    command.MoveToOffset(first, False),
    command.EditRanges(changes, first),
  ])
}

fn block_rows(vim: Vim, state: State, to_end: Bool) -> List(vim_block.Row) {
  let rows = vim_block.rows(state.doc, vim.visual_anchor, cursor(state), vim.goal_column, vim.goal_line_end)
  case to_end {
    True -> list.map(rows, fn(row) { vim_block.extend_to_end(state.doc, row) })
    False -> rows
  }
}

fn run_block_operator_extent(vim: Vim, state: State, operator: String, to_end: Bool) -> Option(#(Vim, Response)) {
  let rows = block_rows(vim, state, to_end)
  let #(_, _, left, right) =
    vim_block.bounds(state.doc, vim.visual_anchor, cursor(state), vim.goal_column, vim.goal_line_end)
  let content_right = list.fold(rows, left, fn(maximum, row) { int.max(maximum, row.right) })
  let right = case to_end { True -> content_right False -> int.min(right, content_right) }
  let value = rows |> list.map(fn(row) { row.value }) |> string.join("\n")
  let vim = case operator {
    "d" | "y" -> yank_block(vim, value, right - left, operator)
    _ -> vim
  }
  let first = case rows {
    [row, ..] -> row.from + text.width(row.leading)
    [] -> cursor(state)
  }
  let next = Vim(..vim, mode: NormalMode)
  case operator {
    "y" -> done(next, [command.MoveToOffset(first, False)])
    _ -> {
      let changes =
        rows
        |> list.filter(fn(row) { row.from < row.to })
        |> list.map(fn(row) {
          let value = case operator {
            "d" -> ""
            "gu" -> string.lowercase(row.value)
            "gU" -> string.uppercase(row.value)
            _ -> swap_case(row.value)
          }
          vim_block.change(row, value)
        })
      let caret = case operator, rows {
        "d", [row, ..] ->
          case
            row.to == movement.line_end(state.doc, row.to) && row.trailing == ""
          {
            True ->
              int.max(
                movement.line_start(state.doc, row.from),
                movement.prev_offset(state.doc, row.from),
              )
              + text.width(row.leading)
            False -> first
          }
        _, _ -> first
      }
      done(next, [
        command.MoveToOffset(first, False),
        command.EditRanges(changes, caret),
      ])
    }
  }
}

fn yank_block(vim: Vim, value: String, width: Int, operator: String) -> Vim {
  write_register(vim, Register(value, False, option.Some(width)), operator)
}

fn replace_characters(
  vim: Vim,
  state: State,
  character: String,
  count: Int,
) -> Option(#(Vim, Response)) {
  case vim.mode {
    VisualMode(BlockWise) -> {
      let rows = vim_block.rows(state.doc, vim.visual_anchor, cursor(state), vim.goal_column, vim.goal_line_end)
      let changes =
        rows
        |> list.filter(fn(row) { row.from < row.to })
        |> list.map(fn(row) {
          vim_block.change(row, string.repeat(character, row.right - row.left))
        })
      let caret = case rows {
        [row, ..] -> row.from + text.width(row.leading)
        [] -> cursor(state)
      }
      done(Vim(..vim, mode: NormalMode), [
        command.MoveToOffset(caret, False),
        command.EditRanges(changes, caret),
      ])
    }
    _ -> replace_linear_characters(vim, state, character, count)
  }
}

fn paste(vim: Vim, state: State, after: Bool, count: Int) -> Option(#(Vim, Response)) {
  let name = case vim.pending_register {
    option.Some(name) -> name
    option.None -> "\""
  }
  case dict.get(vim.registers, string.lowercase(name)), vim.mode {
    Ok(register), NormalMode ->
      case register.block_width {
        option.Some(width) -> {
          let at = case after {
            True ->
              int.min(
                movement.next_offset(state.doc, cursor(state)),
                movement.line_end(state.doc, cursor(state)),
              )
            False -> cursor(state)
          }
          let line = document.line_index_at(state.doc, at)
          let column = vim_block.column(state.doc, at)
          let changes =
            block_put_changes(
              state.doc,
              line,
              column,
              string.split(register.text, "\n"),
              width,
              count,
            )
          done(vim, [command.EditRanges(changes, at)])
        }
        option.None -> paste_linear(vim, state, after, count)
      }
    _, _ -> paste_linear(vim, state, after, count)
  }
}

fn block_put_changes(
  doc: document.Document,
  line: Int,
  column: Int,
  values: List(String),
  width: Int,
  count: Int,
) -> List(transaction.Change) {
  case values {
    [] -> []
    [value, ..rest] -> {
      let pad_end = column < vim_block.column(doc, document.line_end(doc, line))
      let value = vim_block.repeat_value(value, width, count, pad_end)
      let change = vim_block.insert(doc, line, column, value)
      case line + 1 < document.line_count(doc), rest {
        True, _ -> [change, ..block_put_changes(doc, line + 1, column, rest, width, count)]
        False, [] -> [change]
        False, _ -> {
          let extra =
            rest
            |> list.map(fn(value) { string.repeat(" ", column) <> vim_block.repeat_value(value, width, count, False) })
            |> string.join("\n")
          [
            transaction.Change(
              change.from,
              document.length(doc),
              change.insert
                <> document.slice(doc, change.to, document.length(doc))
                <> "\n"
                <> extra,
            ),
          ]
        }
      }
    }
  }
}

pub fn capture_insert_start(vim: Vim, current: State) -> Vim {
  case vim.insertion {
    option.Some(start) -> Vim(..vim, insertion: option.Some(InsertSession(..start, opened: current, started: True)))
    option.None -> vim
  }
}

fn append_insert_stroke(vim: Vim, stroke: Stroke) -> Vim {
  case vim.insertion {
    option.Some(start) -> Vim(..vim, insertion: option.Some(InsertSession(..start, strokes: [stroke, ..start.strokes])))
    option.None -> vim
  }
}

pub fn record_native_edit(vim: Vim, before: State, change: transaction.Change) -> Vim {
  case accepts_native_input(vim) {
    False -> vim
    True -> {
      let stroke = EditStroke(change.from - cursor(before), change.to - cursor(before), change.insert)
      let vim = case vim.mode {
        ReplaceMode -> Vim(..vim, replace_undo: replacement_undo(change.from, string.to_graphemes(change.insert), string.to_graphemes(document.slice(before.doc, change.from, change.to)), vim.replace_undo))
        _ -> vim
      }
      record(append_insert_stroke(vim, stroke), stroke)
    }
  }
}

fn finish_insert(vim: Vim, current: State) -> #(Vim, Response) {
  case vim.insertion, vim.insert_repeat > 1 {
    option.Some(start), True -> {
      // The current Escape is replayed only after all counted text has landed.
      let strokes = list.drop(start.strokes, 1)
      let body = strokes |> list.reverse |> list.drop(start.opener_length)
      let next = Vim(..vim, insert_repeat: 1, expanding_insert: True,
        insertion: option.Some(InsertSession(..start, strokes: strokes)))
      #(next, Replay(list.append(repeat_tokens(body, vim.insert_repeat - 1), [KeyStroke("<Esc>")])))
    }
    _, _ -> close_insert(vim, current)
  }
}

fn insertion_opener(vim: Vim, tokens: List(String)) -> #(Int, List(String)) {
  let #(count, rest) = split_count(tokens)
  case vim.mode, rest {
    NormalMode, ["i"] | NormalMode, ["a"] | NormalMode, ["I"]
    | NormalMode, ["A"] | NormalMode, ["g", "I"] | NormalMode, ["R"] -> #(repeat_of(count), rest)
    _, _ -> #(1, tokens)
  }
}

fn close_insert(vim: Vim, current: State) -> #(Vim, Response) {
  let vim = Vim(..vim, expanding_insert: False, insert_repeat: 1, replace_undo: [])
  let caret = int.max(movement.line_start(current.doc, cursor(current)), movement.prev_offset(current.doc, cursor(current)))
  let commands = [command.MoveToOffset(caret, False)]
  case vim.insertion {
    option.None -> #(Vim(..vim, mode: NormalMode, pending: []), Handled(commands))
    option.Some(start) -> {
      let changed = document.to_string(start.before.doc) != document.to_string(current.doc)
        || { vim.mode == ReplaceMode && list.any(start.strokes, fn(stroke) { case stroke { EditStroke(..) -> True _ -> False } }) }
      let last = case changed { True -> option.Some(list.reverse(start.strokes)) False -> vim.last_edit }
      let commands = case vim.block_insertion {
        option.Some(block) -> finish_block_insert(block, start, current)
        option.None -> commands
      }
      #(Vim(..vim, mode: NormalMode, pending: [], insertion: option.None, block_insertion: option.None, last_edit: last),
        Handled(list.append(commands, [command.CoalesceUndo(start.before)])))
    }
  }
}

pub fn key_from_token(token: String) -> Key {
  case token {
    "<Esc>" -> keys.plain("Escape")
    "<CR>" -> keys.plain("Enter")
    "<BS>" -> keys.plain("Backspace")
    "<Del>" -> keys.plain("Delete")
    "<Tab>" -> keys.plain("Tab")
    "<Space>" -> keys.plain(" ")
    "<Left>" -> keys.plain("ArrowLeft")
    "<Right>" -> keys.plain("ArrowRight")
    "<Up>" -> keys.plain("ArrowUp")
    "<Down>" -> keys.plain("ArrowDown")
    _ -> case string.starts_with(token, "<C-") {
      True -> keys.ctrl(token |> string.drop_start(3) |> string.drop_end(1))
      False -> keys.plain(token)
    }
  }
}

fn begin_block_insert(vim: Vim, current: State, append: Bool, change: Bool) -> Option(#(Vim, Response)) {
  begin_block_insert_extent(vim, current, append, change, False)
}

fn begin_block_insert_extent(vim: Vim, current: State, append: Bool, change: Bool, to_end: Bool) -> Option(#(Vim, Response)) {
  let #(first, last, left, right) = vim_block.bounds(current.doc, vim.visual_anchor, cursor(current), vim.goal_column, vim.goal_line_end)
  let column = case append, vim.goal_line_end {
    True, True -> vim_block.column(current.doc, document.line_end(current.doc, first))
    True, False -> right
    False, _ -> left
  }
  let rows = block_rows(vim, current, to_end)
  let right = case to_end { True -> list.fold(rows, left, fn(maximum, row) { int.max(maximum, row.right) }) False -> right }
  let return_to = vim_block.offset_at_column(current.doc, first, left)
  let changes = case change {
    True -> rows |> list.filter(fn(row) { row.from < row.to }) |> list.map(fn(row) { vim_block.change(row, "") })
    False -> [vim_block.insert(current.doc, first, column, "")]
  }
  let doc = transaction.apply(current.doc, changes)
  let at = vim_block.offset_at_column(doc, first, column)
  let vim = case change {
    True -> yank_block(vim, rows |> list.map(fn(row) { row.value }) |> string.join("\n"), right - left, "c")
    False -> vim
  }
  option.Some(#(Vim(..vim, mode: InsertMode, pending: [],
    block_insertion: option.Some(BlockInsertion(first, last, column, append, change, return_to, append && vim.goal_line_end))),
    Handled([command.MoveToOffset(return_to, False), command.EditRanges(changes, at)])))
}

fn finish_block_insert(block: BlockInsertion, start: InsertSession, current: State) -> List(EditorCommand) {
  let from = cursor(start.opened)
  let to = cursor(current)
  let value = case document.line_index_at(current.doc, to) == block.first && to >= from {
    True -> document.slice(current.doc, from, to)
    False -> ""
  }
  let changes = replicate_block_insert(current.doc, start.before.doc, block, block.first + 1, value)
  [command.EditRanges(changes, normal_offset(current.doc, block.return_to))]
}

fn replicate_block_insert(doc: document.Document, original: document.Document, block: BlockInsertion, line: Int, value: String) -> List(transaction.Change) {
  case line > block.last || value == "" {
    True -> []
    False -> {
      let rest = replicate_block_insert(doc, original, block, line + 1, value)
      let width = vim_block.column(original, document.line_end(original, line))
      case block.append || width > block.column {
        True -> {
          let column = case block.line_end { True -> width False -> block.column }
          [vim_block.insert(doc, line, column, value), ..rest]
        }
        False -> rest
      }
    }
  }
}


/// Dot retains the selection's dimensions rather than the motions used to draw it.
fn edit_strokes(vim: Vim, state: State, tokens: List(String)) -> List(Stroke) {
  let keys = list.map(tokens, KeyStroke)
  case vim.mode {
    VisualMode(kind) -> {
      let from = int.min(vim.visual_anchor, cursor(state))
      let to = int.max(vim.visual_anchor, cursor(state))
      let first = document.line_index_at(state.doc, from)
      let last = document.line_index_at(state.doc, to)
      let columns = case kind {
        BlockWise -> {
          let #(_, _, left, right) = vim_block.bounds(state.doc, vim.visual_anchor, cursor(state), vim.goal_column, vim.goal_line_end)
          // Zero marks a block whose right edge follows each row's end.
          case vim.goal_line_end { True -> 0 False -> int.max(1, right - left) }
        }
        LineWise -> 0
        CharacterWise -> {
          let start = case first == last { True -> from False -> document.line_start(state.doc, last) }
          string.length(document.slice(state.doc, start, movement.next_offset(state.doc, to)))
        }
      }
      [VisualStroke(kind, last - first + 1, columns), ..keys]
    }
    _ -> keys
  }
}

pub fn replay_visual(vim: Vim, state: State, kind: VisualKind, lines: Int, columns: Int) -> #(Vim, List(EditorCommand)) {
  let anchor = cursor(state)
  let first = document.line_index_at(state.doc, anchor)
  let last = int.min(document.line_count(state.doc) - 1, first + lines - 1)
  let #(head, goal) = case kind {
    BlockWise -> {
      let column = vim_block.column(state.doc, anchor) + columns - 1
      case columns == 0 {
        True -> #(document.line_end(state.doc, last), option.None)
        False -> #(vim_block.offset_at_column(state.doc, last, column), option.Some(column))
      }
    }
    LineWise -> #(document.line_start(state.doc, last), option.None)
    CharacterWise -> {
      let start = case lines == 1 { True -> anchor False -> document.line_start(state.doc, last) }
      let target = repeat(state.doc, start, int.max(0, columns - 1), movement.next_offset)
      #(int.min(target, document.line_end(state.doc, last)), option.None)
    }
  }
  #(Vim(..vim, mode: VisualMode(kind), visual_anchor: anchor, goal_column: goal,
    goal_line_end: kind == BlockWise && columns == 0, pending: []),
    [command.SelectRange(from: anchor, to: head)])
}


/// Native textareas insert; Vim's replace mode consumes characters on this line.
pub fn native_change(vim: Vim, state: State, change: transaction.Change) -> transaction.Change {
  let change = case accepts_native_input(vim) && change.from == change.to {
    True -> {
      let at = cursor(state)
      let between = document.slice(state.doc, int.min(at, change.from), int.max(at, change.from))
      case change.insert <> between == between <> change.insert {
        True -> transaction.Change(at, at, change.insert)
        False -> change
      }
    }
    False -> change
  }
  case vim.mode, change.insert == "" {
    ReplaceMode, False -> {
      let from = case change.from == change.to { True -> cursor(state) False -> change.from }
      let first_line = string.split(change.insert, "\n") |> list.first |> result.unwrap("")
      let count = string.length(first_line)
      let end = movement.line_end(state.doc, from)
      let to = int.min(end, repeat(state.doc, from, count, movement.next_offset))
      transaction.Change(..change, from: from, to: int.max(from, to))
    }
    _, _ -> change
  }
}


fn replacement_undo(at: Int, inserted: List(String), removed: List(String), stack: List(ReplaceUndo)) -> List(ReplaceUndo) {
  case inserted {
    [] -> stack
    [value, ..rest] -> {
      let #(original, remaining) = case removed {
        [original, ..remaining] -> #(original, remaining)
        [] -> #("", [])
      }
      let end = at + text.width(value)
      replacement_undo(end, rest, remaining, [ReplaceUndo(at, end, original), ..stack])
    }
  }
}

fn replace_backspace(vim: Vim, state: State) -> #(Vim, Response) {
  let at = cursor(state)
  case vim.replace_undo {
    [entry, ..rest] if entry.to == at ->
      #(Vim(..vim, replace_undo: rest), Handled([
        command.EditRanges([transaction.Change(entry.from, entry.to, entry.value)], entry.from),
      ]))
    _ -> #(vim, Handled([command.MoveChar(forward: False, extend: False)]))
  }
}


pub fn submit_search(vim: Vim, state: State, pattern: String, forward: Bool) -> #(Vim, List(EditorCommand)) {
  let query = case pattern == "" {
    True -> vim.search_query
    False -> editor_search.Query(..vim.search_query, search: pattern, whole_word: False, regexp: True)
  }
  let next = Vim(..record(vim, SearchStroke(pattern, forward)), search_query: query, last_search: option.Some(query.search), search_forward: forward, search_count: 1, search_operator: option.None)
  case vim.search_operator {
    option.None -> #(next, search_commands(next, state, forward, vim.search_count))
    option.Some(#(operator, count)) -> case search_target(next, state, forward, count) {
      option.None -> #(Vim(..next, pending_register: option.None), [])
      option.Some(target) -> {
        let at = cursor(state)
        case run_operator(Vim(..next, pending: [operator, case forward { True -> "/" False -> "?" }]), state, operator, int.min(at, target), int.max(at, target), False, False) {
          option.Some(#(edited, Handled(commands))) -> {
            let prefix = case next.pending_register {
              option.Some(name) -> [KeyStroke("\""), KeyStroke(name)]
              option.None -> []
            }
            let counts = case count > 1 { True -> int.to_string(count) |> string.to_graphemes |> list.map(KeyStroke) False -> [] }
            let strokes = list.append(prefix, list.append(counts,
              [KeyStroke(operator), KeyStroke(case forward { True -> "/" False -> "?" }), SearchStroke(pattern, forward)]))
            let edited = case operator {
              "c" -> Vim(..edited, insertion: option.Some(InsertSession(state, state, list.reverse(strokes), False, list.length(strokes))))
              "y" -> edited
              _ -> Vim(..edited, last_edit: option.Some(strokes))
            }
            #(edited, commands)
          }
          _ -> #(next, [])
        }
      }
    }
  }
}

fn search_motion(vim: Vim, state: State, forward: Bool, count: Int) -> MotionResult {
  case search_target(vim, state, forward, count) {
    option.Some(target) -> MotionFound(target, False, False)
    option.None -> MotionFailed
  }
}

fn search_move(vim: Vim, state: State, forward: Bool, count: Int) -> Option(#(Vim, Response)) {
  done(vim, search_commands(vim, state, forward, count))
}

fn search_commands(vim: Vim, state: State, forward: Bool, count: Int) -> List(EditorCommand) {
  case search_target(vim, state, forward, count) {
    option.Some(target) -> {
      let target = case in_visual(vim) {
        True -> target
        False -> normal_cursor(state.doc, target)
      }
      [command.MoveToOffset(target, in_visual(vim))]
    }
    option.None -> []
  }
}

fn search_target(vim: Vim, state: State, forward: Bool, count: Int) -> Option(Int) {
  let all = vim_pattern.starts(state.doc, vim.search_query)
    |> list.map(fn(offset) { case in_visual(vim) { True -> offset False -> normal_cursor(state.doc, offset) } })
  let ordered = case forward { True -> all False -> list.reverse(all) }
  let #(ahead, wrapped) = list.partition(ordered, fn(at) { case forward { True -> at > cursor(state) False -> at < cursor(state) } })
  case list.append(ahead, wrapped) {
    [] -> option.None
    matches -> matches |> list.drop(int.max(0, count - 1) % list.length(matches)) |> list.first |> option.from_result
  }
}

fn normal_cursor(doc: document.Document, offset: Int) -> Int {
  let start = movement.line_start(doc, offset)
  let end = movement.line_end(doc, offset)
  int.min(offset, int.max(start, movement.prev_offset(doc, end)))
}

fn search_word(vim: Vim, state: State, forward: Bool, whole: Bool, count: Int) -> Option(#(Vim, Response)) {
  let at = cursor(state)
  let end = movement.line_end(state.doc, at)
  let found = case search_word_offset(state.doc, at, end, True) {
    option.Some(at) -> option.Some(at)
    option.None -> search_word_offset(state.doc, at, end, False)
  }
  case found {
    option.None -> abandon(vim)
    option.Some(at) -> case vim_object.word(state.doc, at, True, False) {
      option.None -> abandon(vim)
      option.Some(#(from, to)) -> {
        let pattern = document.slice(state.doc, from, to)
        let keyword = text.classify(movement.grapheme_after(state.doc, from)) == text.Word
        let query = editor_search.Query(..vim.search_query, search: pattern, whole_word: whole && keyword, regexp: False)
        let next = Vim(..vim, search_query: query, last_search: option.Some(pattern), search_forward: forward)
        let origin = state.State(..state, selection: selection.from(from))
        case search_target(next, origin, forward, count) {
          option.Some(target) -> done(next, [command.MoveToOffset(target, in_visual(vim))])
          option.None -> abandon(next)
        }
      }
    }
  }
}

fn search_word_offset(doc: document.Document, at: Int, end: Int, keyword: Bool) -> Option(Int) {
  case at >= end {
    True -> option.None
    False -> {
      let class = text.classify(movement.grapheme_after(doc, at))
      case class == text.Word || { !keyword && class != text.Whitespace } {
        True -> option.Some(at)
        False -> search_word_offset(doc, movement.next_offset(doc, at), end, keyword)
      }
    }
  }
}

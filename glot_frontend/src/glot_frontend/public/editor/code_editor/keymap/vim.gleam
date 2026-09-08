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
import gleam/string
import glot_frontend/public/editor/code_editor/command.{type EditorCommand}
import glot_frontend/public/editor/code_editor/document
import glot_frontend/public/editor/code_editor/keymap/vim_object
import glot_frontend/public/editor/code_editor/keys.{type Key}
import glot_frontend/public/editor/code_editor/movement
import glot_frontend/public/editor/code_editor/selection
import glot_frontend/public/editor/code_editor/state.{type State}
import glot_frontend/public/editor/code_editor/text

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
  Register(text: String, linewise: Bool)
}

pub type Vim {
  Vim(
    mode: Mode,
    pending: List(String),
    registers: Dict(String, Register),
    marks: Dict(String, Int),
    recording: Option(#(String, List(String))),
    macros: Dict(String, List(String)),
    last_edit: Option(List(String)),
    last_search: Option(String),
    last_char_search: Option(#(String, String)),
    visual_anchor: Int,
    pending_register: Option(String),
    insert_repeat: Int,
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
  Replay(tokens: List(String))
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
    last_char_search: option.None,
    visual_anchor: 0,
    pending_register: option.None,
    insert_repeat: 1,
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
      Register(text: value, linewise: linewise),
    ),
  )
}

// -- Entry point -------------------------------------------------------------

pub fn handle(vim: Vim, state: State, key: Key) -> #(Vim, Response) {
  case keys.is_modifier(key) {
    True -> #(vim, Pending(status(vim)))
    False -> {
      let token = token_of(key)
      let vim = record(vim, token)
      case vim.mode {
        InsertMode | ReplaceMode -> handle_insert(vim, state, token)
        NormalMode | VisualMode(_) -> handle_command(vim, state, token)
      }
    }
  }
}

fn record(vim: Vim, token: String) -> Vim {
  case vim.recording {
    option.Some(#(register, tokens)) ->
      Vim(..vim, recording: option.Some(#(register, [token, ..tokens])))
    option.None -> vim
  }
}

fn handle_insert(vim: Vim, state: State, token: String) -> #(Vim, Response) {
  case token {
    "<Esc>" | "<C-c>" | "<C-[>" -> #(
      Vim(..vim, mode: NormalMode, pending: []),
      Handled([command.MoveChar(forward: False, extend: False)]),
    )
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
  let tokens = list.append(vim.pending, [key_to_key(vim, token)])
  case interpret(Vim(..vim, pending: tokens), state, tokens) {
    option.Some(#(next, response)) -> #(
      remember_edit(remember_char_search(next, tokens), tokens, response),
      response,
    )
    option.None -> #(Vim(..vim, pending: tokens), Pending(status(
      Vim(..vim, pending: tokens),
    )))
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
fn remember_edit(
  vim: Vim,
  tokens: List(String),
  response: Response,
) -> Vim {
  case response {
    Handled(commands) ->
      case tokens != ["."] && list.any(commands, mutates) {
        True -> Vim(..vim, last_edit: option.Some(tokens))
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
    VisualMode(kind) ->
      case rest {
        [] -> {
          let #(from, to, linewise) = visual_span(vim, state, kind)
          run_operator(vim, state, operator, from, to, linewise, True)
        }
        _ -> abandon(vim)
      }
    _ ->
      case rest {
        [] -> option.None
        _ -> {
          let #(inner_count, motion_tokens) = split_count(rest)
          let total = repeat_of(count) * repeat_of(inner_count)
          let motion_tokens = case operator == "c", motion_tokens {
            // Vim's `cw` changes to the end of the word, like `ce`, instead of
            // swallowing the whitespace that follows it.
            True, ["w"] -> ["e"]
            True, ["W"] -> ["E"]
            _, _ -> motion_tokens
          }
          case doubled(operator, motion_tokens) {
            True -> {
              let first = document.line_index_at(state.doc, cursor(state))
              let last = first + total - 1
              let from = document.line_start(state.doc, first)
              let to = document.line_end(state.doc, last)
              run_operator(vim, state, operator, from, to, True, False)
            }
            False ->
              case resolve_target(vim, state, motion_tokens, total) {
                TargetNeedMore -> option.None
                TargetFailed -> abandon(vim)
                TargetFound(from, to, linewise) ->
                  run_operator(vim, state, operator, from, to, linewise, False)
              }
          }
        }
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

fn run_operator(
  vim: Vim,
  state: State,
  operator: String,
  from: Int,
  to: Int,
  linewise: Bool,
  from_visual: Bool,
) -> Option(#(Vim, Response)) {
  let selected = document.slice(state.doc, from, to)
  let vim = yank_into(vim, selected, linewise)
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
        command.MoveToFirstNonWhitespace(False),
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
    True -> #(document.line_start(state.doc, first), document.line_start(state.doc, last + 1))
    False ->
      case first > 0 {
        True -> #(document.line_end(state.doc, first - 1), document.length(state.doc))
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

fn yank_into(vim: Vim, value: String, linewise: Bool) -> Vim {
  let name = case vim.pending_register {
    option.Some(register) -> register
    option.None -> "\""
  }
  store_register(store_register(vim, "\"", value, linewise), name, value, linewise)
}

// -- Motions and text objects ------------------------------------------------

type Target {
  TargetNeedMore
  TargetFailed
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
    ["i", ..rest] -> object_target(state, rest, True)
    ["a", ..rest] -> object_target(state, rest, False)
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

fn object_target(state: State, tokens: List(String), inner: Bool) -> Target {
  case tokens {
    [] -> TargetNeedMore
    [name] -> {
      let offset = cursor(state)
      let span = case name {
        "w" -> vim_object.word(state.doc, offset, inner, False)
        "W" -> vim_object.word(state.doc, offset, inner, True)
        "p" -> vim_object.paragraph(state.doc, offset, inner)
        "(" | ")" | "b" ->
          vim_object.brackets(state.doc, offset, "(", ")", inner)
        "[" | "]" -> vim_object.brackets(state.doc, offset, "[", "]", inner)
        "{" | "}" | "B" ->
          vim_object.brackets(state.doc, offset, "{", "}", inner)
        "<" | ">" -> vim_object.brackets(state.doc, offset, "<", ">", inner)
        "t" -> vim_object.brackets(state.doc, offset, ">", "<", inner)
        "\"" -> vim_object.quotes(state.doc, offset, "\"", inner)
        "'" -> vim_object.quotes(state.doc, offset, "'", inner)
        "`" -> vim_object.quotes(state.doc, offset, "`", inner)
        _ -> option.None
      }
      case span {
        option.Some(#(from, to)) -> TargetFound(from, to, name == "p")
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
    ["h"] -> MotionFound(repeat(doc, offset, count, movement.prev_offset), False, False)
    ["l"] -> MotionFound(repeat(doc, offset, count, movement.next_offset), False, False)
    ["j"] -> vertical(state, count, True)
    ["k"] -> vertical(state, count, False)
    ["w"] ->
      MotionFound(repeat(doc, offset, count, word_forward), False, False)
    ["W"] ->
      MotionFound(repeat(doc, offset, count, big_word_forward), False, False)
    ["b"] -> MotionFound(repeat(doc, offset, count, movement.group_left), False, False)
    ["B"] -> MotionFound(repeat(doc, offset, count, big_word_left), False, False)
    ["e"] -> MotionFound(repeat(doc, offset, count, word_end), False, True)
    ["E"] -> MotionFound(repeat(doc, offset, count, big_word_end), False, True)
    ["0"] -> MotionFound(movement.line_start(doc, offset), False, False)
    ["^"] -> MotionFound(movement.first_non_whitespace(doc, offset), False, False)
    ["$"] -> MotionFound(line_end_after(doc, offset, count), False, True)
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
    ["G"] -> MotionFound(goto_line(state, count, True), True, False)
    ["g"] -> MotionNeedMore
    ["g", "g"] -> MotionFound(goto_line(state, count, False), True, False)
    ["g", "j"] -> vertical(state, count, True)
    ["g", "k"] -> vertical(state, count, False)
    ["g", "0"] | ["g", "^"] -> MotionFound(movement.line_start(doc, offset), False, False)
    ["g", "$"] -> MotionFound(movement.line_end(doc, offset), False, True)
    ["g", "e"] -> MotionFound(repeat(doc, offset, count, word_end_backward), False, True)
    ["g", "E"] -> MotionFound(repeat(doc, offset, count, word_end_backward), False, True)
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
          char_search(state, kind, character, count)
        option.None -> MotionFailed
      }
    [","] ->
      case vim.last_char_search {
        option.Some(#(kind, character)) ->
          char_search(state, reverse_search(kind), character, count)
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

fn vertical(state: State, count: Int, forward: Bool) -> MotionResult {
  let lines = case forward {
    True -> count
    False -> -count
  }
  let #(target, _) =
    movement.by_line(state.doc, cursor(state), lines, state.goal_column)
  MotionFound(target, True, False)
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
  movement.first_non_whitespace(state.doc, document.line_start(state.doc, clamped))
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
        _ ->
          enter_insert(vim, [command.MoveChar(forward: True, extend: False)])
      }
    ["I"] -> enter_insert(vim, [command.MoveToFirstNonWhitespace(False)])
    ["A"] -> enter_insert(vim, [command.MoveLineBoundary(True, False)])
    ["g"] -> option.None
    ["g", "I"] -> enter_insert(vim, [command.MoveLineEdge(False, False)])
    ["g", "i"] -> enter_insert(vim, [])
    ["g", "v"] ->
      option.Some(#(
        Vim(..vim, mode: VisualMode(CharacterWise), pending: []),
        Handled([]),
      ))
    ["g", "J"] -> done(vim, [command.JoinLines(keep_spaces: True)])
    ["o"] ->
      case vim.mode {
        VisualMode(_) ->
          option.Some(#(
            Vim(..vim, pending: [], visual_anchor: offset),
            Handled([command.MoveToOffset(vim.visual_anchor, True)]),
          ))
        _ ->
          enter_insert(vim, [
            command.MoveLineBoundary(True, False),
            command.InsertNewlineAndIndent,
          ])
      }
    ["O"] ->
      enter_insert(vim, [
        command.MoveLineEdge(False, False),
        command.InsertText("\n"),
        command.MoveChar(forward: False, extend: False),
      ])
    ["v"] -> toggle_visual(vim, state, CharacterWise)
    ["V"] -> toggle_visual(vim, state, LineWise)
    ["<C-v>"] | ["<C-q>"] -> toggle_visual(vim, state, BlockWise)
    ["x"] -> delete_chars(vim, state, total, True)
    ["X"] -> delete_chars(vim, state, total, False)
    ["D"] -> operator_to_line_end(vim, state, "d")
    ["C"] -> operator_to_line_end(vim, state, "c")
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
    ["s"] -> {
      let to = movement.next_offset(state.doc, offset)
      run_operator(vim, state, "c", offset, to, False, False)
    }
    ["S"] -> {
      let index = document.line_index_at(state.doc, offset)
      run_operator(
        vim,
        state,
        "c",
        document.line_start(state.doc, index),
        document.line_end(state.doc, index),
        False,
        False,
      )
    }
    ["J"] -> done(vim, [command.JoinLines(keep_spaces: False)])
    ["p"] -> paste(vim, state, True)
    ["P"] -> paste(vim, state, False)
    ["u"] ->
      case vim.mode {
        VisualMode(_) -> {
          let #(from, to, _) = visual_span(vim, state, visual_kind(vim))
          option.Some(#(
            Vim(..vim, mode: NormalMode, pending: []),
            Handled([
              command.SelectRange(from: from, to: to),
              command.ChangeCase(to_upper: False),
            ]),
          ))
        }
        _ -> done(vim, repeat_commands(command.Undo, total))
      }
    ["U"] -> {
      let #(from, to, _) = visual_span(vim, state, visual_kind(vim))
      option.Some(#(
        Vim(..vim, mode: NormalMode, pending: []),
        Handled([
          command.SelectRange(from: from, to: to),
          command.ChangeCase(to_upper: True),
        ]),
      ))
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
    ["~"] -> {
      let to = movement.next_offset(state.doc, offset)
      let selected = document.slice(state.doc, offset, to)
      done(vim, [
        command.SelectRange(from: offset, to: to),
        command.InsertText(swap_case(selected)),
      ])
    }
    ["r"] -> option.None
    ["r", character] -> {
      let to = movement.next_offset(state.doc, offset)
      done(vim, [
        command.SelectRange(from: offset, to: to),
        command.InsertText(string.repeat(character, total)),
        command.MoveToOffset(offset, False),
      ])
    }
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
    ["n"] -> done(vim, [command.FindNext])
    ["N"] -> done(vim, [command.FindPrevious])
    ["*"] ->
      done(vim, [command.SearchForSelection(forward: True, whole_word: True)])
    ["#"] ->
      done(vim, [command.SearchForSelection(forward: False, whole_word: True)])
    ["g", "*"] ->
      done(vim, [command.SearchForSelection(forward: True, whole_word: False)])
    ["g", "#"] ->
      done(vim, [command.SearchForSelection(forward: False, whole_word: False)])
    ["/"] ->
      option.Some(#(
        Vim(..vim, pending: []),
        Prompt(SearchPrompt(forward: True)),
      ))
    ["?"] ->
      option.Some(#(
        Vim(..vim, pending: []),
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
        MotionFound(target, _, _) ->
          done(vim, [command.MoveToOffset(target, in_visual(vim))])
      }
  }
}

fn repeat_tokens(tokens: List(String), count: Int) -> List(String) {
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

fn trim_recording(recorded: List(String)) -> List(String) {
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
  option.Some(#(
    Vim(..vim, mode: InsertMode, pending: []),
    Handled(commands),
  ))
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
      let last = document.line_index_at(state.doc, to)
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
    True -> repeat(state.doc, offset, count, movement.next_offset)
    False -> repeat(state.doc, offset, count, movement.prev_offset)
  }
  let #(from, to) = case forward {
    True -> #(offset, target)
    False -> #(target, offset)
  }
  run_operator(vim, state, "d", from, to, False, in_visual(vim))
}

fn operator_to_line_end(
  vim: Vim,
  state: State,
  operator: String,
) -> Option(#(Vim, Response)) {
  let offset = cursor(state)
  run_operator(vim, state, operator, offset, movement.line_end(state.doc, offset), False, False)
}

fn paste(vim: Vim, state: State, after: Bool) -> Option(#(Vim, Response)) {
  let name = case vim.pending_register {
    option.Some(register) -> register
    option.None -> "\""
  }
  case dict.get(vim.registers, name) {
    Error(_) -> abandon(vim)
    Ok(register) -> {
      let offset = cursor(state)
      case register.linewise {
        True -> {
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
            command.SelectRange(from: at, to: at),
            command.InsertText(payload),
          ])
        }
        False -> {
          let at = case after {
            True -> movement.next_offset(state.doc, offset)
            False -> offset
          }
          done(vim, [
            command.SelectRange(from: at, to: at),
            command.InsertText(register.text),
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
  case paste(vim, state, True) {
    option.Some(#(_, Handled(commands))) -> commands
    _ -> []
  }
}

/// `:s/pattern/replacement/[g]`, and the `:g`/`:v` line filters that share its
/// shape.
fn ex_substitute(vim: Vim, _state: State, input: String) -> #(
  Vim,
  List(EditorCommand),
) {
  case string.split(input, "/") {
    ["s", pattern, replacement, ..flags]
    | ["substitute", pattern, replacement, ..flags]
    | ["%s", pattern, replacement, ..flags] -> {
      let all = case flags {
        [found, ..] -> string.contains(found, "g")
        [] -> False
      }
      #(vim, [
        command.Substitute(
          pattern: pattern,
          replacement: replacement,
          all: all,
        ),
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

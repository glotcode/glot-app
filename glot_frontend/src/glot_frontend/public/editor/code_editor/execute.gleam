//// Executes editor commands against the model.
////
//// This is the one place a command becomes a transaction, so the default, Vim,
//// and Emacs keymaps cannot diverge in what a shared operation does.

import gleam/list
import gleam/option.{type Option}
import gleam/string
import glot_frontend/public/editor/code_editor/browser_command
import glot_frontend/public/editor/code_editor/command.{type EditorCommand}
import glot_frontend/public/editor/code_editor/document
import glot_frontend/public/editor/code_editor/editing
import glot_frontend/public/editor/code_editor/history
import glot_frontend/public/editor/code_editor/reconcile
import glot_frontend/public/editor/code_editor/highlight_state
import glot_frontend/public/editor/code_editor/keymap/emacs
import glot_frontend/public/editor/code_editor/message.{type Msg, type Outbound}
import glot_frontend/public/editor/code_editor/model.{type Model, Model} as editor_model
import glot_frontend/public/editor/code_editor/movement
import glot_frontend/public/editor/code_editor/search
import glot_frontend/public/editor/code_editor/selection
import glot_frontend/public/editor/code_editor/session
import glot_frontend/public/editor/code_editor/state
import glot_frontend/public/editor/code_editor/transaction.{type Transaction}

pub type Result {
  Result(
    model: Model,
    command: browser_command.Command(Msg),
    outbound: List(Outbound),
    changed: Bool,
  )
}

pub fn idle(model: Model) -> Result {
  Result(
    model: model,
    command: browser_command.none(),
    outbound: [],
    changed: False,
  )
}

/// Run a list of commands in order, threading the model through.
pub fn run(model: Model, commands: List(EditorCommand)) -> Result {
  list.fold(commands, idle(model), fn(accumulated, item) {
    let next = run_one(accumulated.model, item)
    Result(
      model: next.model,
      command: browser_command.batch([accumulated.command, next.command]),
      outbound: list.append(accumulated.outbound, next.outbound),
      changed: accumulated.changed || next.changed,
    )
  })
  |> synchronise
}

/// After a batch, push the document and selection into the textarea once.
fn synchronise(result: Result) -> Result {
  let current = editor_model.state(result.model)
  let main = selection.main(editor_model.browser_selection(result.model))
  let sync = case result.changed {
    True ->
      browser_command.SyncDocument(
        value: state.text(current),
        selection_anchor: main.anchor,
        selection_head: main.head,
      )
    False ->
      browser_command.SyncSelection(
        selection_anchor: main.anchor,
        selection_head: main.head,
      )
  }
  let caret_line = document.line_index_at(current.doc, selection.head(current.selection))
  Result(
    ..result,
    command: browser_command.batch([
      result.command,
      sync,
      browser_command.ScrollToLine(
        line: caret_line,
        intent: browser_command.KeepCaretVisible,
      ),
    ]),
  )
}

fn changed(model: Model) -> Result {
  Result(
    model: model,
    command: browser_command.none(),
    outbound: [message.DocumentChanged],
    changed: True,
  )
}

fn moved(model: Model) -> Result {
  Result(
    model: model,
    command: browser_command.none(),
    outbound: [],
    changed: False,
  )
}

// -- Applying transactions ---------------------------------------------------

pub fn apply(model: Model, tr: Transaction) -> Model {
  let current = editor_model.active_session(model)
  let before = current.state
  let next = state.apply(before, tr)
  let invalidate_from = case tr.changes {
    [] -> option.None
    changes ->
      option.Some(
        changes
        |> list.map(fn(change) {
          document.line_index_at(before.doc, change.from)
        })
        |> list.fold(document.line_count(before.doc), int_min),
      )
  }
  let cache = case invalidate_from {
    option.Some(line) -> highlight_state.invalidate_from(current.highlight, line)
    option.None -> current.highlight
  }
  editor_model.put_session(
    model,
    session.Session(..current, state: next, highlight: cache),
  )
}

fn apply_result(model: Model, tr: Transaction) -> Result {
  case transaction.is_empty(tr) {
    True -> idle(model)
    False ->
      case transaction.changes_document(tr) {
        True -> changed(apply(model, tr))
        False -> moved(apply(model, tr))
      }
  }
}

fn int_min(a: Int, b: Int) -> Int {
  case a < b {
    True -> a
    False -> b
  }
}

fn read_only_blocked(model: Model, item: EditorCommand) -> Bool {
  model.read_only && mutating(item)
}

fn mutating(item: EditorCommand) -> Bool {
  case item {
    command.CoalesceUndo(..)
    | command.EditRanges(..)
    | command.InsertText(_)
    | command.InsertNewlineAndIndent
    | command.InsertBlankLine
    | command.SplitLine
    | command.TransposeChars
    | command.JoinLines(..)
    | command.IndentMore
    | command.IndentLess
    | command.IndentSelection
    | command.MoveLineUp
    | command.MoveLineDown
    | command.CopyLineUp
    | command.CopyLineDown
    | command.ToggleComment
    | command.ToggleBlockComment
    | command.ChangeCase(..)
    | command.ChangeWordCase(..)
    | command.DeleteChar(..)
    | command.DeleteGroup(..)
    | command.DeleteLineBoundary(..)
    | command.DeleteToLineEnd
    | command.DeleteToLineStart
    | command.DeleteLine
    | command.DeleteSelection
    | command.Undo
    | command.Redo
    | command.Cut
    | command.Paste
    | command.KillRegion(..)
    | command.KillLine
    | command.KillWord(..)
    | command.Yank
    | command.YankRotate
    | command.ReplaceNext
    | command.ReplaceAll
    | command.Substitute(..)
    | command.SortLines -> True
    _ -> False
  }
}

// -- One command -------------------------------------------------------------

fn run_one(model: Model, item: EditorCommand) -> Result {
  case read_only_blocked(model, item) {
    True -> idle(model)
    False -> execute(model, item)
  }
}

fn execute(model: Model, item: EditorCommand) -> Result {
  let current = editor_model.state(model)
  let context = editor_model.context(model)

  case item {
    command.EditRanges(changes, caret) -> apply_result(model, transaction.new(changes, transaction.Command) |> transaction.with_selection(selection.from(caret)))
    command.CoalesceUndo(before) -> coalesce_undo(model, before)
    command.Noop -> idle(model)
    command.Sequence(items) -> run(model, items)

    // -- Movement
    command.MoveChar(forward, extend) ->
      apply_result(
        model,
        editing.move_horizontally(current, extend, forward, case forward {
          True -> movement.next_offset
          False -> movement.prev_offset
        }),
      )
    command.MoveGroup(forward, extend) | command.MoveSubword(forward, extend) ->
      apply_result(
        model,
        editing.move_by(current, extend, case forward {
          True -> movement.group_right
          False -> movement.group_left
        }),
      )
    command.MoveLine(forward, extend) -> vertical(model, extend, case forward {
      True -> 1
      False -> -1
    })
    command.MovePage(forward, extend) ->
      vertical(model, extend, case forward {
        True -> editor_model.page_lines(model)
        False -> -editor_model.page_lines(model)
      })
    command.MoveLineBoundary(forward, extend) ->
      apply_result(
        model,
        editing.move_by(current, extend, case forward {
          True -> movement.line_boundary_forward
          False -> movement.line_boundary_backward
        }),
      )
    command.MoveLineEdge(forward, extend) ->
      apply_result(
        model,
        editing.move_by(current, extend, case forward {
          True -> movement.line_end
          False -> movement.line_start
        }),
      )
    command.MoveDocBoundary(forward, extend) ->
      apply_result(
        model,
        editing.move_by(current, extend, fn(doc, _) {
          case forward {
            True -> movement.doc_end(doc)
            False -> movement.doc_start(doc)
          }
        }),
      )
    command.MoveParagraph(forward, extend) ->
      apply_result(
        model,
        editing.move_by(current, extend, case forward {
          True -> movement.paragraph_forward
          False -> movement.paragraph_backward
        }),
      )
    command.MoveToFirstNonWhitespace(extend) ->
      apply_result(
        model,
        editing.move_by(current, extend, movement.first_non_whitespace),
      )
    command.MoveToColumn(column, extend) ->
      apply_result(
        model,
        editing.move_by(current, extend, fn(doc, offset) {
          movement.offset_at_column(
            doc,
            document.line_index_at(doc, offset),
            column,
          )
        }),
      )
    command.MoveToLineNumber(line, extend) ->
      apply_result(
        model,
        editing.move_by(current, extend, fn(doc, _) {
          movement.first_non_whitespace(
            doc,
            document.line_start(
              doc,
              document.clamp(line - 1, 0, document.line_count(doc) - 1),
            ),
          )
        }),
      )
    command.MoveToMatchingBracket(extend) ->
      apply_result(
        model,
        editing.move_by(current, extend, fn(doc, offset) {
          case movement.matching_bracket(doc, offset) {
            option.Some(target) -> target
            option.None -> offset
          }
        }),
      )
    command.MoveToOffset(offset, extend) ->
      apply_result(model, editing.move_by(current, extend, fn(_, _) { offset }))

    // -- Deletion
    command.DeleteChar(forward) ->
      apply_result(
        model,
        editing.delete_by(
          current,
          case forward {
            True -> movement.next_offset
            False -> movement.prev_offset
          },
          transaction.Deleting,
        ),
      )
    command.DeleteGroup(forward) ->
      apply_result(
        model,
        editing.delete_by(
          current,
          case forward {
            True -> movement.group_right
            False -> movement.group_left
          },
          transaction.Deleting,
        ),
      )
    command.DeleteLineBoundary(forward) ->
      apply_result(
        model,
        editing.delete_by(
          current,
          case forward {
            True -> movement.line_end
            False -> movement.line_start
          },
          transaction.Deleting,
        ),
      )
    command.DeleteToLineEnd ->
      apply_result(
        model,
        editing.delete_by(current, movement.line_end, transaction.Deleting),
      )
    command.DeleteToLineStart ->
      apply_result(
        model,
        editing.delete_by(current, movement.line_start, transaction.Deleting),
      )
    command.DeleteLine -> apply_result(model, editing.delete_line(current))
    command.DeleteSelection ->
      apply_result(model, editing.insert(current, "", transaction.Deleting))

    // -- Insertion
    command.InsertText(value) ->
      apply_result(model, editing.insert(current, value, transaction.Bulk))
    command.InsertNewlineAndIndent ->
      apply_result(model, editing.insert_newline_and_indent(current, context))
    command.InsertBlankLine ->
      apply_result(model, editing.insert_blank_line(current))
    command.SplitLine -> apply_result(model, editing.split_line(current))
    command.TransposeChars ->
      apply_result(model, editing.transpose_chars(current))
    command.JoinLines(keep_spaces) ->
      apply_result(model, editing.join_lines(current, keep_spaces))

    // -- Lines
    command.IndentMore -> apply_result(model, editing.indent_more(current, context))
    command.IndentLess -> apply_result(model, editing.indent_less(current, context))
    command.IndentSelection ->
      apply_result(model, editing.indent_selection(current, context))
    command.MoveLineUp -> apply_result(model, editing.move_line_up(current))
    command.MoveLineDown -> apply_result(model, editing.move_line_down(current))
    command.CopyLineUp -> apply_result(model, editing.copy_line_up(current))
    command.CopyLineDown -> apply_result(model, editing.copy_line_down(current))
    command.SortLines -> apply_result(model, sort_lines(current))

    // -- Comments and case
    command.ToggleComment ->
      apply_result(model, editing.toggle_comment(current, context))
    command.ToggleBlockComment ->
      apply_result(model, editing.toggle_block_comment(current, context))
    command.ChangeCase(to_upper) ->
      apply_result(model, editing.change_case(current, to_upper))
    command.ChangeWordCase(to_upper) -> {
      let #(from, to) =
        movement.word_after(current.doc, selection.head(current.selection))
      let selected = document.slice(current.doc, from, to)
      case selected == "" {
        True -> idle(model)
        False ->
          apply_result(
            model,
            transaction.new(
              [
                transaction.Change(from: from, to: to, insert: case to_upper {
                  True -> string.uppercase(selected)
                  False -> string.lowercase(selected)
                }),
              ],
              transaction.Command,
            )
              |> transaction.with_selection(selection.from(to)),
          )
      }
    }

    // -- Selection
    command.SelectAll -> apply_result(model, editing.select_all(current))
    command.SelectLine -> apply_result(model, editing.select_line(current))
    command.SelectWord -> {
      let #(from, to) =
        movement.word_at(current.doc, selection.head(current.selection))
      apply_result(
        model,
        transaction.selection_only(
          selection.single(selection.range(from, to)),
        ),
      )
    }
    command.SelectParagraph -> {
      let head = selection.head(current.selection)
      apply_result(
        model,
        transaction.selection_only(
          selection.single(selection.range(
            movement.paragraph_backward(current.doc, head),
            movement.paragraph_forward(current.doc, head),
          )),
        ),
      )
    }
    command.SimplifySelection ->
      apply_result(model, editing.simplify_selection(current))
    command.SelectRange(from, to) ->
      apply_result(
        model,
        transaction.selection_only(selection.single(selection.range(from, to))),
      )
    command.SelectRectangularRegion -> rectangular_region(model)

    // -- History
    command.Undo -> history_step(model, state.undo)
    command.Redo -> history_step(model, state.redo)
    command.UndoSelection -> history_step(model, state.undo)
    command.RedoSelection -> history_step(model, state.redo)

    // -- Search
    command.OpenSearchPanel -> open_search(model)
    command.CloseSearchPanel ->
      Result(
        ..idle(
          Model(
            ..model,
            search: editor_model.SearchPanel(..model.search, open: False),
          ),
        ),
        command: browser_command.FocusEditor,
      )
    command.FindNext -> find(model, True)
    command.FindPrevious -> find(model, False)
    command.SelectNextOccurrence -> select_next_occurrence(model)
    command.SelectSelectionMatches -> select_all_matches(model)
    command.ReplaceNext -> replace_next(model)
    command.ReplaceAll -> replace_all(model)
    command.SetSearchQuery(pattern, whole_word, regexp) ->
      idle(
        Model(
          ..model,
          search: editor_model.SearchPanel(
            ..model.search,
            query: search.Query(
              ..model.search.query,
              search: pattern,
              whole_word: whole_word,
              regexp: regexp,
            ),
          ),
        ),
      )
    command.Substitute(pattern, replacement, all) ->
      substitute(model, pattern, replacement, all)
    command.SearchForSelection(forward, whole_word) ->
      search_for_selection(model, forward, whole_word)
    command.OpenGotoLinePrompt ->
      open_prompt(model, editor_model.GotoLinePrompt, "Go to line: ")
    command.OpenCommandPrompt(label) ->
      open_prompt(model, editor_model.CommandPrompt, label)

    // -- Viewport
    command.ScrollCaret(position) -> scroll_caret(model, position)
    command.ScrollLines(forward) ->
      Result(
        ..idle(model),
        command: browser_command.ScrollBy(case forward {
          True -> 1
          False -> -1
        }),
      )
    command.RecenterTopBottom -> scroll_caret(model, command.ScrollCenter)
    command.CenterSelection -> scroll_caret(model, command.ScrollCenter)

    // -- Clipboard
    command.Copy ->
      Result(
        ..idle(model),
        command: browser_command.WriteClipboard(selected_text(current)),
      )
    command.Cut -> {
      let copied = selected_text(current)
      Result(
        ..apply_result(model, editing.insert(current, "", transaction.Deleting)),
        command: browser_command.WriteClipboard(copied),
      )
    }
    command.Paste -> idle(model)

    // -- Emacs mark and kill ring
    command.SetMark ->
      idle(
        Model(
          ..model,
          emacs: emacs.set_mark(
            model.emacs,
            option.Some(selection.head(current.selection)),
          ),
          status: option.Some("Mark set"),
        ),
      )
    command.ClearMark ->
      idle(Model(..model, emacs: emacs.set_mark(model.emacs, option.None)))
    command.ExchangePointAndMark -> exchange_point_and_mark(model)
    command.KillRegion(save_only) -> kill_region(model, save_only)
    command.KillLine -> kill_line(model)
    command.KillWord(forward) -> kill_word(model, forward)
    command.Yank -> yank(model, False)
    command.YankRotate -> yank(model, True)
    command.KeyboardQuit -> keyboard_quit(model)

    command.ClearMarks -> idle(model)

    // -- Modes and outbound
    command.RunSnippet ->
      Result(..idle(model), outbound: [message.RunRequested])
    command.SaveSnippet ->
      Result(..idle(model), outbound: [message.SaveRequested])
  }
}

fn vertical(model: Model, extend: Bool, lines: Int) -> Result {
  let current = editor_model.state(model)
  let #(tr, goal) = editing.move_vertically(current, extend, lines)
  let next = state.set_goal_column(state.apply(current, tr), goal)
  let session_now = editor_model.active_session(model)
  moved(editor_model.put_session(model, session.Session(..session_now, state: next)))
}

fn selected_text(current: state.State) -> String {
  let main = selection.main(current.selection)
  document.slice(current.doc, selection.start(main), selection.end(main))
}

fn sort_lines(current: state.State) -> Transaction {
  case editing.selected_line_spans(current) {
    [#(first, last)] if last > first -> {
      let sorted =
        editing.line_range(#(first, last))
        |> list.map(fn(index) { document.line_text(current.doc, index) })
        |> list.sort(string.compare)
        |> string.join("\n")
      transaction.new(
        [
          transaction.Change(
            from: document.line_start(current.doc, first),
            to: document.line_end(current.doc, last),
            insert: sorted,
          ),
        ],
        transaction.Command,
      )
    }
    _ -> transaction.new([], transaction.Command)
  }
}

fn history_step(
  model: Model,
  step: fn(state.State) -> Option(state.State),
) -> Result {
  let current = editor_model.active_session(model)
  case step(current.state) {
    option.None -> idle(model)
    option.Some(next) ->
      changed(
        editor_model.put_session(
          model,
          session.Session(
            ..current,
            state: next,
            highlight: highlight_state.new(),
          ),
        ),
      )
  }
}

// -- Search helpers ----------------------------------------------------------

fn open_search(model: Model) -> Result {
  let current = editor_model.state(model)
  let seed = selected_text(current)
  let query = case seed == "" || string.contains(seed, "\n") {
    True -> model.search.query
    False -> search.Query(..model.search.query, search: seed)
  }
  Result(
    ..idle(
      Model(
        ..model,
        search: editor_model.SearchPanel(open: True, query: query, focus_field: True),
      ),
    ),
    command: browser_command.FocusSearchField,
  )
}

fn find(model: Model, forward: Bool) -> Result {
  let current = editor_model.state(model)
  let main = selection.main(current.selection)
  let found = case forward {
    True -> search.find_next(current.doc, model.search.query, selection.end(main))
    False ->
      search.find_previous(current.doc, model.search.query, selection.start(main))
  }
  case found {
    option.None -> idle(Model(..model, status: option.Some("No matches")))
    option.Some(#(from, to)) ->
      apply_result(
        model,
        transaction.selection_only(selection.single(selection.range(from, to))),
      )
  }
}

fn select_next_occurrence(model: Model) -> Result {
  let current = editor_model.state(model)
  let main = selection.main(current.selection)
  case selection.is_empty(main) {
    True -> {
      let #(from, to) = movement.word_at(current.doc, main.head)
      apply_result(
        model,
        transaction.selection_only(selection.single(selection.range(from, to))),
      )
    }
    False -> {
      let word = selected_text(current)
      let query = search.Query(..model.search.query, search: word)
      let updated =
        Model(..model, search: editor_model.SearchPanel(..model.search, query: query))
      find(updated, True)
    }
  }
}

fn select_all_matches(model: Model) -> Result {
  let current = editor_model.state(model)
  let word = selected_text(current)
  case word == "" {
    True -> idle(model)
    False -> {
      let query = search.Query(..model.search.query, search: word)
      let ranges =
        search.matches(current.doc, query)
        |> list.map(fn(span) { selection.range(span.0, span.1) })
      case ranges {
        [] -> idle(model)
        _ ->
          apply_result(
            Model(
              ..model,
              search: editor_model.SearchPanel(..model.search, query: query),
            ),
            transaction.selection_only(selection.many(ranges, False)),
          )
      }
    }
  }
}

fn replace_next(model: Model) -> Result {
  let current = editor_model.state(model)
  let main = selection.main(current.selection)
  case
    search.find_next(current.doc, model.search.query, selection.start(main))
  {
    option.None -> idle(model)
    option.Some(#(from, to)) ->
      apply_result(
        model,
        transaction.new(
          [
            transaction.Change(
              from: from,
              to: to,
              insert: model.search.query.replace,
            ),
          ],
          transaction.Command,
        ),
      )
  }
}

fn replace_all(model: Model) -> Result {
  let current = editor_model.state(model)
  let changes =
    search.matches(current.doc, model.search.query)
    |> list.map(fn(span) {
      transaction.Change(
        from: span.0,
        to: span.1,
        insert: model.search.query.replace,
      )
    })
  case changes {
    [] -> idle(model)
    [first, ..] -> {
      // Assemble the replaced region once. Applying thousands of individual
      // changes would rebuild the document's entire line list for every match.
      let #(end, pieces) = list.fold(changes, #(first.from, []), fn(acc, change) {
        let #(cursor, pieces) = acc
        #(
          change.to,
          [change.insert, document.slice(current.doc, cursor, change.from), ..pieces],
        )
      })
      let insert = pieces |> list.reverse |> string.join("")
      let selection = transaction.map_selection(changes, current.selection, False)
      let combined = transaction.Change(from: first.from, to: end, insert: insert)
      apply_result(
        model,
        transaction.new([combined], transaction.Command)
        |> transaction.with_selection(selection),
      )
    }
  }
}

fn substitute(
  model: Model,
  pattern: String,
  replacement: String,
  all: Bool,
) -> Result {
  let query =
    search.Query(
      search: pattern,
      replace: replacement,
      case_sensitive: True,
      whole_word: False,
      regexp: True,
    )
  let updated =
    Model(..model, search: editor_model.SearchPanel(..model.search, query: query))
  case all {
    True -> replace_all(updated)
    False -> replace_next(updated)
  }
}

fn search_for_selection(
  model: Model,
  forward: Bool,
  whole_word: Bool,
) -> Result {
  let current = editor_model.state(model)
  let main = selection.main(current.selection)
  let word = case selection.is_empty(main) {
    True -> {
      let #(from, to) = movement.word_at(current.doc, main.head)
      document.slice(current.doc, from, to)
    }
    False -> selected_text(current)
  }
  case word == "" {
    True -> idle(model)
    False -> {
      let query =
        search.Query(
          ..model.search.query,
          search: word,
          whole_word: whole_word,
          regexp: False,
        )
      find(
        Model(..model, search: editor_model.SearchPanel(..model.search, query: query)),
        forward,
      )
    }
  }
}

fn open_prompt(model: Model, kind: editor_model.PromptKind, label: String) -> Result {
  Result(
    ..idle(
      Model(
        ..model,
        prompt: option.Some(editor_model.Prompt(kind: kind, label: label, value: "")),
      ),
    ),
    command: browser_command.FocusPrompt,
  )
}

// -- Viewport ----------------------------------------------------------------

fn scroll_caret(model: Model, position: command.ScrollPosition) -> Result {
  let current = editor_model.state(model)
  let line =
    document.line_index_at(current.doc, selection.head(current.selection))
  Result(
    ..idle(model),
    command: browser_command.ScrollToLine(
      line: line,
      intent: case position {
        command.ScrollTop -> browser_command.CaretToTop
        command.ScrollCenter -> browser_command.CaretToCenter
        command.ScrollBottom -> browser_command.CaretToBottom
      },
    ),
  )
}

// -- Rectangular selection ---------------------------------------------------

/// Glot never enabled multiple selections, so a rectangular region resolves to
/// the single range spanning its corners — the behaviour that was actually
/// reachable — and the view draws the rectangle so the shape stays visible.
fn rectangular_region(model: Model) -> Result {
  let current = editor_model.state(model)
  let main = selection.main(current.selection)
  apply_result(
    model,
    transaction.selection_only(
      selection.Selection(
        ranges: [main],
        primary: 0,
        rectangular: True,
      ),
    ),
  )
}

// -- Emacs mark and kill ring ------------------------------------------------

fn exchange_point_and_mark(model: Model) -> Result {
  let current = editor_model.state(model)
  case emacs.mark(model.emacs) {
    option.None -> idle(model)
    option.Some(mark) -> {
      let head = selection.head(current.selection)
      apply_result(
        Model(..model, emacs: emacs.set_mark(model.emacs, option.Some(head))),
        transaction.selection_only(
          selection.single(selection.range(head, mark)),
        ),
      )
    }
  }
}

fn region(model: Model) -> #(Int, Int) {
  let current = editor_model.state(model)
  let head = selection.head(current.selection)
  case emacs.mark(model.emacs) {
    option.Some(mark) ->
      case mark <= head {
        True -> #(mark, head)
        False -> #(head, mark)
      }
    option.None -> {
      let main = selection.main(current.selection)
      #(selection.start(main), selection.end(main))
    }
  }
}

fn kill_region(model: Model, save_only: Bool) -> Result {
  let current = editor_model.state(model)
  let #(from, to) = region(model)
  let killed = document.slice(current.doc, from, to)
  case killed == "" {
    True -> idle(model)
    False -> {
      let pushed =
        Model(
          ..model,
          kill_ring: [killed, ..model.kill_ring],
          kill_index: 0,
          last_yank: option.None,
          emacs: emacs.set_mark(model.emacs, option.None),
        )
      case save_only {
        True ->
          Result(
            ..apply_result(
              pushed,
              transaction.selection_only(selection.from(to)),
            ),
            command: browser_command.WriteClipboard(killed),
          )
        False ->
          Result(
            ..apply_result(
              pushed,
              transaction.new(
                [transaction.Change(from: from, to: to, insert: "")],
                transaction.Deleting,
              ),
            ),
            command: browser_command.WriteClipboard(killed),
          )
      }
    }
  }
}

fn kill_line(model: Model) -> Result {
  let current = editor_model.state(model)
  let head = selection.head(current.selection)
  let end = movement.line_end(current.doc, head)
  let to = case end == head {
    True -> movement.next_offset(current.doc, head)
    False -> end
  }
  let killed = document.slice(current.doc, head, to)
  case killed == "" {
    True -> idle(model)
    False ->
      apply_result(
        Model(
          ..model,
          kill_ring: [killed, ..model.kill_ring],
          kill_index: 0,
          last_yank: option.None,
        ),
        transaction.new(
          [transaction.Change(from: head, to: to, insert: "")],
          transaction.Deleting,
        ),
      )
  }
}

fn kill_word(model: Model, forward: Bool) -> Result {
  let current = editor_model.state(model)
  let head = selection.head(current.selection)
  let target = case forward {
    True -> movement.group_right(current.doc, head)
    False -> movement.group_left(current.doc, head)
  }
  let #(from, to) = case forward {
    True -> #(head, target)
    False -> #(target, head)
  }
  let killed = document.slice(current.doc, from, to)
  case killed == "" {
    True -> idle(model)
    False ->
      apply_result(
        Model(
          ..model,
          kill_ring: [killed, ..model.kill_ring],
          kill_index: 0,
          last_yank: option.None,
        ),
        transaction.new(
          [transaction.Change(from: from, to: to, insert: "")],
          transaction.Deleting,
        ),
      )
  }
}

/// `C-y` inserts the newest kill; `M-y` replaces what the previous yank
/// inserted with the next entry in the ring.
fn yank(model: Model, rotate: Bool) -> Result {
  let index = case rotate {
    True -> model.kill_index + 1
    False -> 0
  }
  let current = editor_model.state(model)
  let main = selection.main(current.selection)
  let target = case rotate, model.last_yank {
    True, option.Some(span) -> option.Some(span)
    True, option.None -> option.None
    False, _ -> option.Some(#(selection.start(main), selection.end(main)))
  }

  case target, list.drop(model.kill_ring, index) {
    option.Some(#(from, to)), [value, ..] ->
      apply_result(
        Model(
          ..model,
          kill_index: index,
          last_yank: option.Some(#(from, from + transaction.insert_width(value))),
        ),
        transaction.new(
          [transaction.Change(from: from, to: to, insert: value)],
          transaction.Bulk,
        ),
      )
    _, _ -> idle(model)
  }
}

fn keyboard_quit(model: Model) -> Result {
  Result(
    ..idle(
      Model(
        ..model,
        emacs: emacs.set_mark(model.emacs, option.None),
        prompt: option.None,
        search: editor_model.SearchPanel(..model.search, open: False),
        status: option.None,
      ),
    ),
    command: browser_command.FocusEditor,
  )
}

/// Finish an explicit editing session as one minimal document change. This
/// retains the pre-session history and also handles native typing/paste/IME.
fn coalesce_undo(model: Model, before: state.State) -> Result {
  let current = editor_model.active_session(model)
  let next_history = case reconcile.diff(before.doc, state.text(current.state)) {
    option.None -> before.history
    option.Some(change) -> history.record(before.history,
      history.Step([change], transaction.invert(before.doc, [change])),
      before.selection, current.state.selection, transaction.Command)
  }
  idle(editor_model.put_session(model, session.Session(..current,
    state: state.State(..current.state, history: next_history))))
}

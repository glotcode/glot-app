//// The editor's reducer.
////
//// Browser events arrive here already carrying the session and generation they
//// were produced for, so anything belonging to a replaced document is dropped
//// before it can touch the state.

import gleam/int
import gleam/list
import gleam/option.{type Option}
import gleam/string
import glot_frontend/public/editor/code_editor/browser_command
import glot_frontend/public/editor/code_editor/command.{type EditorCommand}
import glot_frontend/public/editor/code_editor/document
import glot_frontend/public/editor/code_editor/execute
import glot_frontend/public/editor/code_editor/keymap/default_keymap
import glot_frontend/public/editor/code_editor/keymap/emacs
import glot_frontend/public/editor/code_editor/keymap/vim
import glot_frontend/public/editor/code_editor/keys.{type Key}
import glot_frontend/public/editor/code_editor/message.{
  type Msg, type NativeInput, type Outbound,
}
import glot_frontend/public/editor/code_editor/model.{type Model, Model} as editor_model
import glot_frontend/public/editor/code_editor/reconcile
import glot_frontend/public/editor/code_editor/search
import glot_frontend/public/editor/code_editor/selection
import glot_frontend/public/editor/code_editor/session
import glot_frontend/public/editor/code_editor/settings_bridge
import glot_frontend/public/editor/code_editor/state
import glot_frontend/public/editor/code_editor/text
import glot_frontend/public/editor/code_editor/transaction

pub type Update =
  #(Model, browser_command.Command(Msg), List(Outbound))

/// Push the active session's document and selection into the textarea.
///
/// Activating another session, or replacing a document, changes what the editor
/// shows without any message passing through the reducer, so the caller asks
/// for this command to bring the field back in step.
pub fn sync(model: Model) -> browser_command.Command(msg) {
  let current = editor_model.active_session(model)
  let main = selection.main(editor_model.browser_selection(model))
  browser_command.SyncSession(
    session_key: session.key_to_string(current.key),
    generation: current.generation,
    value: state.text(current.state),
    selection_anchor: main.anchor,
    selection_head: main.head,
    scroll_top: current.scroll_top,
    scroll_left: current.scroll_left,
  )
}

pub fn update(model: Model, msg: Msg) -> Update {
  let #(next, command, outbound) = reduce(model, msg)
  #(editor_model.refresh(next), command, outbound)
}

fn reduce(model: Model, msg: Msg) -> Update {
  case msg {
    message.KeyPressed(key, prevented) ->
      case model.composing {
        True -> unchanged(model)
        False -> key_pressed(model, key, prevented)
      }

    message.BeforeInputReceived(input_type) ->
      case input_type {
        "historyUndo" -> finish(execute.run(model, [command.Undo]))
        "historyRedo" -> finish(execute.run(model, [command.Redo]))
        _ -> unchanged(model)
      }

    message.InputReceived(native) ->
      case is_current(model, native.session, native.generation) {
        False -> unchanged(model)
        True ->
          case model.composing {
            True -> unchanged(model)
            False -> case editor_model.accepts_native_input(model) {
              True -> reconcile_input(model, native, transaction.Typing)
              False -> #(model, sync(model), [])
            }
          }
      }

    message.CompositionStarted -> unchanged(Model(..model, composing: True))

    message.CompositionEnded(native) ->
      case is_current(model, native.session, native.generation) {
        False -> unchanged(Model(..model, composing: False))
        True ->
          reconcile_input(
            Model(..model, composing: False),
            native,
            transaction.Composition,
          )
      }

    message.Pasted(native) ->
      case is_current(model, native.session, native.generation) {
        False -> unchanged(model)
        True -> reconcile_input(model, native, transaction.Bulk)
      }

    message.SelectionMoved(snapshot) ->
      case is_current(model, snapshot.session, snapshot.generation) {
        False -> unchanged(model)
        True -> selection_moved(model, snapshot)
      }

    message.Scrolled(snapshot) ->
      case session.key_to_string(model.active) == snapshot.session {
        False -> unchanged(model)
        True -> {
          let current = editor_model.active_session(model)
          unchanged(
            editor_model.put_session(
              model,
              session.Session(
                ..current,
                scroll_top: snapshot.scroll_top,
                scroll_left: snapshot.scroll_left,
              ),
            ),
          )
        }
      }

    message.Measured(line_height, height, width, char_width) ->
      unchanged(
        Model(
          ..model,
          viewport: editor_model.Viewport(
            ..model.viewport,
            line_height: int_max(1, line_height),
            height: height,
            width: width,
            char_width: int_max(1, char_width),
          ),
        ),
      )

    message.FocusChanged(focused) -> unchanged(Model(..model, focused: focused))

    message.GutterLineClicked(line) ->
      finish(
        execute.run(model, [command.MoveToLineNumber(line: line + 1, extend: False)]),
      )

    // -- Search panel
    message.SearchFieldChanged(field, value) -> {
      let query = case field {
        message.SearchTerm -> search.Query(..model.search.query, search: value)
        message.ReplacementTerm ->
          search.Query(..model.search.query, replace: value)
      }
      unchanged(
        Model(
          ..model,
          search: editor_model.SearchPanel(..model.search, query: query),
        ),
      )
    }

    message.SearchToggled(toggle) -> {
      let query = case toggle {
        message.CaseSensitive ->
          search.Query(
            ..model.search.query,
            case_sensitive: !model.search.query.case_sensitive,
          )
        message.WholeWord ->
          search.Query(
            ..model.search.query,
            whole_word: !model.search.query.whole_word,
          )
        message.RegularExpression ->
          search.Query(..model.search.query, regexp: !model.search.query.regexp)
      }
      unchanged(
        Model(
          ..model,
          search: editor_model.SearchPanel(..model.search, query: query),
        ),
      )
    }

    message.SearchNextClicked -> finish(execute.run(model, [command.FindNext]))
    message.SearchPreviousClicked ->
      finish(execute.run(model, [command.FindPrevious]))
    message.SearchReplaceClicked(all) ->
      finish(
        execute.run(model, [
          case all {
            True -> command.ReplaceAll
            False -> command.ReplaceNext
          },
        ]),
      )
    message.SearchClosed ->
      finish(execute.run(model, [command.CloseSearchPanel]))

    // -- Prompt
    message.PromptChanged(value) ->
      unchanged(
        Model(
          ..model,
          prompt: case model.prompt {
            option.Some(prompt) ->
              option.Some(editor_model.Prompt(..prompt, value: value))
            option.None -> option.None
          },
        ),
      )

    message.PromptSubmitted -> submit_prompt(model)

    message.PromptCancelled ->
      finish(
        execute.Result(
          ..execute.idle(Model(..model, prompt: option.None,
            vim: vim.Vim(..model.vim, pending: [], pending_register: option.None, search_operator: option.None, search_count: 1))),
          command: browser_command.FocusEditor,
        ),
      )
  }
}

fn unchanged(model: Model) -> Update {
  #(model, browser_command.none(), [])
}

fn finish(result: execute.Result) -> Update {
  #(result.model, result.command, result.outbound)
}

fn is_current(model: Model, key: String, generation: Int) -> Bool {
  let current = editor_model.active_session(model)
  session.key_to_string(current.key) == key && current.generation == generation
}

fn int_max(a: Int, b: Int) -> Int {
  case a > b {
    True -> a
    False -> b
  }
}

// -- Native input ------------------------------------------------------------

fn reconcile_input(
  model: Model,
  native: NativeInput,
  origin: transaction.Origin,
) -> Update {
  let current = editor_model.active_session(model)
  let caret =
    selection.Selection(
      ranges: [
        selection.range(native.selection_anchor, native.selection_head),
      ],
      primary: 0,
      rectangular: False,
    )

  case reconcile.diff(current.state.doc, native.value) {
    option.None ->
      finish(
        execute.Result(
          ..execute.idle(
            editor_model.put_session(
              model,
              session.Session(
                ..current,
                state: state.State(
                  ..current.state,
                  selection: state.clamp_selection(current.state.doc, caret),
                ),
              ),
            ),
          ),
          command: browser_command.none(),
        ),
      )
    option.Some(native_change) -> {
      let change = case model.bindings {
        settings_bridge.VimLike -> vim.native_change(model.vim, current.state, native_change)
        _ -> native_change
      }
      let tr =
        transaction.new([change], origin)
        |> transaction.with_selection(caret)
      let model = case model.bindings {
        settings_bridge.VimLike -> Model(..model, vim: vim.record_native_edit(model.vim, current.state, change))
        _ -> model
      }
      let next = execute.apply(model, tr)
      #(
        next,
        browser_command.batch([
          case change != native_change { True -> replay_snapshot(next) False -> browser_command.none() },
          browser_command.ScrollToLine(
            line: document.line_index_at(editor_model.state(next).doc, native.selection_head),
            intent: browser_command.KeepCaretVisible,
          ),
        ]),
        [message.DocumentChanged],
      )
    }
  }
}

fn selection_moved(
  model: Model,
  snapshot: message.SelectionSnapshot,
) -> Update {
  let current = editor_model.active_session(model)
  let next =
    selection.Selection(
      ranges: [
        selection.range(snapshot.selection_anchor, snapshot.selection_head),
      ],
      primary: 0,
      rectangular: False,
    )
  case selection.main(editor_model.browser_selection(model)) == selection.main(next) {
    True -> unchanged(model)
    False ->
      unchanged(
        editor_model.put_session(
          leave_visual_for_pointer(model),
          session.Session(
            ..current,
            state: state.apply(
              current.state,
              transaction.selection_only(next),
            ),
          ),
        ),
      )
  }
}

// -- Keys --------------------------------------------------------------------

/// Whether the editor will act on this key, and therefore whether the view
/// should cancel the browser's default. Browser-reserved combinations always
/// answer `False`, so they can never turn into an accidental edit.
pub fn handles_key(model: Model, key: Key) -> Bool {
  case keys.is_modifier(key), keys.is_browser_reserved(key, model.mac) {
    True, _ | _, True -> False
    False, False ->
      case run_shortcut(model, key) {
        True -> True
        False ->
          case model.tab_focus_mode && key.key == "Tab" {
            True -> False
            False -> resolves(model, key)
          }
      }
  }
}

fn run_shortcut(model: Model, key: Key) -> Bool {
  key.key == "Enter" && { key.ctrl || key.meta } && !key.alt && !key.shift
  || {
    let _ = model
    False
  }
}

fn resolves(model: Model, key: Key) -> Bool {
  case model.bindings {
    settings_bridge.VimLike ->
      case vim.accepts_native_input(model.vim) {
        // In normal and visual mode every ordinary key is a command.
        False -> True
        True -> vim_insert_binding(key) || default_binding(model, key)
      }
    settings_bridge.EmacsLike ->
      emacs_binding(model, key) || default_binding(model, key)
    settings_bridge.Plain -> default_binding(model, key)
  }
}

fn vim_insert_binding(key: Key) -> Bool {
  key.key == "Escape"
  || {
    key.ctrl
    && list.contains(["w", "u", "t", "d", "o", "c", "["], string.lowercase(key.key))
  }
}

fn emacs_binding(model: Model, key: Key) -> Bool {
  case emacs.handle(model.emacs, key, model.mac) {
    #(_, emacs.Unhandled) -> False
    _ -> True
  }
}

fn default_binding(model: Model, key: Key) -> Bool {
  case default_keymap.resolve(key, model.mac) {
    option.Some(_) -> True
    option.None -> False
  }
}

fn key_pressed(model: Model, key: Key, prevented: Bool) -> Update {
  case keys.is_modifier(key), keys.is_browser_reserved(key, model.mac) {
    True, _ | _, True -> unchanged(model)
    False, False ->
      case run_shortcut(model, key) {
        True -> finish(execute.run(model, [command.RunSnippet]))
        False -> reconcile_decision(routed(model, key), key, prevented)
      }
  }
}

/// What routing a key did: the resulting update, and whether the editor claimed
/// the key at all.
type Routed {
  Routed(result: Update, claimed: Bool)
}

/// Put right a disagreement between the view's cancellation decision and what
/// the live model does with the key. The view decides from the model as last
/// rendered, so under load the two can be a frame apart.
fn reconcile_decision(routed: Routed, key: Key, prevented: Bool) -> Update {
  let #(after, command, outbound) = routed.result

  case prevented, routed.claimed, editor_model.accepts_native_input(after) {
    // Cancelled, unclaimed, and the mode would have let the browser type it:
    // insert the character here rather than lose it.
    True, False, True ->
      case keys.is_printable(key) && !after.read_only {
        True -> {
          let current = editor_model.state(after)
          let range = selection.main(current.selection)
          let change = transaction.Change(selection.start(range), selection.end(range), key.key)
          let change = case after.bindings {
            settings_bridge.VimLike -> vim.native_change(after.vim, current, change)
            _ -> change
          }
          let after = case after.bindings {
            settings_bridge.VimLike -> Model(..after, vim: vim.record_native_edit(after.vim, current, change))
            _ -> after
          }
          let item = case after.bindings {
            settings_bridge.VimLike -> command.EditRanges([change], change.from + text.width(change.insert))
            _ -> command.InsertText(key.key)
          }
          finish(execute.run(after, [item]))
        }
        False -> routed.result
      }

    // Not cancelled, but the live mode treats keys as commands: the browser has
    // already typed the character, so the document is written back over it.
    False, _, False -> #(
      after,
      browser_command.batch([command, sync(after)]),
      outbound,
    )

    _, _, _ -> routed.result
  }
}

fn routed(model: Model, key: Key) -> Routed {
  case model.bindings {
    settings_bridge.VimLike -> vim_key(model, key)
    settings_bridge.EmacsLike -> emacs_key(model, key)
    settings_bridge.Plain -> default_key(model, key)
  }
}

fn default_key(model: Model, key: Key) -> Routed {
  case model.tab_focus_mode && key.key == "Tab" {
    True ->
      Routed(
        result: #(
          model,
          browser_command.MoveFocus(forward: !key.shift),
          [],
        ),
        claimed: True,
      )
    False ->
      case default_keymap.resolve(key, model.mac) {
        option.None -> Routed(result: unchanged(model), claimed: False)
        option.Some(item) ->
          Routed(result: finish(execute.run(model, [item])), claimed: True)
      }
  }
}

fn emacs_key(model: Model, key: Key) -> Routed {
  let #(next, response) = emacs.handle(model.emacs, key, model.mac)
  let model = Model(..model, emacs: next)
  case response {
    emacs.Unhandled -> default_key(model, key)
    emacs.Pending(label) ->
      Routed(
        result: announce_status(model, case label {
          "" -> option.None
          _ -> option.Some(label)
        }),
        claimed: True,
      )
    emacs.Handled(commands, repeat) ->
      Routed(
        result: finish(
          execute.run(
            Model(..model, status: emacs.status(next)),
            repeat_commands(commands, repeat),
          ),
        ),
        claimed: True,
      )
  }
}

fn repeat_commands(
  commands: List(EditorCommand),
  repeat: Int,
) -> List(EditorCommand) {
  case repeat <= 1 {
    True -> commands
    False -> list.append(commands, repeat_commands(commands, repeat - 1))
  }
}

fn vim_key(model: Model, key: Key) -> Routed {
  let #(next, response) = vim.handle(model.vim, editor_model.state(model), key)
  let search = case next.search_query != model.vim.search_query {
    True -> editor_model.SearchPanel(..model.search, query: next.search_query)
    False -> model.search
  }
  let model = Model(..model, vim: next, search: search, status: option.Some(vim.status(next)))
  case response {
    vim.Unhandled ->
      case vim.accepts_native_input(next) {
        True -> default_key(model, key)
        False -> Routed(result: unchanged(model), claimed: True)
      }
    vim.Pending(label) ->
      Routed(result: announce_status(model, option.Some(label)), claimed: True)
    vim.Handled(commands) -> {
      let result = execute.run(model, commands)
      let updated = case vim.accepts_native_input(next), next.insertion {
        True, option.Some(start) if !start.started ->
          Model(..result.model, vim: vim.capture_insert_start(result.model.vim, editor_model.state(result.model)))
        _, _ -> result.model
      }
      Routed(result: finish(execute.Result(..result, model: updated)), claimed: True)
    }
    vim.Prompt(kind) ->
      Routed(result: open_vim_prompt(model, kind), claimed: True)
    vim.Replay(tokens) -> {
      let #(final, command, outbound) = replay(model, tokens, 0)
      Routed(result: #(final, browser_command.batch([without_replay_snapshots(command), replay_snapshot(final)]), outbound), claimed: True)
    }
  }
}

/// Macro playback and `.` re-enter the same state machine, so a replayed
/// command sees the document each step produced. The step budget stops a macro
/// that records itself from looping.
fn replay(model: Model, tokens: List(vim.Stroke), steps: Int) -> Update {
  case tokens, steps >= 1000 {
    [], _ | _, True -> unchanged(model)
    [stroke, ..rest], False -> case stroke {
      vim.KeyStroke(token) -> {
        let #(next, response) = vim.handle(model.vim, editor_model.state(model), vim.key_from_token(token))
        case response {
          vim.Replay(nested) -> replay(Model(..model, vim: next, status: option.Some(vim.status(next))), list.append(list.take(nested, 1000 - steps), rest), steps + 1)
          _ -> replay_then(model, stroke, rest, steps)
        }
      }
      _ -> replay_then(model, stroke, rest, steps)
    }
  }
}

fn replay_then(model: Model, stroke: vim.Stroke, rest: List(vim.Stroke), steps: Int) -> Update {
  let #(next, command, outbound) = replay_stroke(model, stroke)
  let #(final, final_command, final_outbound) = replay(next, rest, steps + 1)
  #(final, browser_command.batch([command, final_command]), list.append(outbound, final_outbound))
}

fn open_vim_prompt(model: Model, kind: vim.PromptKind) -> Update {
  let prompt = case kind {
    vim.ExPrompt ->
      editor_model.Prompt(kind: editor_model.ExPrompt, label: ":", value: case model.vim.mode {
        vim.VisualMode(_) -> "'<,'>"
        _ -> ""
      })
    vim.SearchPrompt(forward) ->
      editor_model.Prompt(
        kind: editor_model.SearchPrompt(forward),
        label: case forward {
          True -> "/"
          False -> "?"
        },
        value: "",
      )
  }
  #(
    Model(..model, prompt: option.Some(prompt)),
    browser_command.FocusPrompt,
    [],
  )
}

/// Mode and prefix feedback is rendered into the editor's polite live region,
/// so it reaches assistive technology without a separate announcement channel.
fn announce_status(model: Model, status: Option(String)) -> Update {
  #(Model(..model, status: status), browser_command.none(), [])
}

// -- Prompt ------------------------------------------------------------------

fn submit_prompt(model: Model) -> Update {
  case model.prompt {
    option.None -> unchanged(model)
    option.Some(prompt) -> {
      let cleared = Model(..model, prompt: option.None)
      let result = case prompt.kind {
        editor_model.GotoLinePrompt ->
          case int.parse(string.trim(prompt.value)) {
            Ok(line) ->
              execute.run(cleared, [
                command.MoveToLineNumber(line: line, extend: False),
              ])
            Error(_) -> execute.idle(cleared)
          }

        editor_model.SearchPrompt(forward) -> execute_search(cleared, prompt.value, forward)

        editor_model.ExPrompt -> {
          let #(next_vim, commands) =
            vim.ex_command(
              cleared.vim,
              editor_model.state(cleared),
              prompt.value,
            )
          execute.run(Model(..cleared, vim: next_vim), commands)
        }

        editor_model.CommandPrompt ->
          execute.run(cleared, named_command(string.trim(prompt.value)))
      }

      finish(
        execute.Result(
          ..result,
          command: browser_command.batch([
            result.command,
            browser_command.FocusEditor,
          ]),
        ),
      )
    }
  }
}

/// Emacs' `M-x`, limited to commands the editor actually implements.
fn named_command(name: String) -> List(EditorCommand) {
  case name {
    "goto-line" -> [command.OpenGotoLinePrompt]
    "comment-region" | "comment-dwim" -> [command.ToggleComment]
    "upcase-region" -> [command.ChangeCase(to_upper: True)]
    "downcase-region" -> [command.ChangeCase(to_upper: False)]
    "upcase-word" -> [command.ChangeWordCase(to_upper: True)]
    "downcase-word" -> [command.ChangeWordCase(to_upper: False)]
    "kill-region" -> [command.KillRegion(save_only: False)]
    "kill-ring-save" -> [command.KillRegion(save_only: True)]
    "yank" -> [command.Yank]
    "yank-pop" -> [command.YankRotate]
    "undo" -> [command.Undo]
    "redo" -> [command.Redo]
    "isearch-forward" -> [command.OpenSearchPanel]
    "query-replace" -> [command.OpenSearchPanel]
    "indent-region" -> [command.IndentSelection]
    "sort-lines" -> [command.SortLines]
    "mark-whole-buffer" -> [command.SelectAll]
    "transpose-chars" -> [command.TransposeChars]
    "set-mark-command" -> [command.SetMark]
    "exchange-point-and-mark" -> [command.ExchangePointAndMark]
    "recenter-top-bottom" -> [command.RecenterTopBottom]
    "save-buffer" -> [command.SaveSnippet]
    _ -> []
  }
}

fn leave_visual_for_pointer(model: Model) -> Model {
  case model.bindings, vim.mode(model.vim) {
    settings_bridge.VimLike, vim.VisualMode(kind) -> {
      let current = editor_model.state(model)
      let next = vim.Vim(..model.vim, mode: vim.NormalMode, pending: [],
        last_visual: option.Some(#(kind, model.vim.visual_anchor, selection.head(current.selection))))
      Model(..model, vim: next, status: option.Some(vim.status(next)))
    }
    _, _ -> model
  }
}

fn replay_stroke(model: Model, stroke: vim.Stroke) -> Update {
  case stroke {
    vim.KeyStroke(token) -> vim_key(model, vim.key_from_token(token)).result
    vim.SearchStroke(pattern, forward) -> finish(execute_search(Model(..model, prompt: option.None), pattern, forward))
    vim.VisualStroke(kind, lines, columns) -> {
      let #(next, commands) = vim.replay_visual(model.vim, editor_model.state(model), kind, lines, columns)
      finish(execute.run(Model(..model, vim: next, status: option.Some(vim.status(next))), commands))
    }
    vim.EditStroke(from_delta, to_delta, insert) -> {
      let current = editor_model.state(model)
      let caret = selection.head(current.selection)
      let change = transaction.Change(caret + from_delta, caret + to_delta, insert)
      let change = vim.native_change(model.vim, current, change)
      let next = Model(..model, vim: vim.record_native_edit(model.vim, current, change))
      finish(execute.run(next, [command.EditRanges([change], change.from + text.width(insert))]))
    }
  }
}


/// Intermediate replay states belong to the reducer, not the native textarea.
fn without_replay_snapshots(command: browser_command.Command(msg)) -> browser_command.Command(msg) {
  case command {
    browser_command.Batch(commands) -> browser_command.batch(list.map(commands, without_replay_snapshots))
    browser_command.SyncDocument(..) | browser_command.SyncSelection(..)
    | browser_command.ScrollToLine(_, browser_command.KeepCaretVisible) -> browser_command.none()
    _ -> command
  }
}


fn replay_snapshot(model: Model) -> browser_command.Command(msg) {
  let current = editor_model.state(model)
  let range = selection.main(editor_model.browser_selection(model))
  browser_command.batch([
    browser_command.SyncDocument(state.text(current), range.anchor, range.head),
    browser_command.ScrollToLine(document.line_index_at(current.doc, selection.head(current.selection)), browser_command.KeepCaretVisible),
  ])
}


fn execute_search(model: Model, pattern: String, forward: Bool) -> execute.Result {
  let #(next_vim, commands) = vim.submit_search(model.vim, editor_model.state(model), pattern, forward)
  let result = execute.run(Model(..model, vim: next_vim,
    search: editor_model.SearchPanel(..model.search, query: next_vim.search_query)), commands)
  let next = case result.model.vim.insertion {
    option.Some(start) if !start.started -> Model(..result.model, vim: vim.capture_insert_start(result.model.vim, editor_model.state(result.model)))
    _ -> result.model
  }
  execute.Result(..result, model: next,
    command: browser_command.batch([result.command, browser_command.FocusEditor]))
}

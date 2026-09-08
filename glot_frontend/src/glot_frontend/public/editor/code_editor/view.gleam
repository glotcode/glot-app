//// The editor's presentation.
////
//// A native `textarea` holds the whole document and owns focus, the caret,
//// native selection, touch selection, and IME. A highlighting layer behind it
//// renders only the visible lines, with overscan, using the same typography, so
//// the two stay aligned without soft wrapping.

import gleam/dynamic/decode.{type Decoder}
import gleam/float
import gleam/int
import gleam/list
import gleam/option
import gleam/string
import glot_frontend/public/editor/code_editor/document
import glot_frontend/public/editor/code_editor/highlight_state
import glot_frontend/public/editor/code_editor/ids
import glot_frontend/public/editor/code_editor/keys.{type Key}
import glot_frontend/public/editor/code_editor/message.{type Msg}
import glot_frontend/public/editor/code_editor/model.{type Model} as editor_model
import glot_frontend/public/editor/code_editor/movement
import glot_frontend/public/editor/code_editor/search
import glot_frontend/public/editor/code_editor/selection
import glot_frontend/public/editor/code_editor/session
import glot_frontend/public/editor/code_editor/settings_bridge
import glot_frontend/public/editor/code_editor/syntax/token
import glot_frontend/public/editor/code_editor/text
import glot_frontend/public/editor/code_editor/update
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn view(model: Model) -> Element(Msg) {
  let current = editor_model.active_session(model)
  html.div(
    [
      attribute.class("code-editor"),
      attribute.style(
        "--code-editor-gutter-digits",
        int.to_string(gutter_digits(document.line_count(current.state.doc))),
      ),
      attribute.attribute("data-bindings", binding_name(model)),
    ],
    [
      search_panel(model),
      prompt(model),
      html.div([attribute.class("code-editor__frame")], [
        gutter(model),
        area(model),
      ]),
      status_line(model),
    ],
  )
}

fn binding_name(model: Model) -> String {
  case model.bindings {
    settings_bridge.Plain -> "default"
    settings_bridge.EmacsLike -> "emacs"
    settings_bridge.VimLike -> "vim"
  }
}

// -- Gutter ------------------------------------------------------------------

fn gutter(model: Model) -> Element(Msg) {
  let current = editor_model.active_session(model)
  let caret_line =
    document.line_index_at(
      current.state.doc,
      selection.head(current.state.selection),
    )

  html.div(
    [
      attribute.class("code-editor__gutter"),
      attribute.attribute("aria-hidden", "true"),
    ],
    [
      html.div(
        [
          attribute.class("code-editor__gutter-inner"),
          attribute.style("transform", translate(0, layer_offset(model))),
        ],
        list.map(model.rendered, fn(line) {
          html.button(
            [
              attribute.class(case line.index == caret_line {
                True ->
                  "code-editor__line-number code-editor__line-number--active"
                False -> "code-editor__line-number"
              }),
              attribute.attribute("type", "button"),
              attribute.attribute("tabindex", "-1"),
              attribute.style("height", pixels(model.viewport.line_height)),
              event.on_click(message.GutterLineClicked(line.index)),
            ],
            [html.text(int.to_string(line.index + 1))],
          )
        }),
      ),
    ],
  )
}

/// The gutter is sized from the document's line count so that it does not
/// resize as the rendered window scrolls, and so that the server, which renders
/// every line, and the browser, which renders only the visible ones, agree on
/// where the code starts. `glot_web/page/editor` computes the same value for the
/// server-rendered markup.
fn gutter_digits(line_count: Int) -> Int {
  int.max(2, string.length(int.to_string(line_count)))
}

fn layer_offset(model: Model) -> Int {
  let current = editor_model.active_session(model)
  model.rendered_from * model.viewport.line_height - current.scroll_top
}

fn translate(x: Int, y: Int) -> String {
  "translate(" <> pixels(x) <> ", " <> pixels(y) <> ")"
}

fn pixels(value: Int) -> String {
  int.to_string(value) <> "px"
}

// -- Editing area ------------------------------------------------------------

fn area(model: Model) -> Element(Msg) {
  html.div([attribute.class("code-editor__area")], [
    highlight_layer(model),
    input(model),
  ])
}

fn highlight_layer(model: Model) -> Element(Msg) {
  let current = editor_model.active_session(model)

  html.div(
    [
      attribute.class("code-editor__layer"),
      attribute.attribute("aria-hidden", "true"),
    ],
    [
      html.div(
        [
          attribute.class("code-editor__lines"),
          attribute.style(
            "transform",
            translate(-current.scroll_left, layer_offset(model)),
          ),
        ],
        list.append(decorations(model), list.map(model.rendered, rendered_line(
          model,
          _,
        ))),
      ),
    ],
  )
}

fn rendered_line(
  model: Model,
  line: highlight_state.HighlightedLine,
) -> Element(Msg) {
  let current = editor_model.active_session(model)
  let character_width = int.max(1, model.viewport.char_width)
  let first_column = int.max(0, current.scroll_left / character_width - 20)
  let last_column = { current.scroll_left + model.viewport.width } / character_width + 20
  html.div(
    [
      attribute.class("code-editor__line"),
      attribute.style("height", pixels(model.viewport.line_height)),
    ],
    case line.tokens {
      [] -> [html.text(" ")]
      tokens ->
        highlight_state.viewport_segments(line.text, tokens, first_column, last_column)
        |> list.map(fn(segment) {
          let #(kind, value) = segment
          html.span([attribute.class(token.class_name(kind))], [html.text(value)])
        })
    },
  )
}

/// Active line, search and selection matches, the matching bracket, and the
/// rectangular-selection outline.
fn decorations(model: Model) -> List(Element(Msg)) {
  let current = editor_model.active_session(model)
  let doc = current.state.doc
  let head = selection.head(current.state.selection)
  let caret_line = document.line_index_at(doc, head)
  let #(first, last) = editor_model.visible_range(model)

  let active = case caret_line >= first && caret_line < last {
    True -> [
      html.div(
        [
          attribute.class("code-editor__active-line"),
          attribute.style("top", pixels({ caret_line - first } * model.viewport.line_height)),
          attribute.style("height", pixels(model.viewport.line_height)),
        ],
        [],
      ),
    ]
    False -> []
  }

  let matches =
    match_query(model)
    |> list.map(fn(query) {
      search.matches_in_lines(doc, query, first, last)
    })
    |> list.flatten
    |> list.map(fn(span) { span_decoration(model, span, "code-editor__match") })

  let bracket = case movement.matching_bracket(doc, head) {
    option.Some(target) -> [
      span_decoration(
        model,
        #(target, movement.next_offset(doc, target)),
        "code-editor__bracket",
      ),
    ]
    option.None -> []
  }

  let rectangle = case current.state.selection.rectangular {
    True -> [
      span_decoration(
        model,
        #(
          selection.start(selection.main(current.state.selection)),
          selection.end(selection.main(current.state.selection)),
        ),
        "code-editor__rectangle",
      ),
    ]
    False -> []
  }

  list.flatten([active, matches, bracket, rectangle])
}

/// The query used for match highlighting: the search panel's when it is open,
/// otherwise the selected word, which is what `highlightSelectionMatches` did.
fn match_query(model: Model) -> List(search.Query) {
  let current = editor_model.active_session(model)
  let main = selection.main(current.state.selection)
  case model.search.open, selection.is_empty(main) {
    True, _ ->
      case search.is_usable(model.search.query) {
        True -> [model.search.query]
        False -> []
      }
    False, False -> {
      let selected =
        document.slice(
          current.state.doc,
          selection.start(main),
          selection.end(main),
        )
      case string.contains(selected, "\n") || string.trim(selected) == "" {
        True -> []
        False -> [search.Query(..search.empty_query(), search: selected)]
      }
    }
    False, True -> []
  }
}

fn span_decoration(
  model: Model,
  span: #(Int, Int),
  class_name: String,
) -> Element(Msg) {
  let current = editor_model.active_session(model)
  let doc = current.state.doc
  let #(from, to) = span
  let line = document.line_index_at(doc, from)
  let start_column = movement.column_at(doc, from)
  let end_column = movement.column_at(doc, to)
  let #(first, _) = editor_model.visible_range(model)

  html.div(
    [
      attribute.class(class_name),
      attribute.style("top", pixels({ line - first } * model.viewport.line_height)),
      attribute.style("height", pixels(model.viewport.line_height)),
      attribute.style("left", pixels(start_column * model.viewport.char_width)),
      attribute.style(
        "width",
        pixels(int_max(1, end_column - start_column) * model.viewport.char_width),
      ),
    ],
    [],
  )
}

fn int_max(a: Int, b: Int) -> Int {
  case a > b {
    True -> a
    False -> b
  }
}

// -- Textarea ----------------------------------------------------------------

fn input(model: Model) -> Element(Msg) {
  let current = editor_model.active_session(model)

  element.element(
    "textarea",
    [
      attribute.id(ids.input),
      attribute.class("code-editor__input"),
      attribute.attribute("wrap", "off"),
      attribute.attribute("spellcheck", "false"),
      attribute.attribute("autocapitalize", "off"),
      attribute.attribute("autocorrect", "off"),
      attribute.attribute("autocomplete", "off"),
      attribute.attribute("aria-label", "Code editor"),
      attribute.attribute("aria-multiline", "true"),
      attribute.attribute("aria-describedby", ids.status),
      attribute.attribute(
        "data-session",
        session.key_to_string(current.key),
      ),
      attribute.attribute("data-generation", int.to_string(current.generation)),
      attribute.attribute("data-line-height", int.to_string(model.viewport.line_height)),
      attribute.readonly(model.read_only),
      event.advanced("keydown", keydown_handler(model)),
      event.advanced("beforeinput", beforeinput_handler()),
      event.on("input", decode.map(native_decoder(), message.InputReceived)),
      event.on("paste", decode.map(native_decoder(), message.Pasted)),
      event.on("compositionstart", decode.success(message.CompositionStarted)),
      event.on(
        "compositionend",
        decode.map(native_decoder(), message.CompositionEnded),
      ),
      event.on("select", decode.map(selection_decoder(), message.SelectionMoved)),
      event.on("click", decode.map(selection_decoder(), message.SelectionMoved)),
      event.on("keyup", decode.map(selection_decoder(), message.SelectionMoved)),
      event.on("scroll", decode.map(scroll_decoder(), message.Scrolled)),
      event.on("focus", decode.success(message.FocusChanged(True))),
      event.on("blur", decode.success(message.FocusChanged(False))),
    ],
    // Use a plain element: html.textarea adds a controlled value property,
    // which Lustre reapplies after events and overwrites pending IME text.
    // Content initializes the field; SyncDocument owns subsequent value writes.
    [html.text(model.initial_content)],
  )
}

fn keydown_handler(model: Model) -> Decoder(event.Handler(Msg)) {
  use composing <- decode.field("isComposing", decode.bool)
  use key_code <- decode.field("keyCode", decode.int)
  use _ <- decode.then(case composing || key_code == 229 || model.composing {
    True -> decode.failure(Nil, "NonCompositionKey")
    False -> decode.success(Nil)
  })
  decode.then(key_decoder(), fn(key) {
    let prevented = update.handles_key(model, key)
    decode.success(event.handler(
      dispatch: message.KeyPressed(key, prevented),
      prevent_default: prevented,
      stop_propagation: False,
    ))
  })
}

/// The browser's own undo stack must never fight the editor's, so the two
/// history input types are cancelled and routed through our history instead.
fn beforeinput_handler() -> Decoder(event.Handler(Msg)) {
  use input_type <- decode.then(decode.at(["inputType"], decode.string))
  use _ <- decode.then(case input_type {
    "historyUndo" | "historyRedo" -> decode.success(Nil)
    // The input event carries the completed native edit. Avoid re-lexing and
    // rendering the unchanged document before every keystroke.
    _ -> decode.failure(Nil, "NativeInput")
  })
  decode.success(event.handler(
    dispatch: message.BeforeInputReceived(input_type),
    prevent_default: True,
    stop_propagation: False,
  ))
}

fn key_decoder() -> Decoder(Key) {
  use key <- decode.field("key", decode.string)
  use ctrl <- decode.field("ctrlKey", decode.bool)
  use alt <- decode.field("altKey", decode.bool)
  use shift <- decode.field("shiftKey", decode.bool)
  use meta <- decode.field("metaKey", decode.bool)
  decode.success(keys.Key(key: key, ctrl: ctrl, alt: alt, shift: shift, meta: meta))
}

fn native_decoder() -> Decoder(message.NativeInput) {
  use value <- decode.subfield(["target", "value"], decode.string)
  use start <- decode.subfield(["target", "selectionStart"], decode.int)
  use end <- decode.subfield(["target", "selectionEnd"], decode.int)
  use direction <- decode.subfield(["target", "selectionDirection"], decode.string)
  use key <- decode.subfield(
    ["target", "dataset", "session"],
    decode.string,
  )
  use generation <- decode.subfield(
    ["target", "dataset", "generation"],
    decode.string,
  )
  decode.success(message.NativeInput(
    session: key,
    generation: parse_int(generation),
    value: value,
    selection_anchor: case direction {
      "backward" -> end
      _ -> start
    },
    selection_head: case direction {
      "backward" -> start
      _ -> end
    },
  ))
}

fn selection_decoder() -> Decoder(message.SelectionSnapshot) {
  use start <- decode.subfield(["target", "selectionStart"], decode.int)
  use end <- decode.subfield(["target", "selectionEnd"], decode.int)
  use direction <- decode.subfield(["target", "selectionDirection"], decode.string)
  use key <- decode.subfield(["target", "dataset", "session"], decode.string)
  use generation <- decode.subfield(
    ["target", "dataset", "generation"],
    decode.string,
  )
  decode.success(message.SelectionSnapshot(
    session: key,
    generation: parse_int(generation),
    selection_anchor: case direction {
      "backward" -> end
      _ -> start
    },
    selection_head: case direction {
      "backward" -> start
      _ -> end
    },
  ))
}

fn scroll_decoder() -> Decoder(message.ScrollSnapshot) {
  use top <- decode.subfield(["target", "scrollTop"], decode.float)
  use left <- decode.subfield(["target", "scrollLeft"], decode.float)
  use key <- decode.subfield(["target", "dataset", "session"], decode.string)
  decode.success(message.ScrollSnapshot(
    session: key,
    scroll_top: float_to_int(top),
    scroll_left: float_to_int(left),
  ))
}

fn parse_int(value: String) -> Int {
  case int.parse(value) {
    Ok(parsed) -> parsed
    Error(_) -> 0
  }
}

fn float_to_int(value: Float) -> Int {
  case value <. 0.0 {
    True -> 0
    False -> float.truncate(value)
  }
}

// -- Panels ------------------------------------------------------------------

fn search_panel(model: Model) -> Element(Msg) {
  case model.search.open {
    False -> element.none()
    True -> {
      let current = editor_model.active_session(model)
      let total = search.count(current.state.doc, model.search.query)

      html.div(
        [
          attribute.id(ids.search_panel),
          attribute.class("code-editor__panel"),
          attribute.attribute("role", "search"),
          attribute.attribute("aria-label", "Find in code"),
        ],
        [
          html.label([attribute.for(ids.search_field)], [html.text("Find")]),
          html.input([
            attribute.id(ids.search_field),
            attribute.type_("text"),
            attribute.value(model.search.query.search),
            event.on_input(message.SearchFieldChanged(message.SearchTerm, _)),
          ]),
          html.label([attribute.for(ids.replace_field)], [html.text("Replace")]),
          html.input([
            attribute.id(ids.replace_field),
            attribute.type_("text"),
            attribute.value(model.search.query.replace),
            event.on_input(message.SearchFieldChanged(
              message.ReplacementTerm,
              _,
            )),
          ]),
          toggle("Match case", model.search.query.case_sensitive, message.CaseSensitive),
          toggle("Whole word", model.search.query.whole_word, message.WholeWord),
          toggle(
            "Regular expression",
            model.search.query.regexp,
            message.RegularExpression,
          ),
          html.span([attribute.class("code-editor__panel-count")], [
            html.text(int.to_string(total) <> " matches"),
          ]),
          panel_button("Previous", message.SearchPreviousClicked),
          panel_button("Next", message.SearchNextClicked),
          panel_button("Replace", message.SearchReplaceClicked(False)),
          panel_button("Replace all", message.SearchReplaceClicked(True)),
          panel_button("Close", message.SearchClosed),
        ],
      )
    }
  }
}

fn toggle(label: String, checked: Bool, toggle_msg: message.SearchToggle) -> Element(Msg) {
  html.label([attribute.class("code-editor__panel-toggle")], [
    html.input([
      attribute.type_("checkbox"),
      attribute.checked(checked),
      event.on_check(fn(_) { message.SearchToggled(toggle_msg) }),
    ]),
    html.text(label),
  ])
}

fn panel_button(label: String, msg: Msg) -> Element(Msg) {
  html.button(
    [attribute.attribute("type", "button"), event.on_click(msg)],
    [html.text(label)],
  )
}

fn prompt(model: Model) -> Element(Msg) {
  case model.prompt {
    option.None -> element.none()
    option.Some(current) ->
      html.div(
        [
          attribute.class("code-editor__prompt"),
          attribute.attribute("role", "dialog"),
          attribute.attribute("aria-label", "Editor command"),
        ],
        [
          html.label([attribute.for(ids.prompt_field)], [
            html.text(current.label),
          ]),
          html.input([
            attribute.id(ids.prompt_field),
            attribute.type_("text"),
            attribute.value(current.value),
            event.on_input(message.PromptChanged),
            event.advanced("keydown", prompt_key_handler()),
          ]),
          panel_button("Cancel", message.PromptCancelled),
        ],
      )
  }
}

fn prompt_key_handler() -> Decoder(event.Handler(Msg)) {
  decode.then(decode.at(["key"], decode.string), fn(key) {
    case key {
      "Enter" ->
        decode.success(event.handler(
          dispatch: message.PromptSubmitted,
          prevent_default: True,
          stop_propagation: True,
        ))
      "Escape" ->
        decode.success(event.handler(
          dispatch: message.PromptCancelled,
          prevent_default: True,
          stop_propagation: True,
        ))
      _ ->
        decode.failure(
          event.handler(
            dispatch: message.PromptCancelled,
            prevent_default: False,
            stop_propagation: False,
          ),
          "PromptKey",
        )
    }
  })
}

// -- Status ------------------------------------------------------------------

fn status_line(model: Model) -> Element(Msg) {
  let current = editor_model.active_session(model)
  let head = selection.head(current.state.selection)
  let position = document.position_at(current.state.doc, head)

  html.div(
    [
      attribute.id(ids.status),
      attribute.class("code-editor__status"),
      attribute.attribute("role", "status"),
      attribute.attribute("aria-live", "polite"),
    ],
    [
      html.span([attribute.class("code-editor__status-mode")], [
        html.text(mode_label(model)),
      ]),
      html.span([attribute.class("code-editor__status-position")], [
        html.text(
          "Line "
          <> int.to_string(position.line + 1)
          <> ", column "
          <> int.to_string(text.cluster_index(
            document.line_text(current.state.doc, position.line),
            position.column,
          ) + 1),
        ),
      ]),
      html.span([attribute.class("code-editor__status-hint")], [
        html.text(tab_hint(model)),
      ]),
    ],
  )
}

fn mode_label(model: Model) -> String {
  case model.status {
    option.Some(label) -> label
    option.None ->
      case model.bindings {
        settings_bridge.Plain -> "Editor"
        settings_bridge.EmacsLike -> "Emacs"
        settings_bridge.VimLike -> "Vim"
      }
  }
}

fn tab_hint(model: Model) -> String {
  case model.tab_focus_mode {
    True -> "Tab moves focus (Ctrl-M to indent)"
    False -> "Tab indents (Ctrl-M or Escape then Tab to leave)"
  }
}

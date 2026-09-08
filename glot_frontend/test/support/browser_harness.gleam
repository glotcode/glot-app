//// A standalone page that mounts the code editor for the browser integration
//// tests.
////
//// It is deliberately small but complete: several files with their own
//// sessions, stdin, a read-only toggle, a theme toggle, and Run and Save
//// buttons that record the text the editor reported. Everything runs through
//// the production reducer, interpreter, and ports, so the tests exercise the
//// real browser interop rather than a stub.

import gleam/int
import gleam/list
import gleam/option
import glot_core/language
import glot_frontend/platform/user_agent
import glot_frontend/public/editor/code_editor/browser_command
import glot_frontend/public/editor/code_editor/interpreter
import glot_frontend/public/editor/code_editor/message as editor_message
import glot_frontend/public/editor/code_editor/model as editor_model
import glot_frontend/public/editor/code_editor/production_ports
import glot_frontend/public/editor/code_editor/session
import glot_frontend/public/editor/code_editor/settings_bridge
import glot_frontend/public/editor/code_editor/update as editor_update
import glot_frontend/public/editor/code_editor/view as editor_view
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub type Model {
  Model(
    editor: editor_model.Model,
    tab: Int,
    ran: option.Option(String),
    saved: option.Option(String),
    changes: Int,
  )
}

pub type Msg {
  Editor(editor_message.Msg)
  TabSelected(Int)
  ReadOnlyToggled
}

const first_source = "// first file
function greet(name) {
  const parts = [\"hello\", name];
  return parts.join(\" \");
}
"

const second_source = "// second file
const answer = 42;
"

pub fn main(bindings: String) -> Nil {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#editor", bindings)
  Nil
}

fn init(bindings: String) -> #(Model, Effect(Msg)) {
  let editor =
    editor_model.new(
      session.file_key(0),
      first_source,
      language.JavaScript,
      False,
      binding_mode(bindings),
      // The same detection production uses, so `Mod` lands on the same key.
      user_agent.is_mac(),
    )
    |> editor_model.open_session(session.file_key(1), second_source)
    |> editor_model.open_session(session.stdin_key(), "stdin text\n")
    |> open_extra_files

  #(
    Model(
      editor: editor,
      tab: 0,
      ran: option.None,
      saved: option.None,
      changes: 0,
    ),
    run_editor(browser_command.Measure(editor_message.Measured)),
  )
}

fn open_extra_files(editor: editor_model.Model) -> editor_model.Model {
  list.fold([3, 4, 5, 6, 7], editor, fn(current, index) {
    editor_model.open_session(
      current,
      session.file_key(index),
      "// file " <> int.to_string(index) <> "\n",
    )
  })
}

fn binding_mode(name: String) -> settings_bridge.BindingMode {
  case name {
    "vim" -> settings_bridge.VimLike
    "emacs" -> settings_bridge.EmacsLike
    _ -> settings_bridge.Plain
  }
}

fn run_editor(command: browser_command.Command(editor_message.Msg)) -> Effect(Msg) {
  interpreter.run(command, production_ports.ports())
  |> effect.map(Editor)
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    Editor(inner) -> {
      let #(next, command, outbound) = editor_update.update(model.editor, inner)
      let updated =
        list.fold(
          outbound,
          Model(..model, editor: next),
          fn(current, event) {
            case event {
              editor_message.DocumentChanged ->
                Model(..current, changes: current.changes + 1)
              editor_message.RunRequested ->
                Model(..current, ran: option.Some(editor_model.text(next)))
              editor_message.SaveRequested ->
                Model(..current, saved: option.Some(editor_model.text(next)))
            }
          },
        )
      #(updated, run_editor(command))
    }

    TabSelected(index) -> {
      let next = editor_model.activate(model.editor, key_for(index))
      #(
        Model(..model, tab: index, editor: next),
        run_editor(editor_update.sync(next)),
      )
    }

    ReadOnlyToggled -> #(
      Model(
        ..model,
        editor: editor_model.set_read_only(
          model.editor,
          !model.editor.read_only,
        ),
      ),
      effect.none(),
    )
  }
}

fn key_for(index: Int) -> session.Key {
  case index {
    2 -> session.stdin_key()
    other -> session.file_key(other)
  }
}

fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("harness")], [
    html.div([attribute.id("harness-controls")], [
      tab_button(0, "first.js"),
      tab_button(1, "second.js"),
      tab_button(2, "stdin"),
      tab_button(3, "third.js"),
      tab_button(4, "fourth.js"),
      tab_button(5, "fifth.js"),
      tab_button(6, "sixth.js"),
      tab_button(7, "seventh.js"),
      html.button(
        [
          attribute.id("harness-read-only"),
          attribute.attribute("type", "button"),
          event.on_click(ReadOnlyToggled),
        ],
        [html.text("Toggle read only")],
      ),
    ]),
    html.div([attribute.id("harness-editor")], [
      editor_view.view(model.editor) |> element.map(Editor),
    ]),
    html.button(
      [
        attribute.id("harness-after"),
        attribute.attribute("type", "button"),
      ],
      [html.text("after the editor")],
    ),
    html.div([attribute.id("harness-state")], [
      readout("harness-text", editor_model.text(model.editor)),
      readout("harness-ran", option.unwrap(model.ran, "")),
      readout("harness-saved", option.unwrap(model.saved, "")),
      readout("harness-changes", int.to_string(model.changes)),
    ]),
  ])
}

fn tab_button(index: Int, label: String) -> Element(Msg) {
  html.button(
    [
      attribute.id("harness-tab-" <> int.to_string(index)),
      attribute.attribute("type", "button"),
      event.on_click(TabSelected(index)),
    ],
    [html.text(label)],
  )
}

fn readout(id: String, value: String) -> Element(Msg) {
  html.pre([attribute.id(id)], [html.text(value)])
}

import gleam/list
import gleam/option
import glot_core/language
import glot_frontend/public/editor/environment
import glot_frontend/public/editor/command
import glot_frontend/public/editor/message
import glot_frontend/public/editor/model
import glot_frontend/public/editor/operations
import glot_frontend/public/editor/quick_actions
import glot_frontend/public/editor/ready
import glot_frontend/public/editor/update
import glot_web/page/top_bar

pub fn execution_quick_action_follows_cancellation_availability_test() {
  let editor = ready.new(language.JavaScript, environment.defaults())
  let idle_actions = actions(editor)
  assert list.contains(labels(idle_actions), "Run code")
  assert !list.contains(labels(idle_actions), "Cancel run")

  let #(running_operations, generation) =
    operations.begin_execution(editor.operations)
  let running = model.Editor(..editor, operations: running_operations)
  let running_labels = labels(actions(running))
  assert !list.contains(running_labels, "Run code")
  assert list.contains(running_labels, "Cancel run")

  let assert option.Some(cancellable_operations) =
    operations.offer_execution_cancellation(running_operations, generation)
  let cancellable = model.Editor(..editor, operations: cancellable_operations)
  let cancellable_actions = actions(cancellable)
  assert !list.contains(labels(cancellable_actions), "Run code")
  let assert Ok(top_bar.Action(msg:, ..)) =
    list.find(cancellable_actions, fn(action) { action.label == "Cancel run" })
  assert msg
    == message.Editor(message.Execution(message.RunCancellationSubmitted))
}

pub fn plaintext_exposes_information_and_unfocus_actions_test() {
  let base = ready.new(language.Plaintext, environment.defaults())
  let editor =
    model.Editor(
      ..base,
      snippet: model.Snippet(..base.snippet, slug: option.Some("legacy")),
    )

  assert labels(actions(editor)) == ["Snippet info", "Unfocus editor"]
}

pub fn unfocus_action_blurs_the_editor_without_changing_it_test() {
  let editor = ready.new(language.JavaScript, environment.defaults())
  let editor_actions = actions(editor)
  let assert Ok(top_bar.Action(msg: message.Editor(msg), ..)) =
    list.find(editor_actions, fn(action) { action.label == "Unfocus editor" })

  assert update.update(editor, msg, option.None)
    == #(editor, command.Blur("code-editor-input"))
}

fn actions(editor: model.Editor) -> List(top_bar.Action(message.Msg)) {
  quick_actions.actions(model.Ready(editor), option.None)
}

fn labels(actions: List(top_bar.Action(msg))) -> List(String) {
  list.map(actions, fn(action) { action.label })
}

import gleam/list
import gleam/option
import glot_frontend/public/editor/message.{
  type EditorMsg, type Msg, AddEntryClicked, EditMetadataClicked,
  Editor as EditorMessage, Execution, File, Metadata, RunCancellationSubmitted,
  RunSubmitted, Save, SaveClicked, Settings, SettingsClicked, SnippetInfo,
  SnippetInfoClicked,
}
import glot_frontend/public/editor/model.{
  type Editor, type Model, Lifecycle, Ready,
}
import glot_frontend/public/editor/operations
import glot_frontend/public/editor/policy
import glot_web/page/top_bar
import youid/uuid.{type Uuid}

pub fn actions(
  model: Model,
  current_user_id: option.Option(Uuid),
) -> List(top_bar.Action(Msg)) {
  case model {
    Ready(model) ->
      actions_for_model(model, current_user_id)
      |> list.map(fn(action) { top_bar.map_action(action, EditorMessage) })
    Lifecycle(_) -> []
  }
}

fn actions_for_model(
  model: Editor,
  current_user_id: option.Option(Uuid),
) -> List(top_bar.Action(EditorMsg)) {
  let execution_actions = case
    operations.execution_is_running(model.operations)
  {
    True -> [
      top_bar.Action(
        label: "Cancel run",
        description: "Stop the current snippet run.",
        shortcut: [],
        target_route: option.None,
        msg: Execution(RunCancellationSubmitted),
      ),
    ]
    False -> [
      top_bar.Action(
        label: "Run code",
        description: "Execute the current snippet.",
        shortcut: ["cmd+enter", "ctrl+enter"],
        target_route: option.None,
        msg: Execution(RunSubmitted),
      ),
    ]
  }

  let base_actions = [
    top_bar.Action(
      label: policy.action_name(model, current_user_id),
      description: "Save the current snippet state.",
      shortcut: [],
      target_route: option.None,
      msg: Save(SaveClicked),
    ),
    top_bar.Action(
      label: "New file",
      description: "Add a new file or stdin input entry.",
      shortcut: [],
      target_route: option.None,
      msg: File(AddEntryClicked),
    ),
    top_bar.Action(
      label: "Settings",
      description: "Open editor settings.",
      shortcut: [],
      target_route: option.None,
      msg: Settings(SettingsClicked),
    ),
  ]

  let info_actions = case model.snippet.slug != option.None {
    True -> [
      top_bar.Action(
        label: "Snippet info",
        description: "View snippet metadata.",
        shortcut: [],
        target_route: option.None,
        msg: SnippetInfo(SnippetInfoClicked),
      ),
    ]
    False -> []
  }

  let title_actions = case
    model.snippet.slug == option.None || policy.is_owner(model, current_user_id)
  {
    True -> [
      top_bar.Action(
        label: "Edit metadata",
        description: "Edit the current snippet's metadata.",
        shortcut: [],
        target_route: option.None,
        msg: Metadata(EditMetadataClicked),
      ),
    ]
    False -> []
  }

  execution_actions
  |> list.append(base_actions)
  |> list.append(info_actions)
  |> list.append(title_actions)
}

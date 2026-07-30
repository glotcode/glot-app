import gleam/list
import gleam/option
import glot_frontend/public/editor/message.{
  type Msg, AddEntryClicked, EditMetadataClicked, RunSubmitted, SaveClicked,
  SettingsClicked, SnippetInfoClicked,
}
import glot_frontend/public/editor/model.{
  type Model, type RealModel, Initializing, LoadError, LoadingSnippet,
  SupportedLanguage, UnsupportedLanguage,
}
import glot_frontend/public/editor/policy
import glot_web/page/top_bar
import youid/uuid.{type Uuid}

pub fn actions(
  model: Model,
  current_user_id: option.Option(Uuid),
) -> List(top_bar.Action(Msg)) {
  case model {
    SupportedLanguage(model) -> actions_for_model(model, current_user_id)
    Initializing(_)
    | UnsupportedLanguage(_)
    | LoadingSnippet(_, _, _)
    | LoadError(_) -> []
  }
}

fn actions_for_model(
  model: RealModel,
  current_user_id: option.Option(Uuid),
) -> List(top_bar.Action(Msg)) {
  let base_actions = [
    top_bar.Action(
      label: "Run code",
      description: "Execute the current snippet.",
      shortcut: ["cmd+enter", "ctrl+enter"],
      target_route: option.None,
      msg: RunSubmitted,
    ),
    top_bar.Action(
      label: policy.action_name(model, current_user_id),
      description: "Save the current snippet state.",
      shortcut: [],
      target_route: option.None,
      msg: SaveClicked,
    ),
    top_bar.Action(
      label: "New file",
      description: "Add a new file or stdin input entry.",
      shortcut: [],
      target_route: option.None,
      msg: AddEntryClicked,
    ),
    top_bar.Action(
      label: "Settings",
      description: "Open editor settings.",
      shortcut: [],
      target_route: option.None,
      msg: SettingsClicked,
    ),
  ]

  let info_actions = case model.slug != option.None {
    True -> [
      top_bar.Action(
        label: "Snippet info",
        description: "View snippet metadata.",
        shortcut: [],
        target_route: option.None,
        msg: SnippetInfoClicked,
      ),
    ]
    False -> []
  }

  let title_actions = case
    model.slug == option.None || policy.is_owner(model, current_user_id)
  {
    True -> [
      top_bar.Action(
        label: "Edit metadata",
        description: "Edit the current snippet's metadata.",
        shortcut: [],
        target_route: option.None,
        msg: EditMetadataClicked,
      ),
    ]
    False -> []
  }

  base_actions
  |> list.append(info_actions)
  |> list.append(title_actions)
}

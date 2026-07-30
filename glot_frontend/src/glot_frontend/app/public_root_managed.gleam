import gleam/list
import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_core/route
import glot_frontend/app/event
import glot_frontend/app/public_managed
import glot_frontend/app/public_page_actions
import glot_frontend/app/public_page_command
import glot_frontend/app/public_page_managed
import glot_frontend/app/public_page_message
import glot_frontend/app/public_page_state
import glot_frontend/app/public_quick_actions
import glot_frontend/app/quick_actions
import glot_frontend/app/quick_actions_managed
import glot_frontend/app/runtime
import glot_frontend/public/editor/message as editor_message
import glot_web/page/top_bar

pub type Model {
  Model(
    lifecycle: public_managed.Model(public_page_state.Model),
    quick_actions: quick_actions.Model,
  )
}

pub type QuickActionTarget {
  NavigateTo(route.Route)
  TriggerPageAction(public_page_message.Msg)
}

pub type Msg {
  LifecycleMsg(public_managed.Msg)
  PageMsg(public_page_message.Msg)
  QuickActionsMsg(quick_actions_managed.Msg)
  QuickActionSelected(QuickActionTarget)
  EditorRunShortcutPressed
}

pub type Command {
  None
  Batch(List(Command))
  RunPage(public_page_command.Command)
  GetSession
  RefreshSession
  TrackPageview(route.Route)
  ApplyMetadata
  ScheduleTick
  LoadRoute(route.Route)
  ObserveNavigation
  BindKeyboardShortcuts
  OpenQuickActions
  CloseQuickActions
  ScrollToQuickAction(Int)
  Navigate(route.Route)
}

pub fn init(
  initial_route: route.Route,
  now: Timestamp,
  page_visible: Bool,
) -> #(Model, Command) {
  let #(lifecycle, lifecycle_command) =
    public_managed.init(
      initial_route,
      now,
      page_visible,
      public_page_managed.init,
    )
  let model = Model(lifecycle:, quick_actions: quick_actions.init())
  #(
    model,
    batch([
      ObserveNavigation,
      from_lifecycle_command(lifecycle_command),
      BindKeyboardShortcuts,
    ]),
  )
}

pub fn update(model: Model, msg: Msg) -> #(Model, Command) {
  case msg {
    LifecycleMsg(lifecycle_msg) -> update_lifecycle(model, lifecycle_msg)
    PageMsg(page_msg) -> update_page(model, page_msg)
    QuickActionsMsg(quick_action_msg) ->
      update_quick_actions(model, quick_action_msg)
    QuickActionSelected(target) ->
      handle_quick_action(
        Model(
          ..model,
          quick_actions: quick_actions.clear_query(model.quick_actions),
        ),
        target,
      )
    EditorRunShortcutPressed ->
      case model.lifecycle.page_model {
        public_page_state.Editor(_) ->
          update_page(
            model,
            public_page_message.EditorPageMsg(editor_message.RunSubmitted),
          )
        _ -> #(model, None)
      }
  }
}

fn update_lifecycle(
  model: Model,
  msg: public_managed.Msg,
) -> #(Model, Command) {
  let #(lifecycle, command) =
    public_managed.update(
      model.lifecycle,
      msg,
      public_page_managed.init,
      public_page_managed.session_loaded,
    )
  let next_model = Model(..model, lifecycle:)
  case msg {
    public_managed.UserNavigatedTo(_) -> {
      let reset_model = Model(..next_model, quick_actions: quick_actions.init())
      #(
        reset_model,
        batch([CloseQuickActions, from_lifecycle_command(command)]),
      )
    }
    _ -> #(next_model, from_lifecycle_command(command))
  }
}

fn update_page(
  model: Model,
  msg: public_page_message.Msg,
) -> #(Model, Command) {
  case
    public_page_managed.update(
      model.lifecycle.page_model,
      msg,
      model.lifecycle.runtime.session,
    )
  {
    option.None -> #(model, None)
    option.Some(transition) -> {
      let next_model = with_page_model(model, transition.model)
      let metadata_command = case transition.metadata_changed {
        True -> ApplyMetadata
        False -> None
      }
      #(
        next_model,
        batch([
          run_page(transition.command),
          command_for_app_event(transition.event),
          metadata_command,
        ]),
      )
    }
  }
}

fn command_for_app_event(app_event: event.AppEvent) -> Command {
  case app_event {
    event.NoAppEvent -> None
    event.RefreshSession -> GetSession
  }
}

fn with_page_model(model: Model, page_model: public_page_state.Model) -> Model {
  Model(
    ..model,
    lifecycle: public_managed.Model(..model.lifecycle, page_model:),
  )
}

fn update_quick_actions(
  model: Model,
  msg: quick_actions_managed.Msg,
) -> #(Model, Command) {
  let #(quick_actions, command) =
    quick_actions_managed.update(
      model.quick_actions,
      msg,
      quick_action_sections(model),
    )
  let next_model = Model(..model, quick_actions:)
  case command {
    quick_actions_managed.None -> #(next_model, None)
    quick_actions_managed.OpenDialog -> #(next_model, OpenQuickActions)
    quick_actions_managed.CloseDialog -> #(next_model, CloseQuickActions)
    quick_actions_managed.ScrollTo(index) -> #(
      next_model,
      ScrollToQuickAction(index),
    )
    quick_actions_managed.Run(target) -> handle_quick_action(next_model, target)
  }
}

fn handle_quick_action(
  model: Model,
  target: QuickActionTarget,
) -> #(Model, Command) {
  case target {
    NavigateTo(destination) -> #(
      model,
      batch([CloseQuickActions, Navigate(destination)]),
    )
    TriggerPageAction(page_msg) -> {
      let #(next_model, command) = update_page(model, page_msg)
      #(next_model, batch([CloseQuickActions, command]))
    }
  }
}

pub fn quick_action_sections(
  model: Model,
) -> List(top_bar.Section(QuickActionTarget)) {
  public_quick_actions.sections(
    model.lifecycle.runtime.session,
    model.lifecycle.route,
    model.quick_actions.query,
    public_page_actions.actions(
      model.lifecycle.page_model,
      runtime.current_user_id(model.lifecycle.runtime.session),
    )
      |> list.map(fn(action) { top_bar.map_action(action, TriggerPageAction) }),
    NavigateTo,
  )
}

fn from_lifecycle_command(
  command: public_managed.Command(public_page_command.Command),
) -> Command {
  case command {
    public_managed.None -> None
    public_managed.Batch(commands) ->
      commands
      |> list.map(from_lifecycle_command)
      |> batch
    public_managed.RunPage(page_command) -> run_page(page_command)
    public_managed.GetSession -> GetSession
    public_managed.RefreshSession -> RefreshSession
    public_managed.TrackPageview(target) -> TrackPageview(target)
    public_managed.ApplyMetadata -> ApplyMetadata
    public_managed.ScheduleTick -> ScheduleTick
    public_managed.LoadRoute(target) -> LoadRoute(target)
  }
}

fn run_page(command: public_page_command.Command) -> Command {
  case public_page_command.is_none(command) {
    True -> None
    False -> RunPage(command)
  }
}

pub fn batch(commands: List(Command)) -> Command {
  let commands = list.flat_map(commands, flatten_command)
  case commands {
    [] -> None
    [command] -> command
    commands -> Batch(commands)
  }
}

fn flatten_command(command: Command) -> List(Command) {
  case command {
    None -> []
    Batch(commands) -> list.flat_map(commands, flatten_command)
    command -> [command]
  }
}

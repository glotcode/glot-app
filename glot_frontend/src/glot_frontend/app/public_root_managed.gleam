import gleam/list
import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_core/route
import glot_frontend/app/event
import glot_frontend/app/page_presentation
import glot_frontend/app/public_managed
import glot_frontend/app/public_page_actions
import glot_frontend/app/public_page_command
import glot_frontend/app/public_page_managed
import glot_frontend/app/public_page_message
import glot_frontend/app/public_page_state
import glot_frontend/app/public_quick_actions
import glot_frontend/app/quick_actions
import glot_frontend/app/quick_actions_managed
import glot_frontend/app/quick_actions_root_managed
import glot_frontend/app/runtime
import glot_frontend/navigation.{type Presentation}
import glot_frontend/public/editor/message as editor_message
import glot_web/page/top_bar

pub type Model {
  Model(
    lifecycle: public_managed.Model(public_page_state.Model),
    presentation: page_presentation.Model(public_page_state.Model),
    navigation_presentation: Presentation,
    quick_actions: quick_actions.Model,
  )
}

pub type QuickActionTarget {
  NavigateTo(route.Route)
  TriggerPageAction(public_page_message.Msg)
}

pub type Msg {
  LifecycleMsg(public_managed.Msg)
  NavigationObserved(route.Route, Presentation)
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
  CommitNavigation(Presentation)
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
  let model =
    Model(
      lifecycle:,
      presentation: page_presentation.init(lifecycle.page_model),
      navigation_presentation: navigation.Reset,
      quick_actions: quick_actions.init(),
    )
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
    LifecycleMsg(public_managed.UserNavigatedTo(destination)) ->
      update_lifecycle(
        Model(..model, navigation_presentation: navigation.Reset),
        public_managed.UserNavigatedTo(destination),
      )
    LifecycleMsg(lifecycle_msg) -> update_lifecycle(model, lifecycle_msg)
    NavigationObserved(destination, presentation) ->
      navigation_observed(model, destination, presentation)
    PageMsg(page_msg) -> update_page(model, page_msg)
    QuickActionsMsg(quick_action_msg) ->
      quick_actions_root_managed.update(
        model,
        quick_action_msg,
        using: quick_actions_coordinator(),
      )
    QuickActionSelected(target) ->
      quick_actions_root_managed.select(
        model,
        target,
        using: quick_actions_coordinator(),
      )
    EditorRunShortcutPressed ->
      case model.lifecycle.page_model {
        public_page_state.Editor(_) ->
          update_page(
            model,
            public_page_message.EditorPageMsg(
              editor_message.Editor(editor_message.Execution(
                editor_message.RunSubmitted,
              )),
            ),
          )
        _ -> #(model, None)
      }
  }
}

fn navigation_observed(
  model: Model,
  destination: route.Route,
  presentation: Presentation,
) -> #(Model, Command) {
  let model = Model(..model, navigation_presentation: presentation)
  case destination == model.lifecycle.route, is_transitioning(model) {
    True, False -> #(model, CommitNavigation(presentation))
    True, True -> #(model, None)
    False, _ ->
      update_lifecycle(model, public_managed.UserNavigatedTo(destination))
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
  let route_changed = lifecycle.route != model.lifecycle.route
  let presentation_transition = case route_changed {
    True ->
      page_presentation.begin(
        model.presentation,
        lifecycle.page_model,
        public_page_state.is_presentable,
      )
    False ->
      page_presentation.advance(
        model.presentation,
        lifecycle.page_model,
        public_page_state.is_presentable,
      )
  }
  let presentation = page_presentation.model(presentation_transition)
  let next_model = Model(..model, lifecycle:, presentation:)
  let lifecycle_command =
    command
    |> from_lifecycle_command
    |> keep_metadata_unless_transitioning(presentation)
  let lifecycle_command = case
    page_presentation.did_present(presentation_transition),
    route_changed
  {
    True, True ->
      batch([
        lifecycle_command,
        CommitNavigation(next_model.navigation_presentation),
      ])
    True, False ->
      batch([
        lifecycle_command,
        ApplyMetadata,
        CommitNavigation(next_model.navigation_presentation),
      ])
    False, _ -> lifecycle_command
  }
  case msg {
    public_managed.UserNavigatedTo(_) -> {
      let #(reset_model, close_command) =
        quick_actions_root_managed.reset(
          next_model,
          using: quick_actions_coordinator(),
        )
      #(reset_model, batch([close_command, lifecycle_command]))
    }
    _ -> #(next_model, lifecycle_command)
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
      let model_with_page = with_page_model(model, transition.model)
      let presentation_transition =
        page_presentation.advance(
          model.presentation,
          transition.model,
          public_page_state.is_presentable,
        )
      let presentation = page_presentation.model(presentation_transition)
      let next_model = Model(..model_with_page, presentation:)
      let metadata_command = case
        page_presentation.did_present(presentation_transition),
        page_presentation.is_transitioning(presentation),
        transition.metadata_changed
      {
        True, _, _ | _, False, True -> ApplyMetadata
        _, _, _ -> None
      }
      #(
        next_model,
        batch([
          run_page(transition.command),
          command_for_app_event(transition.event),
          metadata_command,
        ]),
      )
      |> with_navigation_commit(presentation_transition)
    }
  }
}

fn with_navigation_commit(
  result: #(Model, Command),
  transition: page_presentation.Transition(public_page_state.Model),
) -> #(Model, Command) {
  let #(model, command) = result
  case page_presentation.did_present(transition) {
    True -> #(
      model,
      batch([command, CommitNavigation(model.navigation_presentation)]),
    )
    False -> result
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

fn run_quick_action(
  model: Model,
  target: QuickActionTarget,
) -> #(Model, Command) {
  case target {
    NavigateTo(destination) -> #(model, Navigate(destination))
    TriggerPageAction(page_msg) -> update_page(model, page_msg)
  }
}

fn quick_actions_coordinator() -> quick_actions_root_managed.Coordinator(
  Model,
  QuickActionTarget,
  Command,
) {
  quick_actions_root_managed.Coordinator(
    state: fn(model: Model) { model.quick_actions },
    replace_state: fn(model, quick_actions) { Model(..model, quick_actions:) },
    sections: quick_action_sections,
    none: None,
    open_dialog: OpenQuickActions,
    close_dialog: CloseQuickActions,
    scroll_to: ScrollToQuickAction,
    batch: batch,
    run: run_quick_action,
  )
}

pub fn quick_action_sections(
  model: Model,
) -> List(top_bar.Section(QuickActionTarget)) {
  public_quick_actions.sections(
    model.lifecycle.runtime.session,
    model.lifecycle.route,
    model.quick_actions.query,
    public_page_actions.actions(
      presented_page(model),
      runtime.current_user_id(model.lifecycle.runtime.session),
    )
      |> list.map(fn(action) { top_bar.map_action(action, TriggerPageAction) }),
    NavigateTo,
  )
}

pub fn presented_page(model: Model) -> public_page_state.Model {
  page_presentation.presented(model.presentation)
}

pub fn is_transitioning(model: Model) -> Bool {
  page_presentation.is_transitioning(model.presentation)
}

fn keep_metadata_unless_transitioning(
  command: Command,
  presentation: page_presentation.Model(public_page_state.Model),
) -> Command {
  case page_presentation.is_transitioning(presentation) {
    True -> without_metadata(command)
    False -> command
  }
}

fn without_metadata(command: Command) -> Command {
  case command {
    ApplyMetadata -> None
    Batch(commands) -> commands |> list.map(without_metadata) |> batch
    command -> command
  }
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

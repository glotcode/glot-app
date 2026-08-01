import gleam/list
import gleam/time/timestamp.{type Timestamp}
import glot_core/route
import glot_frontend/admin/command as admin_command
import glot_frontend/admin/router_managed
import glot_frontend/admin/router_message
import glot_frontend/admin/router_state
import glot_frontend/app/admin_managed
import glot_frontend/app/page_presentation
import glot_frontend/app/public_quick_actions
import glot_frontend/app/quick_actions
import glot_frontend/app/quick_actions_managed
import glot_frontend/app/quick_actions_root_managed
import glot_frontend/request_generation.{type Generation}
import glot_frontend/ui/delayed_loading
import glot_web/page/top_bar

pub type Model {
  Model(
    lifecycle: admin_managed.Model(router_state.Model),
    presentation: page_presentation.Model(Page),
    navigation_loading: delayed_loading.State,
    quick_actions: quick_actions.Model,
  )
}

pub type Page {
  Page(route: route.Route, model: router_state.Model)
}

pub type QuickActionTarget {
  NavigateTo(route.Route)
}

pub type Msg {
  LifecycleMsg(admin_managed.Msg(router_message.Msg))
  QuickActionsMsg(quick_actions_managed.Msg)
  QuickActionSelected(QuickActionTarget)
  IgnoredEditorRunShortcut
  NavigationLoadingDelayElapsed(Generation(delayed_loading.Stream))
}

pub type Command {
  None
  Batch(List(Command))
  RunAdmin(admin_command.Command(router_message.Msg))
  GetSession
  RefreshSession
  TrackPageview(route.Route)
  ScheduleTick
  ReplaceRoute(route.Route)
  LoadRoute(route.Route)
  ObserveNavigation
  BindKeyboardShortcuts
  OpenQuickActions
  CloseQuickActions
  ScrollToQuickAction(Int)
  Navigate(route.Route)
  ScheduleNavigationLoading(Int, Generation(delayed_loading.Stream))
  CommitNavigation
}

pub fn init(
  initial_route: route.Route,
  now: Timestamp,
  page_visible: Bool,
) -> #(Model, Command) {
  let #(lifecycle, lifecycle_command) =
    admin_managed.init(initial_route, now, page_visible, pages())
  let model =
    Model(
      lifecycle:,
      presentation: page_presentation.init(Page(
        route: lifecycle.route,
        model: lifecycle.page_model,
      )),
      navigation_loading: delayed_loading.idle(),
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
    LifecycleMsg(lifecycle_msg) -> update_lifecycle(model, lifecycle_msg)
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
    IgnoredEditorRunShortcut -> #(model, None)
    NavigationLoadingDelayElapsed(generation) ->
      navigation_loading_delay_elapsed(model, generation)
  }
}

fn update_lifecycle(
  model: Model,
  msg: admin_managed.Msg(router_message.Msg),
) -> #(Model, Command) {
  let #(lifecycle, command) =
    admin_managed.update(model.lifecycle, msg, pages())
  let route_changed = lifecycle.route != model.lifecycle.route
  let candidate = Page(route: lifecycle.route, model: lifecycle.page_model)
  let presentation_transition = case route_changed {
    True -> page_presentation.begin(model.presentation, candidate, presentable)
    False ->
      page_presentation.advance(model.presentation, candidate, presentable)
  }
  let presentation = page_presentation.model(presentation_transition)
  let #(navigation_loading, presentation_command) =
    presentation_command(
      model.navigation_loading,
      presentation_transition,
      route_changed,
    )
  let next_model =
    Model(..model, lifecycle:, presentation:, navigation_loading:)
  let lifecycle_command =
    batch([from_lifecycle_command(command), presentation_command])
  case msg {
    admin_managed.UserNavigatedTo(_) -> {
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

fn presentable(page: Page) -> Bool {
  router_state.is_presentable(page.model)
}

fn presentation_command(
  navigation_loading: delayed_loading.State,
  transition: page_presentation.Transition(Page),
  route_changed: Bool,
) -> #(delayed_loading.State, Command) {
  case
    page_presentation.did_present(transition),
    route_changed,
    page_presentation.is_transitioning(page_presentation.model(transition))
  {
    True, _, _ -> #(
      delayed_loading.finish(navigation_loading),
      CommitNavigation,
    )
    False, True, True -> {
      let #(navigation_loading, generation) =
        delayed_loading.begin(navigation_loading)
      #(
        navigation_loading,
        ScheduleNavigationLoading(delayed_loading.delay(), generation),
      )
    }
    False, _, _ -> #(navigation_loading, None)
  }
}

fn navigation_loading_delay_elapsed(
  model: Model,
  generation: Generation(delayed_loading.Stream),
) -> #(Model, Command) {
  let navigation_loading =
    delayed_loading.reveal(model.navigation_loading, generation)
  case
    delayed_loading.is_visible(navigation_loading),
    page_presentation.is_transitioning(model.presentation)
  {
    True, True -> {
      let candidate =
        Page(route: model.lifecycle.route, model: model.lifecycle.page_model)
      let presentation =
        page_presentation.force(candidate)
        |> page_presentation.model
      #(
        Model(
          ..model,
          presentation:,
          navigation_loading: delayed_loading.finish(navigation_loading),
        ),
        CommitNavigation,
      )
    }
    _, _ -> #(Model(..model, navigation_loading:), None)
  }
}

pub fn presented_page(model: Model) -> router_state.Model {
  let Page(model: page_model, ..) =
    page_presentation.presented(model.presentation)
  page_model
}

pub fn presented_route(model: Model) -> route.Route {
  let Page(route:, ..) = page_presentation.presented(model.presentation)
  route
}

pub fn is_transitioning(model: Model) -> Bool {
  page_presentation.is_transitioning(model.presentation)
}

fn run_quick_action(
  model: Model,
  target: QuickActionTarget,
) -> #(Model, Command) {
  case target {
    NavigateTo(destination) -> #(model, Navigate(destination))
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
    presented_route(model),
    model.quick_actions.query,
    [],
    NavigateTo,
  )
}

fn pages() -> admin_managed.Pages(
  router_state.Model,
  router_message.Msg,
  admin_command.Command(router_message.Msg),
) {
  admin_managed.Pages(
    empty: router_managed.empty,
    init: router_managed.init,
    session_loaded: router_managed.session_loaded,
    update: router_managed.update,
    none: admin_command.none(),
  )
}

fn from_lifecycle_command(
  command: admin_managed.Command(admin_command.Command(router_message.Msg)),
) -> Command {
  case command {
    admin_managed.None -> None
    admin_managed.Batch(commands) ->
      commands
      |> list.map(from_lifecycle_command)
      |> batch
    admin_managed.RunAdmin(command) -> run_admin(command)
    admin_managed.GetSession -> GetSession
    admin_managed.RefreshSession -> RefreshSession
    admin_managed.TrackPageview(target) -> TrackPageview(target)
    admin_managed.ScheduleTick -> ScheduleTick
    admin_managed.ReplaceRoute(target) -> ReplaceRoute(target)
    admin_managed.LoadRoute(target) -> LoadRoute(target)
  }
}

fn run_admin(command: admin_command.Command(router_message.Msg)) -> Command {
  case command {
    admin_command.None -> None
    _ -> RunAdmin(command)
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

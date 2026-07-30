import gleam/list
import gleam/time/timestamp.{type Timestamp}
import glot_core/route
import glot_frontend/admin/command as admin_command
import glot_frontend/admin/router_managed
import glot_frontend/admin/router_message
import glot_frontend/admin/router_state
import glot_frontend/app/admin_managed
import glot_frontend/app/public_quick_actions
import glot_frontend/app/quick_actions
import glot_frontend/app/quick_actions_managed
import glot_web/page/top_bar

pub type Model {
  Model(
    lifecycle: admin_managed.Model(router_state.Model),
    quick_actions: quick_actions.Model,
  )
}

pub type QuickActionTarget {
  NavigateTo(route.Route)
}

pub type Msg {
  LifecycleMsg(admin_managed.Msg(router_message.Msg))
  QuickActionsMsg(quick_actions_managed.Msg)
  QuickActionSelected(QuickActionTarget)
  IgnoredEditorRunShortcut
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
}

pub fn init(
  initial_route: route.Route,
  now: Timestamp,
  page_visible: Bool,
) -> #(Model, Command) {
  let #(lifecycle, lifecycle_command) =
    admin_managed.init(initial_route, now, page_visible, pages())
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
    IgnoredEditorRunShortcut -> #(model, None)
  }
}

fn update_lifecycle(
  model: Model,
  msg: admin_managed.Msg(router_message.Msg),
) -> #(Model, Command) {
  let #(lifecycle, command) =
    admin_managed.update(model.lifecycle, msg, pages())
  let next_model = Model(..model, lifecycle:)
  case msg {
    admin_managed.UserNavigatedTo(_) -> {
      let reset_model = Model(..next_model, quick_actions: quick_actions.init())
      #(
        reset_model,
        batch([CloseQuickActions, from_lifecycle_command(command)]),
      )
    }
    _ -> #(next_model, from_lifecycle_command(command))
  }
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
  }
}

pub fn quick_action_sections(
  model: Model,
) -> List(top_bar.Section(QuickActionTarget)) {
  public_quick_actions.sections(
    model.lifecycle.runtime.session,
    model.lifecycle.route,
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

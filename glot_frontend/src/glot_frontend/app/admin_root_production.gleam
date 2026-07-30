import gleam/list
import gleam/option
import glot_core/route
import glot_frontend/admin/interpreter as admin_interpreter
import glot_frontend/admin/production_ports as admin_ports
import glot_frontend/api/account
import glot_frontend/app/admin_managed
import glot_frontend/app/admin_root_managed
import glot_frontend/app/quick_actions_managed
import glot_frontend/app/runtime_production
import glot_frontend/platform/app_dialog
import glot_frontend/platform/browser_navigation
import glot_frontend/platform/clock
import glot_frontend/platform/keyboard_shortcuts
import glot_frontend/platform/page_visibility
import glot_frontend/platform/quick_action_scroll
import glot_web/page/top_bar
import lustre/effect.{type Effect}
import modem

pub fn run(
  command: admin_root_managed.Command,
) -> Effect(admin_root_managed.Msg) {
  case command {
    admin_root_managed.None -> effect.none()
    admin_root_managed.Batch(commands) -> effect.batch(list.map(commands, run))
    admin_root_managed.RunAdmin(command) ->
      admin_interpreter.run(command, using: admin_ports.new())
      |> effect.map(fn(msg) {
        admin_root_managed.LifecycleMsg(admin_managed.AdminPagesMsg(msg))
      })
    admin_root_managed.GetSession ->
      account.get_session(fn(result) {
        admin_root_managed.LifecycleMsg(admin_managed.SessionLoaded(result))
      })
    admin_root_managed.RefreshSession ->
      account.refresh_session(fn(result) {
        admin_root_managed.LifecycleMsg(admin_managed.SessionRefreshed(result))
      })
    admin_root_managed.TrackPageview(target) ->
      runtime_production.track_pageview(target, fn(result) {
        admin_root_managed.LifecycleMsg(admin_managed.PageviewTracked(result))
      })
    admin_root_managed.ScheduleTick ->
      clock.schedule_next_tick(fn(now) {
        admin_root_managed.LifecycleMsg(admin_managed.ClockTicked(
          now,
          page_visibility.document_is_visible(),
        ))
      })
    admin_root_managed.ReplaceRoute(target) -> {
      let #(path, query) = route.path_and_query(target)
      modem.replace(path, query, option.None)
    }
    admin_root_managed.LoadRoute(target) ->
      browser_navigation.load(route.to_string(target))
    admin_root_managed.ObserveNavigation ->
      modem.init(fn(uri) {
        uri
        |> route.from_uri
        |> admin_managed.UserNavigatedTo
        |> admin_root_managed.LifecycleMsg
      })
    admin_root_managed.BindKeyboardShortcuts ->
      keyboard_shortcuts.bind(
        admin_root_managed.QuickActionsMsg(quick_actions_managed.Opened),
        admin_root_managed.IgnoredEditorRunShortcut,
      )
    admin_root_managed.OpenQuickActions ->
      app_dialog.open(top_bar.quick_actions_dialog_id)
    admin_root_managed.CloseQuickActions ->
      app_dialog.close(top_bar.quick_actions_dialog_id)
    admin_root_managed.ScrollToQuickAction(index) ->
      quick_action_scroll.ensure_visible(index)
    admin_root_managed.Navigate(destination) -> navigate(destination)
  }
}

fn navigate(destination: route.Route) -> Effect(admin_root_managed.Msg) {
  case route.is_admin_route(destination) {
    True -> {
      let #(path, query) = route.path_and_query(destination)
      modem.push(path, query, option.None)
    }
    False -> browser_navigation.load(route.to_string(destination))
  }
}

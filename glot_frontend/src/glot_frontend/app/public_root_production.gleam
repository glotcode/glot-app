import gleam/list
import glot_core/route
import glot_frontend/api/account as account_api
import glot_frontend/app/public_managed
import glot_frontend/app/public_page_metadata
import glot_frontend/app/public_page_production
import glot_frontend/app/public_root_managed
import glot_frontend/app/quick_actions_managed
import glot_frontend/app/runtime_production
import glot_frontend/platform/app_dialog
import glot_frontend/platform/browser_navigation
import glot_frontend/platform/clock
import glot_frontend/platform/keyboard_shortcuts
import glot_frontend/platform/page_metadata
import glot_frontend/platform/page_visibility
import glot_frontend/platform/quick_action_scroll
import glot_frontend/platform/spa_navigation
import glot_web/page/top_bar
import lustre/effect.{type Effect}

pub fn run(
  command: public_root_managed.Command,
  model: public_root_managed.Model,
) -> Effect(public_root_managed.Msg) {
  case command {
    public_root_managed.None -> effect.none()
    public_root_managed.Batch(commands) ->
      effect.batch(list.map(commands, fn(command) { run(command, model) }))
    public_root_managed.RunPage(page_command) ->
      public_page_production.run(page_command)
      |> effect.map(public_root_managed.PageMsg)
    public_root_managed.GetSession ->
      account_api.get_session(fn(result) {
        public_root_managed.LifecycleMsg(public_managed.SessionLoaded(result))
      })
    public_root_managed.RefreshSession ->
      account_api.refresh_session(fn(result) {
        public_root_managed.LifecycleMsg(public_managed.SessionRefreshed(result))
      })
    public_root_managed.TrackPageview(target) ->
      runtime_production.track_pageview(target, fn(result) {
        public_root_managed.LifecycleMsg(public_managed.PageviewTracked(result))
      })
    public_root_managed.ApplyMetadata ->
      page_metadata.apply(public_page_metadata.metadata(
        public_root_managed.presented_page(model),
        model.lifecycle.route,
      ))
    public_root_managed.ScheduleTick ->
      clock.schedule_next_tick(fn(now) {
        public_root_managed.LifecycleMsg(public_managed.ClockTicked(
          now,
          page_visibility.document_is_visible(),
        ))
      })
    public_root_managed.LoadRoute(target) ->
      browser_navigation.load(route.to_string(target))
    public_root_managed.ObserveNavigation ->
      spa_navigation.observe(fn(uri) {
        uri
        |> route.from_uri
        |> public_managed.UserNavigatedTo
        |> public_root_managed.LifecycleMsg
      })
    public_root_managed.BindKeyboardShortcuts ->
      keyboard_shortcuts.bind(
        public_root_managed.QuickActionsMsg(quick_actions_managed.Opened),
        public_root_managed.EditorRunShortcutPressed,
      )
    public_root_managed.OpenQuickActions ->
      app_dialog.open(top_bar.quick_actions_dialog_id)
    public_root_managed.CloseQuickActions ->
      app_dialog.close(top_bar.quick_actions_dialog_id)
    public_root_managed.ScrollToQuickAction(index) ->
      quick_action_scroll.ensure_visible(index)
    public_root_managed.Navigate(destination) -> navigate(destination)
    public_root_managed.CommitNavigation -> spa_navigation.commit()
  }
}

fn navigate(destination: route.Route) -> Effect(public_root_managed.Msg) {
  case route.is_admin_route(destination) {
    True -> browser_navigation.load(route.to_string(destination))
    False -> {
      let #(path, query) = route.path_and_query(destination)
      spa_navigation.push(path, query)
    }
  }
}

import gleam/option
import gleam/string
import gleam/time/timestamp
import gleeunit
import glot_core/admin/rate_limit_config_dto
import glot_core/auth/session_dto
import glot_core/auth/user_model
import glot_core/email/email_address_model
import glot_core/route
import glot_frontend/admin/command
import glot_frontend/admin/effect/config
import glot_frontend/admin/effect/users
import glot_frontend/admin/router_message
import glot_frontend/admin/router_state
import glot_frontend/api/response
import glot_frontend/app/admin_managed
import glot_frontend/app/admin_root_managed
import glot_frontend/app/admin_root_view
import glot_frontend/navigation
import lustre/element
import youid/uuid

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn initialization_describes_runtime_subscriptions_and_work_test() {
  let target = route.Admin(route.AdminHome)
  let #(model, command) = init(target)

  assert model.lifecycle.route == target
  assert command
    == admin_root_managed.Batch([
      admin_root_managed.ObserveNavigation,
      admin_root_managed.TrackPageview(target),
      admin_root_managed.GetSession,
      admin_root_managed.ScheduleTick,
      admin_root_managed.BindKeyboardShortcuts,
    ])
}

pub fn authenticated_navigation_loads_and_accepts_the_initial_response_test() {
  let #(initial, _) = init(route.Admin(route.AdminHome))
  let #(authenticated, _) = authenticate(initial)
  let destination = route.Admin(route.AdminRateLimits)
  let #(loading, navigation_command) =
    update_lifecycle(authenticated, admin_managed.UserNavigatedTo(destination))
  let assert admin_root_managed.Batch([
    admin_root_managed.CloseQuickActions,
    admin_root_managed.RunAdmin(command.Batch([
      command.None,
      command.Config(config.GetRateLimits(complete)),
    ])),
    admin_root_managed.TrackPageview(route.Admin(route.AdminRateLimits)),
    admin_root_managed.ScheduleNavigationLoading(_, loading_generation),
  ]) = navigation_command
  let assert router_state.AdminPage(_) =
    router_state.page(admin_root_managed.presented_page(loading))
  assert admin_root_managed.is_transitioning(loading)

  let #(failed, failure_command) =
    update_lifecycle(
      loading,
      admin_managed.AdminPagesMsg(
        complete(
          response.ApiFailure(response.Error(
            code: "fixture",
            message: "Navigation request completed.",
            request_id: uuid.v7(),
          )),
        ),
      ),
    )
  assert failure_command
    == admin_root_managed.CommitNavigation(navigation.Reset)
  assert !admin_root_managed.is_transitioning(failed)
  let assert router_state.AdminRateLimitsPage(_) =
    router_state.page(admin_root_managed.presented_page(failed))
  let rendered =
    admin_root_view.view(failed)
    |> element.to_document_string
  assert string.contains(rendered, "Navigation request completed.")

  let #(after_stale_delay, stale_delay_command) =
    admin_root_managed.update(
      failed,
      admin_root_managed.NavigationLoadingDelayElapsed(loading_generation),
    )
  assert after_stale_delay == failed
  assert stale_delay_command == admin_root_managed.None
}

pub fn response_from_page_left_during_navigation_is_ignored_test() {
  let #(initial, _) = init(route.Admin(route.AdminHome))
  let #(authenticated, _) = authenticate(initial)
  let #(rate_limits, rate_command) =
    update_lifecycle(
      authenticated,
      admin_managed.UserNavigatedTo(route.Admin(route.AdminRateLimits)),
    )
  let assert admin_root_managed.Batch([
    admin_root_managed.CloseQuickActions,
    admin_root_managed.RunAdmin(command.Batch([
      command.None,
      command.Config(config.GetRateLimits(rate_loaded)),
    ])),
    admin_root_managed.TrackPageview(_),
    admin_root_managed.ScheduleNavigationLoading(_, _),
  ]) = rate_command

  let #(users_page, users_command) =
    update_lifecycle(
      rate_limits,
      admin_managed.UserNavigatedTo(route.Admin(route.AdminUsers)),
    )
  let assert admin_root_managed.Batch([
    admin_root_managed.CloseQuickActions,
    admin_root_managed.RunAdmin(command.Batch([
      command.None,
      command.Users(users.GetUsers(_, _)),
    ])),
    admin_root_managed.TrackPageview(_),
    admin_root_managed.ScheduleNavigationLoading(_, _),
  ]) = users_command

  let stale =
    rate_loaded(
      response.Success(rate_limit_config_dto.RateLimitPoliciesResponse([])),
    )
  let #(unchanged, next_command) =
    update_lifecycle(users_page, admin_managed.AdminPagesMsg(stale))

  assert unchanged == users_page
  assert next_command == admin_root_managed.None
}

pub fn slow_admin_navigation_presents_its_loading_page_after_the_delay_test() {
  let #(initial, _) = init(route.Admin(route.AdminHome))
  let #(authenticated, _) = authenticate(initial)
  let destination = route.Admin(route.AdminRateLimits)
  let #(loading, navigation_command) =
    update_lifecycle(authenticated, admin_managed.UserNavigatedTo(destination))
  let assert admin_root_managed.Batch([
    admin_root_managed.CloseQuickActions,
    admin_root_managed.RunAdmin(_),
    admin_root_managed.TrackPageview(_),
    admin_root_managed.ScheduleNavigationLoading(_, generation),
  ]) = navigation_command

  let #(delayed, command) =
    admin_root_managed.update(
      loading,
      admin_root_managed.NavigationLoadingDelayElapsed(generation),
    )

  assert command == admin_root_managed.CommitNavigation(navigation.Reset)
  assert !admin_root_managed.is_transitioning(delayed)
  assert admin_root_managed.presented_route(delayed) == destination
  let rendered =
    admin_root_view.view(delayed)
    |> element.to_document_string
  assert string.contains(rendered, "Loading policies...")
}

pub fn admin_traversal_restoration_survives_the_loading_transition_test() {
  let #(initial, _) = init(route.Admin(route.AdminHome))
  let #(authenticated, _) = authenticate(initial)
  let destination = route.Admin(route.AdminRateLimits)
  let #(loading, navigation_command) =
    admin_root_managed.update(
      authenticated,
      admin_root_managed.NavigationObserved(
        destination,
        navigation.Restore(32, 960),
      ),
    )
  let assert admin_root_managed.Batch([
    admin_root_managed.CloseQuickActions,
    admin_root_managed.RunAdmin(command.Batch([
      command.None,
      command.Config(config.GetRateLimits(complete)),
    ])),
    admin_root_managed.TrackPageview(_),
    admin_root_managed.ScheduleNavigationLoading(_, _),
  ]) = navigation_command

  let #(loaded, command) =
    update_lifecycle(
      loading,
      admin_managed.AdminPagesMsg(
        complete(
          response.Success(rate_limit_config_dto.RateLimitPoliciesResponse([])),
        ),
      ),
    )

  assert !admin_root_managed.is_transitioning(loaded)
  assert command
    == admin_root_managed.CommitNavigation(navigation.Restore(32, 960))
}

pub fn same_admin_route_traversal_restores_without_reloading_test() {
  let target = route.Admin(route.AdminHome)
  let #(model, _) = init(target)
  let #(unchanged, command) =
    admin_root_managed.update(
      model,
      admin_root_managed.NavigationObserved(target, navigation.Restore(0, 280)),
    )

  assert unchanged.lifecycle == model.lifecycle
  assert command
    == admin_root_managed.CommitNavigation(navigation.Restore(0, 280))
}

pub fn navigation_closes_quick_actions_and_lifts_lifecycle_commands_test() {
  let #(model, _) = init(route.Admin(route.AdminHome))
  let destination = route.Public(route.Home)
  let #(unchanged, command) =
    update_lifecycle(model, admin_managed.UserNavigatedTo(destination))

  assert unchanged == model
  assert command
    == admin_root_managed.Batch([
      admin_root_managed.CloseQuickActions,
      admin_root_managed.LoadRoute(destination),
    ])
}

pub fn selecting_navigation_describes_dialog_and_route_commands_test() {
  let #(model, _) = init(route.Admin(route.AdminHome))
  let destination = route.Public(route.Contact)
  let #(unchanged, command) =
    admin_root_managed.update(
      model,
      admin_root_managed.QuickActionSelected(admin_root_managed.NavigateTo(
        destination,
      )),
    )

  assert unchanged == model
  assert command
    == admin_root_managed.Batch([
      admin_root_managed.CloseQuickActions,
      admin_root_managed.Navigate(destination),
    ])
}

pub fn unauthorized_session_lifts_route_replacement_test() {
  let #(model, _) = init(route.Admin(route.AdminHome))
  let #(loaded, command) =
    update_lifecycle(
      model,
      admin_managed.SessionLoaded(response.Success(option.None)),
    )

  assert loaded.lifecycle.runtime != model.lifecycle.runtime
  let assert admin_root_managed.ReplaceRoute(route.Public(route.Login)) =
    command
}

pub fn editor_shortcut_is_explicitly_ignored_test() {
  let #(model, _) = init(route.Admin(route.AdminHome))
  let #(unchanged, command) =
    admin_root_managed.update(
      model,
      admin_root_managed.IgnoredEditorRunShortcut,
    )

  assert unchanged == model
  assert command == admin_root_managed.None
}

fn init(
  target: route.Route,
) -> #(admin_root_managed.Model, admin_root_managed.Command) {
  admin_root_managed.init(target, timestamp.from_unix_seconds(1), True)
}

fn authenticate(
  model: admin_root_managed.Model,
) -> #(admin_root_managed.Model, admin_root_managed.Command) {
  update_lifecycle(
    model,
    admin_managed.SessionLoaded(response.Success(option.Some(admin_session()))),
  )
}

fn update_lifecycle(
  model: admin_root_managed.Model,
  msg: admin_managed.Msg(router_message.Msg),
) -> #(admin_root_managed.Model, admin_root_managed.Command) {
  admin_root_managed.update(model, admin_root_managed.LifecycleMsg(msg))
}

fn admin_session() -> session_dto.SessionResponse {
  session_dto.SessionResponse(
    id: uuid.v7(),
    user: session_dto.SessionUserResponse(
      id: uuid.v7(),
      email: email_address_model.EmailAddress("admin@example.com"),
      username: "admin",
      role: user_model.AdminUser,
    ),
    created_at: timestamp.from_unix_seconds(1),
  )
}

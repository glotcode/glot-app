import gleam/time/timestamp
import gleeunit
import glot_core/route
import glot_frontend/api/response
import glot_frontend/app/public_managed
import glot_frontend/app/public_page_command
import glot_frontend/app/public_page_message
import glot_frontend/app/public_page_state
import glot_frontend/app/public_root_managed
import glot_frontend/public/editor/lifecycle as editor_lifecycle
import glot_frontend/public/editor/message as editor_message
import glot_frontend/public/editor/model as editor_model
import glot_frontend/public/editor/settings as editor_settings
import glot_frontend/public/home/message
import glot_frontend/public/login/message as login_message

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn initialization_describes_all_runtime_subscriptions_and_work_test() {
  let target = route.Public(route.Privacy)
  let #(model, command) = init(target)

  assert model.lifecycle.route == target
  assert model.lifecycle.page_model == public_page_state.Privacy
  assert command
    == public_root_managed.Batch([
      public_root_managed.ObserveNavigation,
      public_root_managed.TrackPageview(target),
      public_root_managed.ApplyMetadata,
      public_root_managed.GetSession,
      public_root_managed.ScheduleTick,
      public_root_managed.BindKeyboardShortcuts,
    ])
}

pub fn navigation_replaces_the_page_and_closes_quick_actions_test() {
  let #(initial, _) = init(route.Public(route.Home))
  let destination = route.Public(route.Contact)
  let #(navigated, command) =
    public_root_managed.update(
      initial,
      public_root_managed.LifecycleMsg(public_managed.UserNavigatedTo(
        destination,
      )),
    )

  let assert public_page_state.Contact(_) = navigated.lifecycle.page_model
  assert command
    == public_root_managed.Batch([
      public_root_managed.CloseQuickActions,
      public_root_managed.TrackPageview(destination),
      public_root_managed.ApplyMetadata,
    ])
}

pub fn message_from_a_page_left_during_navigation_is_ignored_test() {
  let #(initial, _) = init(route.Public(route.Home))
  let #(contact, _) =
    public_root_managed.update(
      initial,
      public_root_managed.LifecycleMsg(
        public_managed.UserNavigatedTo(route.Public(route.Contact)),
      ),
    )
  let #(unchanged, command) =
    public_root_managed.update(
      contact,
      public_root_managed.PageMsg(public_page_message.HomePageMsg(
        message.Increment,
      )),
    )

  assert unchanged == contact
  assert command == public_root_managed.None
}

pub fn selecting_navigation_describes_dialog_and_route_commands_test() {
  let #(model, _) = init(route.Public(route.Home))
  let destination = route.Admin(route.AdminHome)
  let #(unchanged, command) =
    public_root_managed.update(
      model,
      public_root_managed.QuickActionSelected(public_root_managed.NavigateTo(
        destination,
      )),
    )

  assert unchanged == model
  assert command
    == public_root_managed.Batch([
      public_root_managed.CloseQuickActions,
      public_root_managed.Navigate(destination),
    ])
}

pub fn page_app_events_are_lifted_into_root_commands_test() {
  let #(model, _) = init(route.Public(route.Login))
  let #(logged_in, command) =
    public_root_managed.update(
      model,
      public_root_managed.PageMsg(
        public_page_message.LoginPageMsg(
          login_message.LoggedIn(response.Success(Nil)),
        ),
      ),
    )

  let assert public_page_state.Login(_) = logged_in.lifecycle.page_model
  let assert public_root_managed.Batch([
    public_root_managed.RunPage(public_page_command.Login(_)),
    public_root_managed.GetSession,
  ]) = command
}

pub fn editor_metadata_is_applied_when_the_resulting_state_changes_it_test() {
  let target = route.Public(route.NewSnippet("javascript"))
  let #(initial, _) = init(target)
  let #(loaded, command) =
    public_root_managed.update(
      initial,
      public_root_managed.PageMsg(
        public_page_message.EditorPageMsg(
          editor_message.Lifecycle(editor_message.EnvironmentLoaded(
            editor_lifecycle.NewEditor("javascript"),
            "",
            editor_settings.defaults(),
          )),
        ),
      ),
    )

  let assert public_page_state.Editor(editor_model.Ready(_)) =
    loaded.lifecycle.page_model
  let assert public_root_managed.Batch([
    public_root_managed.RunPage(public_page_command.Editor(_)),
    public_root_managed.ApplyMetadata,
  ]) = command
}

fn init(
  target: route.Route,
) -> #(public_root_managed.Model, public_root_managed.Command) {
  public_root_managed.init(target, timestamp.from_unix_seconds(1), True)
}

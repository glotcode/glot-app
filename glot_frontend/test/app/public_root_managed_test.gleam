import gleam/option
import gleam/time/timestamp
import gleeunit
import glot_core/loadable
import glot_core/pagination_model
import glot_core/route
import glot_core/run
import glot_core/snippet/snippet_dto
import glot_frontend/api/response
import glot_frontend/app/public_managed
import glot_frontend/app/public_page_command
import glot_frontend/app/public_page_message
import glot_frontend/app/public_page_state
import glot_frontend/app/public_root_managed
import glot_frontend/navigation
import glot_frontend/public/editor/command as editor_command
import glot_frontend/public/editor/execution_operation
import glot_frontend/public/editor/lifecycle as editor_lifecycle
import glot_frontend/public/editor/message as editor_message
import glot_frontend/public/editor/model as editor_model
import glot_frontend/public/editor/operations
import glot_frontend/public/editor/settings as editor_settings
import glot_frontend/public/home/message
import glot_frontend/public/login/message as login_message
import glot_frontend/public/snippets/command as snippets_command
import glot_frontend/public/snippets/message as snippets_message
import glot_frontend/public/snippets/model as snippets_model
import support/editor_fixture
import youid/uuid

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
      public_root_managed.CommitNavigation(navigation.Reset),
    ])
}

pub fn navigation_keeps_the_current_page_until_snippets_are_loaded_test() {
  let #(initial, _) = init(route.Public(route.Home))
  let destination =
    route.Public(route.Snippets(
      after: option.None,
      before: option.None,
      username: option.None,
    ))
  let #(loading, loading_command) =
    public_root_managed.update(
      initial,
      public_root_managed.LifecycleMsg(public_managed.UserNavigatedTo(
        destination,
      )),
    )

  let assert public_page_state.Snippets(snippets_model.Model(request:, ..)) =
    loading.lifecycle.page_model
  let assert public_page_state.Home(_) =
    public_root_managed.presented_page(loading)
  assert public_root_managed.is_transitioning(loading)
  let assert public_root_managed.Batch([
    public_root_managed.CloseQuickActions,
    public_root_managed.RunPage(
      _,
      public_page_command.Snippets(snippets_command.LoadSsr(_)),
    ),
    public_root_managed.TrackPageview(tracked_destination),
  ]) = loading_command
  assert tracked_destination == destination

  let #(loaded, loaded_command) =
    public_root_managed.update(
      loading,
      public_root_managed.PageMsg(
        public_page_message.SnippetsPageMsg(snippets_message.SnippetsLoaded(
          request,
          response.Success(
            snippet_dto.ListSnippetsResponse(
              page: pagination_model.InitialCursorPage(
                items: [],
                next_cursor: option.None,
              ),
            ),
          ),
        )),
      ),
    )

  let assert public_page_state.Snippets(_) =
    public_root_managed.presented_page(loaded)
  assert !public_root_managed.is_transitioning(loaded)
  assert loaded_command
    == public_root_managed.Batch([
      public_root_managed.ApplyMetadata,
      public_root_managed.CommitNavigation(navigation.Reset),
    ])
}

pub fn slow_navigation_presents_the_destination_loading_state_after_its_delay_test() {
  let #(initial, _) = init(route.Public(route.Home))
  let destination =
    route.Public(route.Snippets(
      after: option.None,
      before: option.None,
      username: option.None,
    ))
  let #(loading, _) =
    public_root_managed.update(
      initial,
      public_root_managed.LifecycleMsg(public_managed.UserNavigatedTo(
        destination,
      )),
    )
  let assert public_page_state.Snippets(snippets_model.Model(request:, ..)) =
    loading.lifecycle.page_model
  let #(request_started, start_command) =
    public_root_managed.update(
      loading,
      public_root_managed.PageMsg(
        public_page_message.SnippetsPageMsg(snippets_message.EnvironmentLoaded(
          request,
          "",
        )),
      ),
    )
  let assert public_root_managed.RunPage(
    _,
    public_page_command.Snippets(snippets_command.Batch([
      snippets_command.ListPublicSnippets(_, _),
      snippets_command.Schedule(_, delay_elapsed),
    ])),
  ) = start_command
  let assert public_page_state.Home(_) =
    public_root_managed.presented_page(request_started)

  let #(delayed, delayed_command) =
    public_root_managed.update(
      request_started,
      public_root_managed.PageMsg(public_page_message.SnippetsPageMsg(
        delay_elapsed,
      )),
    )

  let assert public_page_state.Snippets(_) =
    public_root_managed.presented_page(delayed)
  assert !public_root_managed.is_transitioning(delayed)
  assert delayed_command
    == public_root_managed.Batch([
      public_root_managed.ApplyMetadata,
      public_root_managed.CommitNavigation(navigation.Reset),
    ])
}

pub fn terminal_navigation_failure_is_presented_instead_of_holding_forever_test() {
  let #(initial, _) = init(route.Public(route.Home))
  let destination =
    route.Public(route.Snippets(
      after: option.None,
      before: option.None,
      username: option.None,
    ))
  let #(loading, _) =
    public_root_managed.update(
      initial,
      public_root_managed.LifecycleMsg(public_managed.UserNavigatedTo(
        destination,
      )),
    )
  let assert public_page_state.Snippets(snippets_model.Model(request:, ..)) =
    loading.lifecycle.page_model
  let assert Ok(request_id) =
    uuid.from_string("00000000-0000-4000-8000-000000000001")

  let #(failed, command) =
    public_root_managed.update(
      loading,
      public_root_managed.PageMsg(
        public_page_message.SnippetsPageMsg(snippets_message.SnippetsLoaded(
          request,
          response.ApiFailure(response.Error(
            "fixture",
            "Could not load snippets.",
            request_id,
          )),
        )),
      ),
    )
  let assert public_page_state.Snippets(snippets_model.Model(
    page: loadable.LoadError(_),
    ..,
  )) = public_root_managed.presented_page(failed)
  assert command
    == public_root_managed.Batch([
      public_root_managed.ApplyMetadata,
      public_root_managed.CommitNavigation(navigation.Reset),
    ])
}

pub fn a_second_navigation_supersedes_a_pending_destination_test() {
  let #(initial, _) = init(route.Public(route.Home))
  let snippets_route =
    route.Public(route.Snippets(
      after: option.None,
      before: option.None,
      username: option.None,
    ))
  let #(snippets_loading, _) =
    public_root_managed.update(
      initial,
      public_root_managed.LifecycleMsg(public_managed.UserNavigatedTo(
        snippets_route,
      )),
    )
  let assert public_page_state.Snippets(snippets_model.Model(request:, ..)) =
    snippets_loading.lifecycle.page_model
  let contact_route = route.Public(route.Contact)
  let #(contact, _) =
    public_root_managed.update(
      snippets_loading,
      public_root_managed.LifecycleMsg(public_managed.UserNavigatedTo(
        contact_route,
      )),
    )

  let #(unchanged, command) =
    public_root_managed.update(
      contact,
      public_root_managed.PageMsg(
        public_page_message.SnippetsPageMsg(snippets_message.SnippetsLoaded(
          request,
          response.Success(
            snippet_dto.ListSnippetsResponse(
              page: pagination_model.InitialCursorPage(
                items: [],
                next_cursor: option.None,
              ),
            ),
          ),
        )),
      ),
    )

  let assert public_page_state.Contact(_) =
    public_root_managed.presented_page(unchanged)
  assert unchanged == contact
  assert command == public_root_managed.None
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

pub fn traversal_restoration_is_retained_until_the_page_is_presentable_test() {
  let #(initial, _) = init(route.Public(route.Home))
  let destination =
    route.Public(route.Snippets(
      after: option.None,
      before: option.None,
      username: option.None,
    ))
  let #(awaiting_cancellation, prepare_command) =
    public_root_managed.update(
      initial,
      public_root_managed.NavigationObserved(
        destination,
        navigation.Restore(18, 720),
      ),
    )
  assert awaiting_cancellation == initial
  assert prepare_command
    == public_root_managed.PrepareNavigation(
      destination,
      navigation.Restore(18, 720),
    )
  let #(loading, _) =
    public_root_managed.update(
      awaiting_cancellation,
      public_root_managed.NavigationPrepared(
        destination,
        navigation.Restore(18, 720),
      ),
    )
  let assert public_page_state.Snippets(snippets_model.Model(request:, ..)) =
    loading.lifecycle.page_model

  let #(loaded, command) =
    public_root_managed.update(
      loading,
      public_root_managed.PageMsg(
        public_page_message.SnippetsPageMsg(snippets_message.SnippetsLoaded(
          request,
          response.Success(
            snippet_dto.ListSnippetsResponse(
              page: pagination_model.InitialCursorPage(
                items: [],
                next_cursor: option.None,
              ),
            ),
          ),
        )),
      ),
    )

  assert !public_root_managed.is_transitioning(loaded)
  assert command
    == public_root_managed.Batch([
      public_root_managed.ApplyMetadata,
      public_root_managed.CommitNavigation(navigation.Restore(18, 720)),
    ])
}

pub fn same_route_traversal_restores_without_reinitializing_the_page_test() {
  let target = route.Public(route.Contact)
  let #(model, _) = init(target)
  let #(unchanged, command) =
    public_root_managed.update(
      model,
      public_root_managed.NavigationObserved(target, navigation.Restore(0, 410)),
    )

  assert unchanged.lifecycle == model.lifecycle
  assert command
    == public_root_managed.CommitNavigation(navigation.Restore(0, 410))
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
    public_root_managed.RunPage(_, public_page_command.Login(_)),
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
    public_root_managed.RunPage(_, public_page_command.Editor(_)),
    public_root_managed.ApplyMetadata,
  ]) = command
}

pub fn late_run_response_from_previous_snippet_is_ignored_test() {
  let first_route = route.Public(route.Snippet("slow-snippet"))
  let second_route = route.Public(route.Snippet("fast-snippet"))
  let #(initial, _) = init(first_route)
  let first = load_snippet(initial, "slow-snippet")
  let #(first_running, first_run_command) = submit_run(first)
  let assert public_root_managed.RunPage(
    first_origin,
    public_page_command.Editor(editor_command.Batch([
      editor_command.RunCode(_, finish_first),
      editor_command.Schedule(3000, _),
    ])),
  ) = first_run_command

  let #(second_loading, _) =
    public_root_managed.update(
      first_running,
      public_root_managed.LifecycleMsg(public_managed.UserNavigatedTo(
        second_route,
      )),
    )
  let second = load_snippet(second_loading, "fast-snippet")
  let #(second_running, second_run_command) = submit_run(second)
  let assert public_root_managed.RunPage(
    second_origin,
    public_page_command.Editor(editor_command.Batch([
      editor_command.RunCode(_, finish_second),
      editor_command.Schedule(3000, _),
    ])),
  ) = second_run_command
  assert first_origin != second_origin

  let #(second_finished, _) =
    public_root_managed.update(
      second_running,
      public_root_managed.PageEffectMsg(
        second_origin,
        public_page_message.EditorPageMsg(
          finish_second(editor_fixture.successful_run(
            stdout: "fast response",
            stderr: "",
            error: "",
          )),
        ),
      ),
    )
  let #(after_late_response, command) =
    public_root_managed.update(
      second_finished,
      public_root_managed.PageEffectMsg(
        first_origin,
        public_page_message.EditorPageMsg(
          finish_first(editor_fixture.successful_run(
            stdout: "slow response",
            stderr: "",
            error: "",
          )),
        ),
      ),
    )

  let assert public_page_state.Editor(editor_model.Ready(editor)) =
    after_late_response.lifecycle.page_model
  assert operations.execution_state(editor.operations)
    == execution_operation.Completed(
      Ok(run.SuccessfulRun(1_000_000, "fast response", "", "")),
    )
  assert command == public_root_managed.None
}

pub fn late_run_response_from_disposed_instance_of_same_route_is_ignored_test() {
  let first_route = route.Public(route.Snippet("same-snippet"))
  let other_route = route.Public(route.Snippet("other-snippet"))
  let #(initial, _) = init(first_route)
  let first_instance = load_snippet(initial, "same-snippet")
  let #(first_running, first_run_command) = submit_run(first_instance)
  let assert public_root_managed.RunPage(
    first_origin,
    public_page_command.Editor(editor_command.Batch([
      editor_command.RunCode(_, finish_first),
      editor_command.Schedule(3000, _),
    ])),
  ) = first_run_command

  let other_instance =
    first_running
    |> navigate_to(other_route)
    |> load_snippet("other-snippet")
  let current_instance =
    other_instance
    |> navigate_to(first_route)
    |> load_snippet("same-snippet")
  let #(current_running, current_run_command) = submit_run(current_instance)
  let assert public_root_managed.RunPage(
    current_origin,
    public_page_command.Editor(editor_command.Batch([
      editor_command.RunCode(_, finish_current),
      editor_command.Schedule(3000, _),
    ])),
  ) = current_run_command
  assert first_origin != current_origin

  let #(current_finished, _) =
    public_root_managed.update(
      current_running,
      public_root_managed.PageEffectMsg(
        current_origin,
        public_page_message.EditorPageMsg(
          finish_current(editor_fixture.successful_run(
            stdout: "current response",
            stderr: "",
            error: "",
          )),
        ),
      ),
    )
  let #(after_late_response, command) =
    public_root_managed.update(
      current_finished,
      public_root_managed.PageEffectMsg(
        first_origin,
        public_page_message.EditorPageMsg(
          finish_first(editor_fixture.successful_run(
            stdout: "disposed response",
            stderr: "",
            error: "",
          )),
        ),
      ),
    )

  let assert public_page_state.Editor(editor_model.Ready(editor)) =
    after_late_response.lifecycle.page_model
  assert operations.execution_state(editor.operations)
    == execution_operation.Completed(
      Ok(run.SuccessfulRun(1_000_000, "current response", "", "")),
    )
  assert command == public_root_managed.None
}

fn navigate_to(
  model: public_root_managed.Model,
  destination: route.Route,
) -> public_root_managed.Model {
  let #(navigated, _) =
    public_root_managed.update(
      model,
      public_root_managed.LifecycleMsg(public_managed.UserNavigatedTo(
        destination,
      )),
    )
  navigated
}

fn load_snippet(
  model: public_root_managed.Model,
  slug: String,
) -> public_root_managed.Model {
  let target = editor_lifecycle.ExistingEditor(slug)
  let #(loading, _) =
    public_root_managed.update(
      model,
      public_root_managed.PageMsg(
        public_page_message.EditorPageMsg(
          editor_message.Lifecycle(editor_message.EnvironmentLoaded(
            target,
            "",
            editor_settings.defaults(),
          )),
        ),
      ),
    )
  let #(loaded, _) =
    public_root_managed.update(
      loading,
      public_root_managed.PageMsg(
        public_page_message.EditorPageMsg(
          editor_message.Lifecycle(editor_message.SnippetLoaded(
            slug,
            response.Success(editor_fixture.snippet(slug, slug)),
          )),
        ),
      ),
    )
  loaded
}

fn submit_run(
  model: public_root_managed.Model,
) -> #(public_root_managed.Model, public_root_managed.Command) {
  public_root_managed.update(
    model,
    public_root_managed.PageMsg(
      public_page_message.EditorPageMsg(
        editor_message.Editor(editor_message.Execution(
          editor_message.RunSubmitted,
        )),
      ),
    ),
  )
}

fn init(
  target: route.Route,
) -> #(public_root_managed.Model, public_root_managed.Command) {
  public_root_managed.init(target, timestamp.from_unix_seconds(1), True)
}

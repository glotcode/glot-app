import gleam/list
import gleam/option
import gleeunit
import glot_core/loadable
import glot_core/pagination_model
import glot_core/snippet/snippet_dto
import glot_frontend/api/response
import glot_frontend/public/snippets/command
import glot_frontend/public/snippets/message
import glot_frontend/public/snippets/model
import glot_frontend/public/snippets/page
import glot_frontend/ui/delayed_loading
import support/managed_scenario

type Scenario =
  managed_scenario.Scenario(
    model.Model,
    command.Command(message.Msg),
    command.Command(message.Msg),
  )

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn environment_api_fixture_and_timer_drive_snippets_scenario_test() {
  let #(initial_model, initial_command) =
    page.init_managed(
      after: option.None,
      before: option.None,
      username: option.Some("alice"),
    )
  let scenario =
    managed_scenario.start(initial_model, initial_command, interpret)
  let assert [command.LoadSsr(environment_loaded)] =
    managed_scenario.pending(scenario)
  let scenario = respond(scenario, environment_loaded(""))
  let assert [
    command.ListPublicSnippets(request, snippets_loaded),
    command.Schedule(1000, delay_elapsed),
  ] = managed_scenario.pending(scenario)
  assert request.usernames == ["alice"]
  assert request.pagination == pagination_model.InitialPage(limit: 20)

  let scenario = respond_at(scenario, 1, delay_elapsed)
  let visible_model = managed_scenario.model(scenario)
  assert delayed_loading.is_visible(visible_model.loading_indicator)

  let fixture =
    snippet_dto.ListSnippetsResponse(page: pagination_model.InitialCursorPage(
      items: [],
      next_cursor: option.None,
    ))
  let scenario = respond(scenario, snippets_loaded(response.Success(fixture)))
  let loaded_model = managed_scenario.model(scenario)
  assert loaded_model.page == loadable.Loaded(fixture.page)
  assert !delayed_loading.is_visible(loaded_model.loading_indicator)
  managed_scenario.assert_no_pending(scenario)
}

fn dispatch(scenario: Scenario, msg: message.Msg) -> Scenario {
  managed_scenario.dispatch(scenario, msg, page.update_managed, interpret)
}

fn respond(scenario: Scenario, msg: message.Msg) -> Scenario {
  respond_at(scenario, 0, msg)
}

fn respond_at(scenario: Scenario, index: Int, msg: message.Msg) -> Scenario {
  let #(_, scenario) = managed_scenario.take_pending_at(scenario, index)
  dispatch(scenario, msg)
}

fn interpret(scenario: Scenario, next_command: command.Command(message.Msg)) {
  case next_command {
    command.None -> scenario
    command.Batch(commands) -> list.fold(commands, scenario, interpret)
    _ -> managed_scenario.append_pending(scenario, next_command)
  }
}

pub fn stale_environment_response_is_ignored_test() {
  let #(model, _) =
    page.init_managed(
      after: option.Some("new"),
      before: option.None,
      username: option.None,
    )
  let stale_request =
    model.Request(
      after: option.Some("old"),
      before: option.None,
      username: option.None,
    )
  let #(unchanged, next) =
    page.update_managed(model, message.EnvironmentLoaded(stale_request, ""))
  assert unchanged == model
  assert next == command.None
}

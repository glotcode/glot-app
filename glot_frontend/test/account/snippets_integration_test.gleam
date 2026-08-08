import gleam/list
import gleam/option
import glot_core/loadable
import glot_core/pagination_model
import glot_core/snippet/snippet_dto
import glot_frontend/account/snippets/command
import glot_frontend/account/snippets/message
import glot_frontend/account/snippets/model
import glot_frontend/account/snippets/page
import glot_frontend/api/response
import support/managed_scenario
import youid/uuid

type Scenario =
  managed_scenario.Scenario(
    model.Model,
    command.Command(message.Msg),
    command.Command(message.Msg),
  )

pub fn account_snippets_are_driven_by_api_and_timer_fixtures_test() {
  let #(initial_model, initial_command) =
    page.init_managed(after: option.None, before: option.None)
  let scenario =
    managed_scenario.start(initial_model, initial_command, interpret)
  let assert [
    command.ListSnippets(request, snippets_loaded),
    command.Schedule(_, delay_elapsed),
  ] = managed_scenario.pending(scenario)
  assert request.pagination == pagination_model.InitialPage(limit: 20)

  let fixture =
    snippet_dto.ListSnippetsResponse(page: pagination_model.InitialCursorPage(
      items: [],
      next_cursor: option.None,
    ))
  let #(_, scenario) = managed_scenario.take_next_pending(scenario)
  let scenario = dispatch(scenario, snippets_loaded(response.Success(fixture)))
  let #(_, scenario) = managed_scenario.take_next_pending(scenario)
  let scenario = dispatch(scenario, delay_elapsed)

  assert managed_scenario.model(scenario).page == loadable.Loaded(fixture.page)
  managed_scenario.assert_no_pending(scenario)
}

pub fn deletion_covers_cancel_failure_retry_and_success_test() {
  let #(model, _) = page.init_managed(after: option.None, before: option.None)
  let #(cancelled, cancel_command) =
    page.update_managed(model, message.DeleteCancelled)
  assert cancelled == model
  assert cancel_command
    == command.CloseDialog("manage-snippets-page-delete-dialog")

  let scenario =
    managed_scenario.new(model)
    |> dispatch(message.DeleteConfirmed("fixture"))
  let assert [command.CloseDialog(_), command.DeleteSnippet(request, complete)] =
    managed_scenario.pending(scenario)
  assert request.slug == "fixture"
  let #(_, scenario) = managed_scenario.take_pending_at(scenario, 1)
  let scenario = dispatch(scenario, complete(api_failure("Delete rejected.")))
  assert managed_scenario.model(scenario).mutation_error
    == option.Some(
      "Delete rejected. Request ID: 00000000-0000-4000-8000-000000000097",
    )

  let scenario = dispatch(scenario, message.DeleteConfirmed("fixture"))
  let assert [
    command.CloseDialog(_),
    command.CloseDialog(_),
    command.DeleteSnippet(_, retry),
  ] = managed_scenario.pending(scenario)
  let #(_, scenario) = managed_scenario.take_pending_at(scenario, 2)
  let scenario = dispatch(scenario, retry(response.Success(Nil)))
  let assert [
    command.CloseDialog(_),
    command.CloseDialog(_),
    command.ListSnippets(_, _),
    command.Schedule(_, _),
  ] = managed_scenario.pending(scenario)
  assert managed_scenario.model(scenario).deleting_slug == option.None
  assert managed_scenario.model(scenario).mutation_error == option.None
}

fn dispatch(scenario: Scenario, msg: message.Msg) -> Scenario {
  managed_scenario.dispatch(scenario, msg, page.update_managed, interpret)
}

fn interpret(scenario: Scenario, next_command: command.Command(message.Msg)) {
  case next_command {
    command.None -> scenario
    command.Batch(commands) -> list.fold(commands, scenario, interpret)
    _ -> managed_scenario.append_pending(scenario, next_command)
  }
}

fn api_failure(message: String) -> response.Response(value) {
  let assert Ok(id) = uuid.from_string("00000000-0000-4000-8000-000000000097")
  response.ApiFailure(response.Error("fixture", message, id))
}

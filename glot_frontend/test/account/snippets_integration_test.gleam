import gleam/list
import gleam/option
import gleam/string
import gleam/time/timestamp
import glot_core/language
import glot_core/loadable
import glot_core/pagination_model
import glot_core/snippet/snippet_dto
import glot_frontend/account/snippets/command
import glot_frontend/account/snippets/message
import glot_frontend/account/snippets/model
import glot_frontend/account/snippets/page
import glot_frontend/api/response
import lustre/element
import support/editor_fixture
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
    page.init_managed(
      after: option.None,
      before: option.None,
      language: option.Some("python"),
    )
  let scenario =
    managed_scenario.start(initial_model, initial_command, interpret)
  let assert [
    command.ListSnippets(request, snippets_loaded),
    command.Schedule(_, delay_elapsed),
  ] = managed_scenario.pending(scenario)
  assert request.pagination == pagination_model.InitialPage(limit: 20)
  assert request.languages == [language.Python]

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
  let #(model, _) =
    page.init_managed(
      after: option.None,
      before: option.None,
      language: option.None,
    )
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

pub fn language_filter_renders_and_is_preserved_by_pagination_test() {
  let #(initial, _) =
    page.init_managed(
      after: option.None,
      before: option.None,
      language: option.Some("javascript"),
    )
  let response =
    snippet_dto.ListSnippetsResponse(page: pagination_model.InitialCursorPage(
      items: [editor_fixture.snippet("fixture", "console.log(1)")],
      next_cursor: option.Some(pagination_model.from_string("next-page")),
    ))
  let #(loaded, _) =
    page.update_managed(
      initial,
      message.SnippetsLoaded(initial.request, response.Success(response)),
    )
  let rendered =
    page.view(loaded, timestamp.from_unix_seconds(300))
    |> element.to_document_string

  assert string.contains(rendered, "Filtered by JavaScript")
  assert string.contains(rendered, "Filter by language JavaScript")
  assert string.contains(rendered, "/account/snippets?language=javascript")

  let #(_, next) = page.update_managed(loaded, message.NextPageClicked)
  assert next
    == command.Navigate(
      "/account/snippets",
      option.Some("after=next-page&language=javascript"),
    )
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

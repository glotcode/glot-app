import gleam/dict
import gleam/option
import glot_backend/snippet/domain/list_session
import glot_backend/system/request/hydrated_context as request_context
import glot_core/language
import glot_core/pagination_model
import glot_core/snippet/snippet_dto
import glot_core/snippet/snippet_model
import support/integration/fixture
import support/integration/model
import support/integration/profile/snippet as runner
import support/integration/store/common

pub fn session_listing_filters_by_language_test() {
  let fixture =
    fixture.integration_fixture(
      next_uuids: [],
      jobs: [],
      account_delete_job_id: option.None,
    )
  let ruby =
    snippet_model.Snippet(
      ..fixture.snippet,
      id: fixture.must_uuid("00000000-0000-0000-0000-000000000019"),
      slug: "zz-snippet-ruby",
      title: "Ruby snippet",
      language: language.Ruby,
    )
  let state =
    model.TestState(
      ..fixture.state,
      snippets: fixture.state.snippets
        |> dict.insert(common.uuid_key(ruby.id), ruby),
    )
  let request =
    snippet_dto.ListSessionSnippetsRequest(
      pagination: pagination_model.InitialPage(10),
      languages: [language.Python],
    )

  let #(result, _) =
    runner.run_test_program(
      list_session.list_session_snippets(
        request_context.new(fixture.ctx, state.dynamic_config),
        request,
      ),
      fixture.ctx,
      state,
    )

  let assert Ok(response) = result
  let assert pagination_model.InitialCursorPage(items, option.None) =
    response.page
  assert items
    == [
      snippet_dto.from_snippet(snippet_model.HydratedSnippet(
        identity: fixture.snippet,
        user: fixture.user,
        is_runnable: option.None,
      )),
    ]
}

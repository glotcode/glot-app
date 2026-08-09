import gleam/dict
import gleam/option
import glot_backend/snippet/domain/list_public
import glot_backend/system/request/context
import glot_backend/system/request/hydrated_context as request_context
import glot_core/language
import glot_core/pagination_model
import glot_core/snippet/snippet_dto
import glot_core/snippet/snippet_model
import support/integration/fixture
import support/integration/model
import support/integration/profile/snippet as runner
import support/integration/store/common

pub fn public_listing_excludes_default_titles_and_plaintext_test() {
  let fixture =
    fixture.integration_fixture(
      next_uuids: [],
      jobs: [],
      account_delete_job_id: option.None,
    )
  let default_title =
    snippet_model.Snippet(
      ..fixture.snippet,
      id: fixture.must_uuid("00000000-0000-0000-0000-000000000014"),
      slug: "snippet-untitled",
      title: "Untitled",
    )
  let mixed_case_default_title =
    snippet_model.Snippet(
      ..fixture.snippet,
      id: fixture.must_uuid("00000000-0000-0000-0000-000000000015"),
      slug: "snippet-untitled-mixed-case",
      title: "uNtItLeD",
    )
  let hello_world =
    snippet_model.Snippet(
      ..fixture.snippet,
      id: fixture.must_uuid("00000000-0000-0000-0000-000000000016"),
      slug: "snippet-hello-world",
      title: "Hello World",
    )
  let untitled_snippet =
    snippet_model.Snippet(
      ..fixture.snippet,
      id: fixture.must_uuid("00000000-0000-0000-0000-000000000017"),
      slug: "snippet-untitled-snippet",
      title: "Untitled snippet",
    )
  let plaintext =
    snippet_model.Snippet(
      ..fixture.snippet,
      id: fixture.must_uuid("00000000-0000-0000-0000-000000000018"),
      slug: "snippet-plaintext",
      title: "Useful plaintext",
      language: language.Plaintext,
    )
  let ruby =
    snippet_model.Snippet(
      ..fixture.snippet,
      id: fixture.must_uuid("00000000-0000-0000-0000-000000000019"),
      slug: "zz-snippet-ruby",
      title: "Useful Ruby",
      language: language.Ruby,
    )
  let state =
    model.TestState(
      ..fixture.state,
      snippets: fixture.state.snippets
        |> dict.insert(common.uuid_key(default_title.id), default_title)
        |> dict.insert(
          common.uuid_key(mixed_case_default_title.id),
          mixed_case_default_title,
        )
        |> dict.insert(common.uuid_key(hello_world.id), hello_world)
        |> dict.insert(common.uuid_key(untitled_snippet.id), untitled_snippet)
        |> dict.insert(common.uuid_key(plaintext.id), plaintext)
        |> dict.insert(common.uuid_key(ruby.id), ruby),
    )
  let request =
    snippet_dto.ListPublicSnippetsRequest(
      pagination: pagination_model.InitialPage(10),
      usernames: [],
      languages: [language.Python],
    )

  let #(result, _) =
    runner.run_test_program(
      list_public.list_public_snippets(
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
      )),
    ]
}

pub fn public_listing_excludes_snippets_from_suspended_accounts_test() {
  let fixture =
    fixture.suspended_integration_fixture(
      next_uuids: [],
      jobs: [],
      account_delete_job_id: option.None,
    )
  let anonymous_ctx =
    context.Context(
      ..fixture.ctx,
      client_info: context.ClientInfo(
        ..fixture.ctx.client_info,
        session_token: option.None,
      ),
    )
  let request =
    snippet_dto.ListPublicSnippetsRequest(
      pagination: pagination_model.InitialPage(10),
      usernames: [],
      languages: [],
    )

  let #(result, _) =
    runner.run_test_program(
      list_public.list_public_snippets(
        request_context.new(anonymous_ctx, fixture.state.dynamic_config),
        request,
      ),
      anonymous_ctx,
      fixture.state,
    )

  let assert Ok(response) = result
  let assert pagination_model.InitialCursorPage([], option.None) = response.page
}

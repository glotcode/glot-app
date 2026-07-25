import gleam/dict
import gleam/option
import glot_backend/snippet/domain/get as get_snippet_domain
import glot_backend/system/effect/error
import glot_backend/system/effect/error/resource_error
import glot_backend/system/request/context
import glot_backend/system/request/hydrated_context as request_context
import glot_core/snippet/snippet_dto
import glot_core/snippet/snippet_model
import support/integration/fixture
import support/integration/model
import support/integration/profile/snippet as runner
import support/integration/store/common

pub fn owner_can_get_a_secret_snippet_test() {
  let fixture = secret_fixture()
  let #(result, _) =
    runner.run_test_program(
      get_snippet_domain.get_snippet(
        request_context.new(fixture.ctx, fixture.state.dynamic_config),
        snippet_dto.GetSnippetRequest(fixture.snippet.slug),
      ),
      fixture.ctx,
      fixture.state,
    )

  let assert Ok(response) = result
  assert response.data.visibility == snippet_model.Secret
}

pub fn anonymous_user_cannot_get_a_secret_snippet_test() {
  let fixture = secret_fixture()
  let anonymous_ctx =
    context.Context(
      ..fixture.ctx,
      client_info: context.ClientInfo(
        ..fixture.ctx.client_info,
        session_token: option.None,
      ),
    )
  let #(result, _) =
    runner.run_test_program(
      get_snippet_domain.get_snippet(
        request_context.new(anonymous_ctx, fixture.state.dynamic_config),
        snippet_dto.GetSnippetRequest(fixture.snippet.slug),
      ),
      anonymous_ctx,
      fixture.state,
    )

  assert result == Error(error.resource(resource_error.SnippetNotFound))
}

fn secret_fixture() {
  let fixture =
    fixture.integration_fixture(
      next_uuids: [],
      jobs: [],
      account_delete_job_id: option.None,
    )
  let secret =
    snippet_model.Snippet(..fixture.snippet, visibility: snippet_model.Secret)
  let state =
    model.TestState(
      ..fixture.state,
      snippets: dict.insert(
        fixture.state.snippets,
        common.uuid_key(secret.id),
        secret,
      ),
    )

  model.TestFixture(..fixture, state: state, snippet: secret)
}

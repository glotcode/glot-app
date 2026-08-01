import gleam/dict
import gleam/option
import glot_backend/snippet/domain/delete as delete_snippet_domain
import glot_backend/system/request/hydrated_context as request_context
import glot_core/snippet/snippet_dto
import support/integration/fixture
import support/integration/profile/snippet as runner
import support/integration/store/common

pub fn delete_snippet_deletes_the_snippet_and_records_the_action_test() {
  let user_action_id = fixture.must_uuid("00000000-0000-0000-0000-000000000697")
  let fixture =
    fixture.integration_fixture(
      next_uuids: [user_action_id],
      jobs: [],
      account_delete_job_id: option.None,
    )

  let #(run_result, db) =
    runner.run_test_program(
      delete_snippet_domain.delete_snippet(
        request_context.new(fixture.ctx, fixture.state.dynamic_config),
        snippet_dto.DeleteSnippetRequest(slug: fixture.snippet.slug),
      ),
      fixture.ctx,
      fixture.state,
    )

  assert run_result == Ok(Nil)
  assert dict.get(db.snippets, common.uuid_key(fixture.snippet.id))
    == Error(Nil)
  assert db.user_action_count == 1
}

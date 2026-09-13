import gleam/list
import gleam/option
import glot_backend/admin/domain/snippet/classify
import glot_backend/admin/domain/snippet/get
import glot_backend/auth/error as auth_error
import glot_backend/system/effect/error
import glot_backend/system/request/hydrated_context
import glot_core/admin/snippet_dto
import support/integration/fixture
import support/integration/profile/snippet as runner

pub fn regular_users_cannot_read_classification_evidence_or_reclassify_test() {
  let fixture =
    fixture.integration_fixture(
      next_uuids: [],
      jobs: [],
      account_delete_job_id: option.None,
    )
  let ctx = hydrated_context.new(fixture.ctx, fixture.state.dynamic_config)
  let request = snippet_dto.GetSnippetRequest(fixture.snippet.slug)
  list.each(
    [get.get_snippet(ctx, request), classify.classify_snippet(ctx, request)],
    fn(program) {
      let #(result, _) =
        runner.run_test_program(program, fixture.ctx, fixture.state)
      assert result == Error(error.auth(auth_error.AdminRequired))
    },
  )
}

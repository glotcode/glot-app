import gleam/dict
import gleam/option
import glot_backend/snippet/domain/update as update_snippet_domain
import glot_backend/system/effect/error
import glot_backend/system/request/hydrated_context as request_context
import glot_core/language
import glot_core/snippet/snippet_dto
import glot_core/snippet/snippet_model
import glot_core/validation_error
import support/integration/fixture
import support/integration/profile/snippet as runner
import support/integration/store/common

pub fn update_snippet_updates_the_snippet_and_records_the_action_test() {
  let user_action_id = fixture.must_uuid("00000000-0000-0000-0000-000000000698")
  let fixture =
    fixture.integration_fixture(
      next_uuids: [user_action_id],
      jobs: [],
      account_delete_job_id: option.None,
    )
  let request =
    snippet_dto.UpdateSnippetRequest(
      slug: fixture.snippet.slug,
      data: snippet_dto.SnippetData(
        title: "Updated snippet",
        language: language.Python,
        visibility: snippet_model.Unlisted,
        stdin: "input",
        run_instructions: option.None,
        files: [snippet_model.File(name: "main.py", content: "print(2)")],
      ),
    )

  let #(run_result, db) =
    runner.run_test_program(
      update_snippet_domain.update_snippet(
        request_context.new(fixture.ctx, fixture.state.dynamic_config),
        request,
      ),
      fixture.ctx,
      fixture.state,
    )

  let assert Ok(response) = run_result
  let assert Ok(updated) =
    dict.get(db.snippets, common.uuid_key(fixture.snippet.id))
  assert response.data.title == "Updated snippet"
  assert updated.title == "Updated snippet"
  assert updated.visibility == snippet_model.Unlisted
  assert db.user_action_count == 1
}

pub fn update_snippet_rejects_too_long_file_content_test() {
  let fixture =
    fixture.integration_fixture(
      next_uuids: [],
      jobs: [],
      account_delete_job_id: option.None,
    )
  let request =
    snippet_dto.UpdateSnippetRequest(
      slug: fixture.snippet.slug,
      data: snippet_dto.SnippetData(
        title: "Snippet",
        language: language.Python,
        visibility: snippet_model.Public,
        stdin: "",
        run_instructions: option.None,
        files: [
          snippet_model.File(
            name: "main.py",
            content: fixture.repeat_string("a", 100_001),
          ),
        ],
      ),
    )

  let #(run_result, db) =
    runner.run_test_program(
      update_snippet_domain.update_snippet(
        request_context.new(fixture.ctx, fixture.state.dynamic_config),
        request,
      ),
      fixture.ctx,
      fixture.state,
    )

  assert run_result
    == Error(
      error.validation(validation_error.FieldTooLong(
        "files[0].content",
        100_000,
      )),
    )
  assert db.write_steps == []
}

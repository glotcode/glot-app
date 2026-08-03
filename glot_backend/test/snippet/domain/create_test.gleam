import gleam/dict
import gleam/option
import glot_backend/snippet/domain/create as create_snippet_domain
import glot_backend/system/effect/error
import glot_backend/system/request/hydrated_context as request_context
import glot_core/language
import glot_core/snippet/snippet_dto
import glot_core/snippet/snippet_model
import glot_core/validation_error
import support/integration/fixture
import support/integration/profile/snippet as runner
import support/integration/store/common

pub fn create_snippet_runs_through_service_ports_test() {
  let snippet_id = fixture.must_uuid("00000000-0000-0000-0000-000000000700")
  let user_action_id = fixture.must_uuid("00000000-0000-0000-0000-000000000699")
  let fixture =
    fixture.integration_fixture(
      next_uuids: [user_action_id, snippet_id],
      jobs: [],
      account_delete_job_id: option.None,
    )
  let request =
    snippet_dto.CreateSnippetRequest(
      data: snippet_dto.SnippetData(
        title: "Created through adapters",
        language: language.Python,
        visibility: snippet_model.Public,
        stdin: "",
        run_instructions: option.None,
        files: [snippet_model.File(name: "main.py", content: "print(1)")],
      ),
    )

  let #(run_result, db) =
    runner.run_test_program(
      create_snippet_domain.create_snippet(
        request_context.new(fixture.ctx, fixture.state.dynamic_config),
        request,
      ),
      fixture.ctx,
      fixture.state,
    )

  let assert Ok(_) = run_result
  assert dict.has_key(db.snippets, common.uuid_key(snippet_id))
  assert db.next_uuids == []
}

pub fn create_snippet_rejects_empty_files_test() {
  let fixture =
    fixture.integration_fixture(
      next_uuids: [fixture.must_uuid("00000000-0000-0000-0000-000000000701")],
      jobs: [],
      account_delete_job_id: option.None,
    )
  let request =
    snippet_dto.CreateSnippetRequest(
      data: snippet_dto.SnippetData(
        title: "Snippet",
        language: language.Python,
        visibility: snippet_model.Public,
        stdin: "",
        run_instructions: option.None,
        files: [],
      ),
    )

  let #(run_result, db) =
    runner.run_test_program(
      create_snippet_domain.create_snippet(
        request_context.new(fixture.ctx, fixture.state.dynamic_config),
        request,
      ),
      fixture.ctx,
      fixture.state,
    )

  assert run_result == Error(error.validation(validation_error.FilesMissing))
  assert db.write_steps == []
}

pub fn create_snippet_rejects_too_long_title_test() {
  let fixture =
    fixture.integration_fixture(
      next_uuids: [fixture.must_uuid("00000000-0000-0000-0000-000000000702")],
      jobs: [],
      account_delete_job_id: option.None,
    )
  let request =
    snippet_dto.CreateSnippetRequest(
      data: snippet_dto.SnippetData(
        title: fixture.repeat_string("a", 201),
        language: language.Python,
        visibility: snippet_model.Public,
        stdin: "",
        run_instructions: option.None,
        files: [snippet_model.File(name: "main.py", content: "print(1)")],
      ),
    )

  let #(run_result, db) =
    runner.run_test_program(
      create_snippet_domain.create_snippet(
        request_context.new(fixture.ctx, fixture.state.dynamic_config),
        request,
      ),
      fixture.ctx,
      fixture.state,
    )

  assert run_result
    == Error(error.validation(validation_error.FieldTooLong("title", 200)))
  assert db.write_steps == []
}

pub fn create_snippet_rejects_plaintext_test() {
  let fixture =
    fixture.integration_fixture(
      next_uuids: [fixture.must_uuid("00000000-0000-0000-0000-000000000703")],
      jobs: [],
      account_delete_job_id: option.None,
    )
  let request =
    snippet_dto.CreateSnippetRequest(
      data: snippet_dto.SnippetData(
        title: "Legacy-only language",
        language: language.Plaintext,
        visibility: snippet_model.Unlisted,
        stdin: "",
        run_instructions: option.None,
        files: [snippet_model.File(name: "main.txt", content: "archive")],
      ),
    )

  let #(run_result, db) =
    runner.run_test_program(
      create_snippet_domain.create_snippet(
        request_context.new(fixture.ctx, fixture.state.dynamic_config),
        request,
      ),
      fixture.ctx,
      fixture.state,
    )

  assert run_result
    == Error(error.validation(validation_error.ReadOnlyLanguage("plaintext")))
  assert db.write_steps == []
}

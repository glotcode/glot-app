import gleam/option
import gleam/time/timestamp
import glot_core/admin/job_dto
import glot_core/admin/job_type_policy_dto
import glot_core/loadable
import glot_frontend/admin/command
import glot_frontend/admin/effect/config
import glot_frontend/admin/effect/jobs
import glot_frontend/admin/jobs/managed as job_managed
import glot_frontend/admin/jobs/message as job_message
import glot_frontend/admin/jobs/model as job_detail_model
import glot_frontend/admin/jobs/policies_managed
import glot_frontend/admin/jobs/policies_message
import glot_frontend/admin/jobs/policies_model
import glot_frontend/admin/jobs/policies_policy
import glot_frontend/api/response
import glot_frontend/request_generation
import glot_frontend/ui/mutation
import youid/uuid

pub fn job_policy_mutation_covers_validation_failure_retry_and_success_test() {
  let #(initial, _) = policies_managed.init()
  let #(loading, load_command) = policies_managed.ensure_loaded(initial)
  let assert command.Config(config.GetJobTypePolicies(loaded)) = load_command
  let #(loaded_model, _) =
    policies_managed.update(
      loading,
      loaded(
        response.Success(
          job_type_policy_dto.ListJobTypePoliciesResponse([
            policy_fixture(3),
          ]),
        ),
      ),
    )

  let #(invalid_model, _) =
    policies_managed.update(
      loaded_model,
      policies_message.FieldChanged(
        "fixture",
        policies_model.MaxAttemptsField,
        "0",
      ),
    )
  let #(invalid_model, invalid_command) =
    policies_managed.update(
      invalid_model,
      policies_message.SaveClicked("fixture"),
    )
  assert invalid_command == command.None
  let invalid_editor = editor(invalid_model)
  assert invalid_editor.state
    == mutation.SaveError("Max attempts must be greater than zero.")

  let #(valid_model, _) =
    policies_managed.update(
      invalid_model,
      policies_message.FieldChanged(
        "fixture",
        policies_model.MaxAttemptsField,
        "4",
      ),
    )
  let #(saving_model, save_command) =
    policies_managed.update(
      valid_model,
      policies_message.SaveClicked("fixture"),
    )
  let assert command.Config(config.UpsertJobTypePolicy(request, complete)) =
    save_command
  assert request.max_attempts == 4
  assert editor(saving_model).state == mutation.Saving

  let #(failed_model, _) =
    policies_managed.update(
      saving_model,
      complete(api_failure("Save rejected.")),
    )
  let assert mutation.SaveError(message) = editor(failed_model).state
  assert message
    == "Save rejected. Request ID: 00000000-0000-4000-8000-000000000099"

  let #(retrying_model, retry_command) =
    policies_managed.update(
      failed_model,
      policies_message.SaveClicked("fixture"),
    )
  let assert command.Config(config.UpsertJobTypePolicy(_, retry_complete)) =
    retry_command
  let #(saved_model, _) =
    policies_managed.update(
      retrying_model,
      retry_complete(response.Success(policy_fixture(4))),
    )
  assert editor(saved_model).state == mutation.Saved
  assert editor(saved_model).saved.max_attempts == "4"
}

pub fn edited_job_policy_ignores_an_in_flight_save_response_test() {
  let model =
    policies_model.Model(
      policies: loadable.Loaded([
        policies_policy.editor_from_response(policy_fixture(3)),
      ]),
      load_generation: request_generation.initial(),
    )
  let #(saving, save_command) =
    policies_managed.update(model, policies_message.SaveClicked("fixture"))
  let assert command.Config(config.UpsertJobTypePolicy(_, complete)) =
    save_command
  let #(edited, _) =
    policies_managed.update(
      saving,
      policies_message.FieldChanged(
        "fixture",
        policies_model.TimeoutSecondsField,
        "90",
      ),
    )
  let #(unchanged, next_command) =
    policies_managed.update(
      edited,
      complete(response.Success(policy_fixture(3))),
    )
  assert unchanged == edited
  assert next_command == command.None
}

pub fn create_job_mutation_covers_cancel_failure_retry_and_success_test() {
  let id = job_id()
  let #(base, _) = job_managed.init(id)
  let editor = create_job_editor(id)
  let initial =
    job_detail_model.Model(..base, create_job_editor: option.Some(editor))
  let #(cancelled, cancel_command) =
    job_managed.update(initial, job_message.CreateJobCancelled)
  assert cancelled.create_job_editor == option.None
  assert cancel_command
    == command.CloseDialog("admin-job-page-create-job-dialog")

  let #(parsing, parse_command) =
    job_managed.update(initial, job_message.CreateJobSubmitted)
  let assert command.ParseLocalDateTime(_, _, parsed) = parse_command
  let now = timestamp.from_unix_seconds(100)
  let #(saving, save_command) =
    job_managed.update(parsing, parsed(option.Some(now)))
  let assert command.Jobs(jobs.CreateJob(request, complete)) = save_command
  assert request.max_attempts == 3

  let #(failed, _) =
    job_managed.update(saving, complete(api_failure("Job rejected.")))
  let assert option.Some(failed_editor) = failed.create_job_editor
  let assert job_detail_model.CreateJobError(_) = failed_editor.state

  let #(retry_parsing, retry_parse_command) =
    job_managed.update(failed, job_message.CreateJobSubmitted)
  let assert command.ParseLocalDateTime(_, _, retry_parsed) =
    retry_parse_command
  let #(retrying, retry_command) =
    job_managed.update(retry_parsing, retry_parsed(option.Some(now)))
  let assert command.Jobs(jobs.CreateJob(_, retry)) = retry_command
  let #(saved, success_command) =
    job_managed.update(
      retrying,
      retry(response.Success(job_dto.GetJobResponse(job_fixture(id)))),
    )
  assert saved.create_job_editor == option.None
  let assert command.Batch([command.CloseDialog(_), command.Navigate(_)]) =
    success_command
}

fn editor(model: policies_model.Model) -> policies_model.PolicyEditor {
  let assert option.Some(editor) =
    policies_policy.find_editor(
      policies_policy.loaded_policies(model),
      "fixture",
    )
  editor
}

fn policy_fixture(
  max_attempts: Int,
) -> job_type_policy_dto.JobTypePolicyResponse {
  let now = timestamp.from_unix_seconds(0)
  job_type_policy_dto.JobTypePolicyResponse(
    job_type: "fixture",
    queue_name: "default",
    max_attempts: max_attempts,
    timeout_seconds: 60,
    base_backoff_seconds: 1,
    max_backoff_seconds: 30,
    created_at: now,
    updated_at: now,
  )
}

fn create_job_editor(id: uuid.Uuid) -> job_detail_model.CreateJobEditor {
  job_detail_model.CreateJobEditor(
    source_job_id: id,
    draft: job_detail_model.CreateJobDraft(
      periodic_job_id: option.None,
      job_type: "fixture",
      payload: "",
      max_attempts: "3",
      timeout_seconds: "60",
      run_date: "2026-07-22",
      run_time: "12:30",
    ),
    state: job_detail_model.CreateJobIdle,
  )
}

fn job_fixture(id: uuid.Uuid) -> job_dto.JobDetailResponse {
  let now = timestamp.from_unix_seconds(100)
  job_dto.JobDetailResponse(
    id: id,
    request_id: option.None,
    periodic_job_id: option.None,
    job_type: "fixture",
    queue_name: "default",
    dedupe_key: option.None,
    payload: option.None,
    status: "pending",
    attempts: 0,
    max_attempts: 3,
    timeout_seconds: 60,
    run_at: now,
    started_at: option.None,
    lease_expires_at: option.None,
    completed_at: option.None,
    timed_out_at: option.None,
    last_error: option.None,
    created_at: now,
    updated_at: now,
    overdue: False,
  )
}

fn job_id() -> uuid.Uuid {
  let assert Ok(id) = uuid.from_string("00000000-0000-4000-8000-000000000094")
  id
}

fn api_failure(message: String) -> response.Response(value) {
  let assert Ok(id) = uuid.from_string("00000000-0000-4000-8000-000000000099")
  response.ApiFailure(response.Error("fixture", message, id))
}

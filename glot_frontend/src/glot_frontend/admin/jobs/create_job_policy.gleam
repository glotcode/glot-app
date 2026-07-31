import gleam/int
import gleam/option
import gleam/result
import gleam/time/timestamp.{type Timestamp}
import glot_core/admin/job_dto
import glot_frontend/admin/jobs/model.{
  type CreateJobEditor, type CreateJobState, type Model, CreateJobDraft,
  CreateJobEditor, CreateJobError, CreateJobIdle, CreateJobSaved,
  CreateJobSaving, Model,
}
import glot_frontend/admin/local_datetime.{type LocalDateTime}
import glot_frontend/admin/ui/format as admin_format
import glot_frontend/request_generation

pub fn reset_state(state: CreateJobState) -> CreateJobState {
  case state {
    CreateJobSaving | CreateJobIdle -> CreateJobIdle
    CreateJobError(_) | CreateJobSaved(_) -> CreateJobIdle
  }
}

pub fn update_model(
  model: Model,
  update: fn(CreateJobEditor) -> CreateJobEditor,
) -> Model {
  case model.create_job_editor {
    option.Some(editor) ->
      Model(
        ..model,
        create_job_editor: option.Some(update(editor)),
        create_generation: request_generation.next(model.create_generation),
      )
    option.None -> model
  }
}

pub fn from_job(
  job: job_dto.JobDetailResponse,
  local: LocalDateTime,
) -> CreateJobEditor {
  let local_datetime.LocalDateTime(date:, time:) = local
  CreateJobEditor(
    source_job_id: job.id,
    draft: CreateJobDraft(
      periodic_job_id: job.periodic_job_id,
      job_type: job.job_type,
      payload: option.unwrap(job.payload, ""),
      max_attempts: int.to_string(job.max_attempts),
      timeout_seconds: int.to_string(job.timeout_seconds),
      run_date: date,
      run_time: time,
    ),
    state: CreateJobIdle,
  )
}

pub fn to_request(
  editor: CreateJobEditor,
  run_at: Timestamp,
) -> Result(job_dto.CreateJobRequest, String) {
  use max_attempts <- result.try(admin_format.parse_positive_int(
    editor.draft.max_attempts,
    "Max attempts",
  ))
  use timeout_seconds <- result.try(admin_format.parse_positive_int(
    editor.draft.timeout_seconds,
    "Timeout seconds",
  ))
  Ok(job_dto.CreateJobRequest(
    periodic_job_id: editor.draft.periodic_job_id,
    job_type: editor.draft.job_type,
    payload: optional_payload(editor.draft.payload),
    max_attempts: max_attempts,
    timeout_seconds: timeout_seconds,
    run_at: run_at,
  ))
}

pub fn validate(editor: CreateJobEditor) -> Result(Nil, String) {
  use _ <- result.try(admin_format.parse_positive_int(
    editor.draft.max_attempts,
    "Max attempts",
  ))
  use _ <- result.try(admin_format.parse_positive_int(
    editor.draft.timeout_seconds,
    "Timeout seconds",
  ))
  case editor.draft.run_date == "" || editor.draft.run_time == "" {
    True -> Error("Run date and time are required.")
    False -> Ok(Nil)
  }
}

fn optional_payload(value: String) -> option.Option(String) {
  case value == "" {
    True -> option.None
    False -> option.Some(value)
  }
}

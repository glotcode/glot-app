import gleam/int
import gleam/option
import gleam/result
import gleam/time/timestamp
import glot_core/admin/periodic_job_dto
import glot_frontend/admin/local_datetime.{type LocalDateTime}
import glot_frontend/admin/periodic_jobs/model.{
  type Model, type PeriodicJobEditor, type PeriodicJobFields, Idle, Model,
  PeriodicJobEditor, PeriodicJobFields, PeriodicJobMetadata,
}
import glot_frontend/admin/ui/format as admin_format
import glot_frontend/request_generation

pub fn update_model(
  model: Model,
  update: fn(PeriodicJobEditor) -> PeriodicJobEditor,
) -> Model {
  case model.periodic_job {
    option.None -> model
    option.Some(editor) ->
      Model(
        ..model,
        periodic_job: option.Some(update(editor)),
        save_generation: request_generation.next(model.save_generation),
      )
  }
}

pub fn from_response(
  periodic_job: periodic_job_dto.PeriodicJobResponse,
  local: LocalDateTime,
) -> PeriodicJobEditor {
  let fields = fields_from_response(periodic_job, local)

  PeriodicJobEditor(
    id: periodic_job.id,
    job_type: periodic_job.job_type,
    saved: fields,
    draft: fields,
    metadata: PeriodicJobMetadata(
      next_run_at: periodic_job.next_run_at,
      last_enqueued_at: periodic_job.last_enqueued_at,
      last_enqueue_error: periodic_job.last_enqueue_error,
      created_at: periodic_job.created_at,
      updated_at: periodic_job.updated_at,
    ),
    state: Idle,
  )
}

fn fields_from_response(
  periodic_job: periodic_job_dto.PeriodicJobResponse,
  local: LocalDateTime,
) -> PeriodicJobFields {
  let local_datetime.LocalDateTime(date:, time:) = local
  PeriodicJobFields(
    payload: option.unwrap(periodic_job.payload, ""),
    interval_seconds: int.to_string(periodic_job.interval_seconds),
    enabled: periodic_job.enabled,
    next_run_date: date,
    next_run_time: time,
  )
}

pub fn to_request(
  editor: PeriodicJobEditor,
  next_run_at: timestamp.Timestamp,
) -> Result(periodic_job_dto.UpdatePeriodicJobRequest, String) {
  use interval_seconds <- result.try(admin_format.parse_positive_int(
    editor.draft.interval_seconds,
    "Interval seconds",
  ))
  Ok(periodic_job_dto.UpdatePeriodicJobRequest(
    id: editor.id,
    payload: optional_payload(editor.draft.payload),
    interval_seconds: interval_seconds,
    enabled: editor.draft.enabled,
    next_run_at: next_run_at,
  ))
}

pub fn validate(editor: PeriodicJobEditor) -> Result(Nil, String) {
  use _ <- result.try(admin_format.parse_positive_int(
    editor.draft.interval_seconds,
    "Interval seconds",
  ))
  case editor.draft.next_run_date == "" || editor.draft.next_run_time == "" {
    True -> Error("Next run date and time are required.")
    False -> Ok(Nil)
  }
}

fn optional_payload(value: String) -> option.Option(String) {
  case value == "" {
    True -> option.None
    False -> option.Some(value)
  }
}

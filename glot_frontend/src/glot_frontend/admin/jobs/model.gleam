import gleam/option
import glot_core/admin/job_dto
import glot_core/admin/job_log_dto
import glot_core/pagination_model
import glot_frontend/request_generation.{type Generation}
import youid/uuid

pub type Model {
  Model(
    job_id: uuid.Uuid,
    job: option.Option(job_dto.JobDetailResponse),
    job_status: Status,
    logs_page: pagination_model.CursorPage(job_log_dto.JobLogResponse),
    logs_status: Status,
    create_job_editor: option.Option(CreateJobEditor),
    logs_generation: Generation(LogsStream),
    create_generation: Generation(CreateStream),
  )
}

pub type LogsStream {
  LogsStream
}

pub type CreateStream {
  CreateStream
}

pub type Status {
  NotLoaded
  Loading
  Ready
  LoadError(String)
}

pub type CreateJobEditor {
  CreateJobEditor(
    source_job_id: uuid.Uuid,
    draft: CreateJobDraft,
    state: CreateJobState,
  )
}

pub type CreateJobDraft {
  CreateJobDraft(
    periodic_job_id: option.Option(uuid.Uuid),
    job_type: String,
    payload: String,
    max_attempts: String,
    timeout_seconds: String,
    run_date: String,
    run_time: String,
  )
}

pub type CreateJobState {
  CreateJobIdle
  CreateJobSaving
  CreateJobError(String)
  CreateJobSaved(job_dto.JobDetailResponse)
}

pub fn is_presentable(model: Model) -> Bool {
  case model.job_status {
    Ready | LoadError(_) -> True
    NotLoaded | Loading -> False
  }
}

import gleam/option
import gleam/time/timestamp
import glot_core/admin/job_dto
import glot_frontend/request_generation.{type Generation}
import youid/uuid

pub type Model {
  Model(
    id: uuid.Uuid,
    periodic_job: option.Option(PeriodicJobEditor),
    status: Status,
    recent_jobs: List(job_dto.JobResponse),
    jobs_status: Status,
    job_generation: Generation(JobStream),
    recent_jobs_generation: Generation(RecentJobsStream),
    save_generation: Generation(SaveStream),
  )
}

pub type JobStream {
  JobStream
}

pub type RecentJobsStream {
  RecentJobsStream
}

pub type SaveStream {
  SaveStream
}

pub type Status {
  NotLoaded
  Loading
  Ready
  LoadError(String)
}

pub type PeriodicJobEditor {
  PeriodicJobEditor(
    id: uuid.Uuid,
    job_type: String,
    saved: PeriodicJobFields,
    draft: PeriodicJobFields,
    metadata: PeriodicJobMetadata,
    state: EditorState,
  )
}

pub type PeriodicJobFields {
  PeriodicJobFields(
    payload: String,
    interval_seconds: String,
    enabled: Bool,
    next_run_date: String,
    next_run_time: String,
  )
}

pub type PeriodicJobMetadata {
  PeriodicJobMetadata(
    next_run_at: timestamp.Timestamp,
    last_enqueued_at: option.Option(timestamp.Timestamp),
    last_enqueue_error: option.Option(String),
    created_at: timestamp.Timestamp,
    updated_at: timestamp.Timestamp,
  )
}

pub type EditorState {
  Idle
  Saving
  Saved
  SaveError(String)
}

pub fn is_presentable(model: Model) -> Bool {
  case model.status {
    Ready | LoadError(_) -> True
    NotLoaded | Loading -> False
  }
}

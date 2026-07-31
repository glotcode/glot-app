import gleam/option
import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/jobs/create_update
import glot_frontend/admin/jobs/loading_update
import glot_frontend/admin/jobs/message.{
  CreateJobCancelled, CreateJobDialogClosed, CreateJobFinished,
  CreateJobMaxAttemptsChanged, CreateJobPayloadChanged, CreateJobRunAtParsed,
  CreateJobRunDateChanged, CreateJobRunTimeChanged, CreateJobSubmitted,
  CreateJobTimeoutSecondsChanged, JobLoaded, JobLogsLoaded, NextLogsPageClicked,
  OpenCreateJobAt, OpenCreateJobClicked, OpenCreateJobWithLocalDateTime,
  PreviousLogsPageClicked,
}
import glot_frontend/admin/jobs/model.{Model, NotLoaded}
import glot_frontend/request_generation
import youid/uuid

pub type Model =
  model.Model

pub type Msg =
  message.Msg

pub fn init(job_id: uuid.Uuid) -> #(Model, admin_effect.Command(Msg)) {
  #(
    Model(
      job_id:,
      job: option.None,
      job_status: NotLoaded,
      logs_page: loading_update.empty_logs_page(),
      logs_status: NotLoaded,
      create_job_editor: option.None,
      logs_generation: request_generation.initial(),
      create_generation: request_generation.initial(),
    ),
    admin_effect.none(),
  )
}

pub fn ensure_loaded(model: Model) {
  loading_update.ensure_loaded(model)
}

pub fn update(model: Model, msg: Msg) {
  case msg {
    JobLoaded(_)
    | JobLogsLoaded(_, _)
    | NextLogsPageClicked
    | PreviousLogsPageClicked -> loading_update.update(model, msg)
    OpenCreateJobClicked
    | OpenCreateJobAt(_)
    | OpenCreateJobWithLocalDateTime(_)
    | CreateJobDialogClosed
    | CreateJobCancelled
    | CreateJobSubmitted
    | CreateJobRunAtParsed(_, _)
    | CreateJobFinished(_, _)
    | CreateJobPayloadChanged(_)
    | CreateJobMaxAttemptsChanged(_)
    | CreateJobTimeoutSecondsChanged(_)
    | CreateJobRunDateChanged(_)
    | CreateJobRunTimeChanged(_) -> create_update.update(model, msg)
  }
}

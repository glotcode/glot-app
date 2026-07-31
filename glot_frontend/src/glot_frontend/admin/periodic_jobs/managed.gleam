import gleam/option
import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/periodic_jobs/editor_update
import glot_frontend/admin/periodic_jobs/loading_update
import glot_frontend/admin/periodic_jobs/message.{
  EnabledToggled, IntervalSecondsChanged, LoadedPeriodicJobFormatted,
  NextRunAtParsed, NextRunDateChanged, NextRunTimeChanged, PayloadChanged,
  PeriodicJobLoaded, RecentJobsLoaded, ResetClicked, SaveClicked, SaveFinished,
  SavedPeriodicJobFormatted,
}
import glot_frontend/admin/periodic_jobs/model.{Model, NotLoaded}
import glot_frontend/request_generation
import youid/uuid

pub type Model =
  model.Model

pub type Msg =
  message.Msg

pub fn init(id: uuid.Uuid) -> #(Model, admin_effect.Command(Msg)) {
  #(
    Model(
      id:,
      periodic_job: option.None,
      status: NotLoaded,
      recent_jobs: [],
      jobs_status: NotLoaded,
      job_generation: request_generation.initial(),
      recent_jobs_generation: request_generation.initial(),
      save_generation: request_generation.initial(),
    ),
    admin_effect.none(),
  )
}

pub fn ensure_loaded(model: Model) {
  loading_update.ensure_loaded(model)
}

pub fn update(model: Model, msg: Msg) {
  case msg {
    PeriodicJobLoaded(_, _)
    | LoadedPeriodicJobFormatted(_, _, _)
    | RecentJobsLoaded(_, _) -> loading_update.update(model, msg)
    PayloadChanged(_)
    | IntervalSecondsChanged(_)
    | EnabledToggled
    | NextRunDateChanged(_)
    | NextRunTimeChanged(_)
    | ResetClicked
    | SaveClicked
    | NextRunAtParsed(_, _)
    | SaveFinished(_, _)
    | SavedPeriodicJobFormatted(_, _, _) -> editor_update.update(model, msg)
  }
}

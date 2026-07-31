import gleam/option
import glot_core/admin/job_dto
import glot_core/admin/periodic_job_dto
import glot_core/pagination_model
import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/periodic_jobs/editor_policy
import glot_frontend/admin/periodic_jobs/message.{
  LoadedPeriodicJobFormatted, PeriodicJobLoaded, RecentJobsLoaded,
}
import glot_frontend/admin/periodic_jobs/model.{
  type Model, type RecentJobsStream, LoadError, Loading, Model, NotLoaded, Ready,
}
import glot_frontend/api/response as api_response
import glot_frontend/request_generation.{type Generation}
import youid/uuid

pub fn ensure_loaded(
  model: Model,
) -> #(Model, admin_effect.Command(message.Msg)) {
  let load_job = model.status == NotLoaded
  let load_recent = model.jobs_status == NotLoaded
  let job_generation = case load_job {
    True -> request_generation.next(model.job_generation)
    False -> model.job_generation
  }
  let recent_generation = case load_recent {
    True -> request_generation.next(model.recent_jobs_generation)
    False -> model.recent_jobs_generation
  }
  case load_job || load_recent {
    False -> #(model, admin_effect.none())
    True -> #(
      Model(
        ..model,
        status: case load_job {
          True -> Loading
          False -> model.status
        },
        jobs_status: case load_recent {
          True -> Loading
          False -> model.jobs_status
        },
        job_generation:,
        recent_jobs_generation: recent_generation,
      ),
      admin_effect.batch([
        case load_job {
          True ->
            admin_effect.get_admin_periodic_job(
              periodic_job_dto.GetPeriodicJobRequest(id: model.id),
              fn(result) { PeriodicJobLoaded(job_generation, result) },
            )
          False -> admin_effect.none()
        },
        case load_recent {
          True -> load_recent_jobs(model.id, recent_generation)
          False -> admin_effect.none()
        },
      ]),
    )
  }
}

pub fn update(
  model: Model,
  msg: message.Msg,
) -> #(Model, admin_effect.Command(message.Msg)) {
  case msg {
    PeriodicJobLoaded(generation, _) if generation != model.job_generation -> #(
      model,
      admin_effect.none(),
    )
    PeriodicJobLoaded(generation, result) ->
      case result {
        api_response.Success(response) -> #(
          model,
          admin_effect.FormatLocalDateTime(
            response.periodic_job.next_run_at,
            fn(local) {
              LoadedPeriodicJobFormatted(
                generation,
                response.periodic_job,
                local,
              )
            },
          ),
        )
        api_response.ApiFailure(error) -> #(
          Model(..model, status: LoadError(api_response.error_message(error))),
          admin_effect.none(),
        )
        api_response.HttpFailure(_) -> #(
          Model(..model, status: LoadError("Could not load periodic job.")),
          admin_effect.none(),
        )
      }
    LoadedPeriodicJobFormatted(generation, _, _)
      if generation != model.job_generation
    -> #(model, admin_effect.none())
    LoadedPeriodicJobFormatted(_, periodic_job, local) -> #(
      Model(
        ..model,
        periodic_job: option.Some(editor_policy.from_response(
          periodic_job,
          local,
        )),
        status: Ready,
      ),
      admin_effect.none(),
    )
    RecentJobsLoaded(generation, _)
      if generation != model.recent_jobs_generation
    -> #(model, admin_effect.none())
    RecentJobsLoaded(_, result) ->
      case result {
        api_response.Success(response) -> #(
          Model(
            ..model,
            recent_jobs: pagination_model.items(response.page),
            jobs_status: Ready,
          ),
          admin_effect.none(),
        )
        api_response.ApiFailure(error) -> #(
          Model(
            ..model,
            jobs_status: LoadError(api_response.error_message(error)),
          ),
          admin_effect.none(),
        )
        api_response.HttpFailure(_) -> #(
          Model(..model, jobs_status: LoadError("Could not load recent jobs.")),
          admin_effect.none(),
        )
      }
    _ -> #(model, admin_effect.none())
  }
}

fn load_recent_jobs(id: uuid.Uuid, generation: Generation(RecentJobsStream)) {
  admin_effect.get_admin_jobs(
    job_dto.ListJobsRequest(
      pagination: pagination_model.InitialPage(limit: 10),
      status_filter: job_dto.AllStatuses,
      job_type_filter: option.None,
      periodic_job_id: option.Some(id),
    ),
    fn(result) { RecentJobsLoaded(generation, result) },
  )
}

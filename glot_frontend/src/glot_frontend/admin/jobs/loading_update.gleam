import gleam/option
import glot_core/admin/job_dto
import glot_core/admin/job_log_dto
import glot_core/pagination_model
import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/jobs/message.{
  JobLoaded, JobLogsLoaded, NextLogsPageClicked, PreviousLogsPageClicked,
}
import glot_frontend/admin/jobs/model.{
  type LogsStream, type Model, type Status, LoadError, Loading, Model, NotLoaded,
  Ready,
}
import glot_frontend/api/response as api_response
import glot_frontend/request_generation.{type Generation}

const job_logs_page_limit = 25

pub fn ensure_loaded(
  model: Model,
) -> #(Model, admin_effect.Command(message.Msg)) {
  let should_load_job = model.job_status == NotLoaded
  let should_load_logs = model.logs_status == NotLoaded
  let logs_generation = case should_load_logs {
    True -> request_generation.next(model.logs_generation)
    False -> model.logs_generation
  }
  case should_load_job || should_load_logs {
    False -> #(model, admin_effect.none())
    True -> #(
      Model(
        ..model,
        job_status: loading_status(model.job_status),
        logs_status: loading_status(model.logs_status),
        logs_generation:,
      ),
      admin_effect.batch([
        case should_load_job {
          True ->
            admin_effect.get_admin_job(
              job_dto.GetJobRequest(id: model.job_id),
              JobLoaded,
            )
          False -> admin_effect.none()
        },
        case should_load_logs {
          True ->
            get_job_logs(
              model,
              pagination_model.InitialPage(limit: job_logs_page_limit),
              logs_generation,
            )
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
    JobLoaded(result) ->
      case result {
        api_response.Success(response) -> #(
          Model(..model, job: option.Some(response.job), job_status: Ready),
          admin_effect.none(),
        )
        api_response.ApiFailure(error) -> #(
          Model(
            ..model,
            job_status: LoadError(api_response.error_message(error)),
          ),
          admin_effect.none(),
        )
        api_response.HttpFailure(_) -> #(
          Model(..model, job_status: LoadError("Could not load job.")),
          admin_effect.none(),
        )
      }
    JobLogsLoaded(generation, _) if generation != model.logs_generation -> #(
      model,
      admin_effect.none(),
    )
    JobLogsLoaded(_, result) ->
      case result {
        api_response.Success(response) -> #(
          Model(..model, logs_page: response.page, logs_status: Ready),
          admin_effect.none(),
        )
        api_response.ApiFailure(error) -> #(
          Model(
            ..model,
            logs_status: LoadError(api_response.error_message(error)),
          ),
          admin_effect.none(),
        )
        api_response.HttpFailure(_) -> #(
          Model(..model, logs_status: LoadError("Could not load job logs.")),
          admin_effect.none(),
        )
      }
    NextLogsPageClicked ->
      case pagination_model.next_cursor(model.logs_page) {
        option.Some(cursor) ->
          load_page(
            model,
            pagination_model.AfterPage(cursor:, limit: job_logs_page_limit),
          )
        option.None -> #(model, admin_effect.none())
      }
    PreviousLogsPageClicked ->
      case pagination_model.previous_cursor(model.logs_page) {
        option.Some(cursor) ->
          load_page(
            model,
            pagination_model.BeforePage(cursor:, limit: job_logs_page_limit),
          )
        option.None -> #(model, admin_effect.none())
      }
    _ -> #(model, admin_effect.none())
  }
}

pub fn empty_logs_page() -> pagination_model.CursorPage(
  job_log_dto.JobLogResponse,
) {
  pagination_model.InitialCursorPage(items: [], next_cursor: option.None)
}

fn load_page(model: Model, pagination: pagination_model.CursorPagination) {
  let generation = request_generation.next(model.logs_generation)
  #(
    Model(..model, logs_status: Loading, logs_generation: generation),
    get_job_logs(model, pagination, generation),
  )
}

fn get_job_logs(
  model: Model,
  pagination: pagination_model.CursorPagination,
  generation: Generation(LogsStream),
) {
  admin_effect.get_admin_job_logs(
    job_log_dto.ListJobLogsRequest(
      pagination:,
      request_id: option.None,
      job_id: option.Some(model.job_id),
      error_filter: job_log_dto.AllJobLogs,
    ),
    fn(result) { JobLogsLoaded(generation, result) },
  )
}

fn loading_status(status: Status) -> Status {
  case status {
    NotLoaded -> Loading
    Loading | Ready | LoadError(_) -> status
  }
}

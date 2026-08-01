import gleam/option
import glot_core/admin/job_dto
import glot_core/loadable
import glot_core/pagination_model
import glot_core/route
import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/jobs/list_message.{
  JobTypeFilterSelected, JobsLoaded, NextPageClicked, PreviousPageClicked,
  StatusFilterSelected,
}
import glot_frontend/admin/jobs/list_model.{Model}
import glot_frontend/admin/list_query
import glot_frontend/admin/ui/cursor_page as admin_cursor_page
import glot_frontend/api/response as api_response

const page_limit = 25

pub fn init(
  raw_query: option.Option(String),
) -> #(Model, admin_effect.Command(Msg)) {
  let query = list_query.parse(raw_query)
  #(
    Model(
      page: loadable.NotLoaded,
      summary: job_dto.empty_summary(),
      status_filter: status_filter_from_string(list_query.value_or(
        query,
        "status",
        "all",
      )),
      job_type_filter: list_query.value(query, "job_type"),
      query: query,
    ),
    admin_effect.none(),
  )
}

pub fn ensure_loaded(model: Model) -> #(Model, admin_effect.Command(Msg)) {
  case model.page {
    loadable.NotLoaded ->
      load_page(
        Model(..model, page: loadable.Loading),
        list_query.pagination(model.query, page_limit),
      )
    loadable.Loading | loadable.Loaded(_) | loadable.LoadError(_) -> #(
      model,
      admin_effect.none(),
    )
  }
}

pub fn update(model: Model, msg: Msg) -> #(Model, admin_effect.Command(Msg)) {
  case msg {
    JobsLoaded(result) ->
      case result {
        api_response.Success(response) -> #(
          Model(
            ..model,
            page: admin_cursor_page.page_from_response(
              result,
              fn(response) { response.page },
              "Could not load jobs.",
            ),
            summary: response.summary,
          ),
          admin_effect.none(),
        )
        api_response.ApiFailure(_) | api_response.HttpFailure(_) -> #(
          Model(
            ..model,
            page: admin_cursor_page.page_from_response(
              result,
              fn(response) { response.page },
              "Could not load jobs.",
            ),
          ),
          admin_effect.none(),
        )
      }

    StatusFilterSelected(filter) ->
      case filter == model.status_filter {
        True -> #(model, admin_effect.none())
        False ->
          navigate(
            Model(..model, status_filter: filter),
            list_query.initial(page_limit),
          )
      }

    JobTypeFilterSelected(filter) -> {
      let next_filter = job_type_filter_value(filter)

      case next_filter == model.job_type_filter {
        True -> #(model, admin_effect.none())
        False ->
          navigate(
            Model(..model, job_type_filter: next_filter),
            list_query.initial(page_limit),
          )
      }
    }

    NextPageClicked ->
      case admin_cursor_page.next_pagination(model.page, page_limit) {
        option.Some(pagination) -> navigate(model, pagination)
        option.None -> #(model, admin_effect.none())
      }

    PreviousPageClicked ->
      case admin_cursor_page.previous_pagination(model.page, page_limit) {
        option.Some(pagination) -> navigate(model, pagination)
        option.None -> #(model, admin_effect.none())
      }
  }
}

fn navigate(model: Model, pagination: pagination_model.CursorPagination) {
  #(
    model,
    admin_effect.Navigate(
      route.Admin(
        route.AdminJobs(query: list_query.encode(
          [
            #("status", status_filter_query(model.status_filter)),
            #("job_type", model.job_type_filter),
          ],
          pagination,
        )),
      ),
    ),
  )
}

fn load_page(
  model: Model,
  pagination: pagination_model.CursorPagination,
) -> #(Model, admin_effect.Command(Msg)) {
  #(
    model,
    admin_effect.get_admin_jobs(
      job_dto.ListJobsRequest(
        pagination: pagination,
        status_filter: model.status_filter,
        job_type_filter: model.job_type_filter,
        periodic_job_id: option.None,
      ),
      JobsLoaded,
    ),
  )
}

fn job_type_filter_value(value: String) -> option.Option(String) {
  case value {
    "all" -> option.None
    job_type -> option.Some(job_type)
  }
}

fn status_filter_from_string(value: String) -> job_dto.StatusFilter {
  case value {
    "pending" -> job_dto.PendingStatus
    "running" -> job_dto.RunningStatus
    "failed" -> job_dto.FailedStatus
    "done" -> job_dto.DoneStatus
    _ -> job_dto.AllStatuses
  }
}

fn status_filter_query(filter: job_dto.StatusFilter) -> option.Option(String) {
  case filter {
    job_dto.AllStatuses -> option.None
    job_dto.PendingStatus -> option.Some("pending")
    job_dto.RunningStatus -> option.Some("running")
    job_dto.FailedStatus -> option.Some("failed")
    job_dto.DoneStatus -> option.Some("done")
  }
}

pub type Model =
  list_model.Model

pub type Msg =
  list_message.Msg

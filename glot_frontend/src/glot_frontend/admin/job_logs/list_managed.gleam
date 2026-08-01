import gleam/option
import glot_core/admin/job_log_dto
import glot_core/loadable
import glot_core/pagination_model
import glot_core/route
import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/job_logs/list_message.{
  ApplyFilters, ErrorFilterSelected, JobIdFilterChanged, LogsLoaded,
  NextPageClicked, PreviousPageClicked, RequestIdFilterChanged,
}
import glot_frontend/admin/job_logs/list_model.{Model}
import glot_frontend/admin/list_query
import glot_frontend/admin/ui/cursor_page as admin_cursor_page
import youid/uuid

pub type Model =
  list_model.Model

pub type Msg =
  list_message.Msg

const page_limit = 25

pub fn init(
  raw_query: option.Option(String),
) -> #(Model, admin_effect.Command(Msg)) {
  let query = list_query.parse(raw_query)
  let request_id_filter = list_query.value_or(query, "request_id", "")
  let job_id_filter = list_query.value_or(query, "job_id", "")
  let #(page, request_id, job_id, request_error, job_error) =
    parse_initial_filters(request_id_filter, job_id_filter)
  #(
    Model(
      page: page,
      error_filter: error_filter_from_string(list_query.value_or(
        query,
        "error",
        "all",
      )),
      request_id_filter: request_id_filter,
      job_id_filter: job_id_filter,
      applied_request_id_filter: request_id,
      applied_job_id_filter: job_id,
      request_id_error: request_error,
      job_id_error: job_error,
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
    LogsLoaded(result) ->
      case result {
        _ -> #(
          Model(
            ..model,
            page: admin_cursor_page.page_from_response(
              result,
              fn(response) { response.page },
              "Could not load job logs.",
            ),
          ),
          admin_effect.none(),
        )
      }

    ErrorFilterSelected(filter) ->
      case filter == model.error_filter {
        True -> #(model, admin_effect.none())
        False ->
          navigate(
            Model(..model, error_filter: filter),
            list_query.initial(page_limit),
          )
      }

    RequestIdFilterChanged(value) -> #(
      Model(..model, request_id_filter: value, request_id_error: option.None),
      admin_effect.none(),
    )

    JobIdFilterChanged(value) -> #(
      Model(..model, job_id_filter: value, job_id_error: option.None),
      admin_effect.none(),
    )

    ApplyFilters ->
      case list_query.optional_uuid(model.request_id_filter, "Request ID") {
        Ok(request_id) ->
          case list_query.optional_uuid(model.job_id_filter, "Job ID") {
            Ok(job_id) ->
              navigate(
                Model(
                  ..model,
                  applied_request_id_filter: request_id,
                  applied_job_id_filter: job_id,
                ),
                list_query.initial(page_limit),
              )
            Error(message) -> #(
              Model(
                ..model,
                page: loadable.LoadError(message),
                job_id_error: option.Some(message),
              ),
              admin_effect.none(),
            )
          }
        Error(message) -> #(
          Model(
            ..model,
            page: loadable.LoadError(message),
            request_id_error: option.Some(message),
          ),
          admin_effect.none(),
        )
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
  let error = case model.error_filter {
    job_log_dto.AllJobLogs -> option.None
    job_log_dto.OnlyJobLogsWithErrors -> option.Some("errors_only")
  }
  #(
    model,
    admin_effect.Navigate(
      route.Admin(
        route.AdminJobLogs(query: list_query.encode(
          [
            #("error", error),
            #(
              "request_id",
              option.map(model.applied_request_id_filter, uuid.to_string),
            ),
            #("job_id", option.map(model.applied_job_id_filter, uuid.to_string)),
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
    admin_effect.get_admin_job_logs(
      job_log_dto.ListJobLogsRequest(
        pagination: pagination,
        request_id: model.applied_request_id_filter,
        job_id: model.applied_job_id_filter,
        error_filter: model.error_filter,
      ),
      LogsLoaded,
    ),
  )
}

fn error_filter_from_string(value: String) -> job_log_dto.JobLogErrorFilter {
  case value {
    "errors_only" -> job_log_dto.OnlyJobLogsWithErrors
    _ -> job_log_dto.AllJobLogs
  }
}

fn parse_initial_filters(request_id, job_id) {
  case list_query.optional_uuid(request_id, "Request ID") {
    Error(message) -> #(
      loadable.LoadError(message),
      option.None,
      option.None,
      option.Some(message),
      option.None,
    )
    Ok(request_id) ->
      case list_query.optional_uuid(job_id, "Job ID") {
        Error(message) -> #(
          loadable.LoadError(message),
          request_id,
          option.None,
          option.None,
          option.Some(message),
        )
        Ok(job_id) -> #(
          loadable.NotLoaded,
          request_id,
          job_id,
          option.None,
          option.None,
        )
      }
  }
}

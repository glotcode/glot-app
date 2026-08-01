import gleam/option
import glot_core/admin/api_log_dto
import glot_core/loadable
import glot_core/pagination_model
import glot_core/route
import glot_frontend/admin/api_logs/list_message.{
  ApplyFilters, ErrorFilterSelected, LogsLoaded, NextPageClicked,
  PreviousPageClicked, RequestIdFilterChanged,
}
import glot_frontend/admin/api_logs/list_model.{Model}
import glot_frontend/admin/command as admin_effect
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
  let error_filter =
    error_filter_from_string(list_query.value_or(query, "error", "all"))
  let parsed_request_id =
    list_query.optional_uuid(request_id_filter, "Request ID")
  let #(page, applied_request_id_filter, request_id_error) = case
    parsed_request_id
  {
    Ok(request_id) -> #(loadable.NotLoaded, request_id, option.None)
    Error(message) -> #(
      loadable.LoadError(message),
      option.None,
      option.Some(message),
    )
  }
  #(
    Model(
      page: page,
      error_filter: error_filter,
      request_id_filter: request_id_filter,
      applied_request_id_filter: applied_request_id_filter,
      request_id_error: request_id_error,
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
              "Could not load API logs.",
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
            model,
            filter,
            model.applied_request_id_filter,
            list_query.initial(page_limit),
          )
      }

    RequestIdFilterChanged(value) -> #(
      Model(..model, request_id_filter: value, request_id_error: option.None),
      admin_effect.none(),
    )

    ApplyFilters ->
      case list_query.optional_uuid(model.request_id_filter, "Request ID") {
        Ok(request_id) ->
          navigate(
            model,
            model.error_filter,
            request_id,
            list_query.initial(page_limit),
          )
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
        option.Some(pagination) ->
          navigate(
            model,
            model.error_filter,
            model.applied_request_id_filter,
            pagination,
          )
        option.None -> #(model, admin_effect.none())
      }

    PreviousPageClicked ->
      case admin_cursor_page.previous_pagination(model.page, page_limit) {
        option.Some(pagination) ->
          navigate(
            model,
            model.error_filter,
            model.applied_request_id_filter,
            pagination,
          )
        option.None -> #(model, admin_effect.none())
      }
  }
}

fn navigate(model: Model, error_filter, request_id, pagination) {
  let request_id = option.map(request_id, uuid.to_string)
  let error = case error_filter {
    api_log_dto.AllApiLogs -> option.None
    api_log_dto.OnlyApiLogsWithErrors -> option.Some("errors_only")
  }
  #(
    model,
    admin_effect.Navigate(
      route.Admin(
        route.AdminApiLogs(query: list_query.encode(
          [#("error", error), #("request_id", request_id)],
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
    admin_effect.get_admin_api_logs(
      api_log_dto.ListApiLogsRequest(
        pagination: pagination,
        request_id: model.applied_request_id_filter,
        error_filter: model.error_filter,
      ),
      LogsLoaded,
    ),
  )
}

fn error_filter_from_string(value: String) -> api_log_dto.ApiLogErrorFilter {
  case value {
    "errors_only" -> api_log_dto.OnlyApiLogsWithErrors
    _ -> api_log_dto.AllApiLogs
  }
}

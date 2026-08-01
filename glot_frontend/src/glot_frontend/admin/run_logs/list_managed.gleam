import gleam/option
import glot_core/admin/run_log_dto
import glot_core/language
import glot_core/loadable
import glot_core/pagination_model
import glot_core/route
import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/list_query
import glot_frontend/admin/run_logs/list_message.{
  ApplyFilters, LanguageFilterChanged, LogsLoaded, NextPageClicked,
  OutcomeFilterSelected, PreviousPageClicked, RequestIdFilterChanged,
  SessionIdFilterChanged, UserIdFilterChanged,
}
import glot_frontend/admin/run_logs/list_model.{Model}
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
  let session_id_filter = list_query.value_or(query, "session_id", "")
  let user_id_filter = list_query.value_or(query, "user_id", "")
  let language_filter = list_query.value_or(query, "language", "all")
  let #(
    page,
    request_id,
    session_id,
    user_id,
    selected_language,
    request_error,
    session_error,
    user_error,
    language_error,
  ) =
    parse_initial_filters(
      request_id_filter,
      session_id_filter,
      user_id_filter,
      language_filter,
    )
  #(
    Model(
      page: page,
      outcome_filter: outcome_filter_from_string(list_query.value_or(
        query,
        "outcome",
        "all",
      )),
      request_id_filter: request_id_filter,
      session_id_filter: session_id_filter,
      user_id_filter: user_id_filter,
      language_filter: language_filter,
      applied_request_id_filter: request_id,
      applied_session_id_filter: session_id,
      applied_user_id_filter: user_id,
      applied_language_filter: selected_language,
      request_id_error: request_error,
      session_id_error: session_error,
      user_id_error: user_error,
      language_error: language_error,
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
              "Could not load run logs.",
            ),
          ),
          admin_effect.none(),
        )
      }

    OutcomeFilterSelected(filter) ->
      case filter == model.outcome_filter {
        True -> #(model, admin_effect.none())
        False ->
          navigate(
            Model(..model, outcome_filter: filter),
            list_query.initial(page_limit),
          )
      }

    RequestIdFilterChanged(value) -> #(
      Model(..model, request_id_filter: value, request_id_error: option.None),
      admin_effect.none(),
    )

    SessionIdFilterChanged(value) -> #(
      Model(..model, session_id_filter: value, session_id_error: option.None),
      admin_effect.none(),
    )

    UserIdFilterChanged(value) -> #(
      Model(..model, user_id_filter: value, user_id_error: option.None),
      admin_effect.none(),
    )

    LanguageFilterChanged(value) -> #(
      Model(..model, language_filter: value, language_error: option.None),
      admin_effect.none(),
    )

    ApplyFilters ->
      case list_query.optional_uuid(model.request_id_filter, "Request ID") {
        Ok(request_id) ->
          case list_query.optional_uuid(model.session_id_filter, "Session ID") {
            Ok(session_id) ->
              case list_query.optional_uuid(model.user_id_filter, "User ID") {
                Ok(user_id) ->
                  case parse_language_filter(model.language_filter) {
                    Ok(language_filter) ->
                      navigate(
                        Model(
                          ..model,
                          applied_request_id_filter: request_id,
                          applied_session_id_filter: session_id,
                          applied_user_id_filter: user_id,
                          applied_language_filter: language_filter,
                        ),
                        list_query.initial(page_limit),
                      )
                    Error(message) -> #(
                      Model(
                        ..model,
                        page: loadable.LoadError(message),
                        language_error: option.Some(message),
                      ),
                      admin_effect.none(),
                    )
                  }
                Error(message) -> #(
                  Model(
                    ..model,
                    page: loadable.LoadError(message),
                    user_id_error: option.Some(message),
                  ),
                  admin_effect.none(),
                )
              }
            Error(message) -> #(
              Model(
                ..model,
                page: loadable.LoadError(message),
                session_id_error: option.Some(message),
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
  #(
    model,
    admin_effect.Navigate(
      route.Admin(
        route.AdminRunLogs(query: list_query.encode(
          [
            #("outcome", outcome_filter_query(model.outcome_filter)),
            #(
              "request_id",
              option.map(model.applied_request_id_filter, uuid.to_string),
            ),
            #(
              "session_id",
              option.map(model.applied_session_id_filter, uuid.to_string),
            ),
            #(
              "user_id",
              option.map(model.applied_user_id_filter, uuid.to_string),
            ),
            #(
              "language",
              option.map(model.applied_language_filter, language.to_string),
            ),
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
    admin_effect.get_admin_run_logs(
      run_log_dto.ListRunLogsRequest(
        pagination: pagination,
        request_id: model.applied_request_id_filter,
        session_id: model.applied_session_id_filter,
        user_id: model.applied_user_id_filter,
        language: model.applied_language_filter,
        outcome_filter: model.outcome_filter,
      ),
      LogsLoaded,
    ),
  )
}

fn parse_language_filter(
  value: String,
) -> Result(option.Option(language.Language), String) {
  case value {
    "all" -> Ok(option.None)
    selected ->
      case language.from_string(selected) {
        option.Some(language) -> Ok(option.Some(language))
        option.None -> Error("Language must be a known runtime.")
      }
  }
}

fn outcome_filter_from_string(
  value: String,
) -> run_log_dto.RunLogOutcomeFilter {
  case value {
    "succeeded" -> run_log_dto.OnlySuccessfulRunLogs
    "failed" -> run_log_dto.OnlyFailedRunLogs
    _ -> run_log_dto.AllRunLogs
  }
}

fn outcome_filter_query(
  filter: run_log_dto.RunLogOutcomeFilter,
) -> option.Option(String) {
  case filter {
    run_log_dto.AllRunLogs -> option.None
    run_log_dto.OnlySuccessfulRunLogs -> option.Some("succeeded")
    run_log_dto.OnlyFailedRunLogs -> option.Some("failed")
  }
}

fn parse_initial_filters(request_id, session_id, user_id, selected_language) {
  case list_query.optional_uuid(request_id, "Request ID") {
    Error(message) -> #(
      loadable.LoadError(message),
      option.None,
      option.None,
      option.None,
      option.None,
      option.Some(message),
      option.None,
      option.None,
      option.None,
    )
    Ok(request_id) ->
      case list_query.optional_uuid(session_id, "Session ID") {
        Error(message) -> #(
          loadable.LoadError(message),
          request_id,
          option.None,
          option.None,
          option.None,
          option.None,
          option.Some(message),
          option.None,
          option.None,
        )
        Ok(session_id) ->
          case list_query.optional_uuid(user_id, "User ID") {
            Error(message) -> #(
              loadable.LoadError(message),
              request_id,
              session_id,
              option.None,
              option.None,
              option.None,
              option.None,
              option.Some(message),
              option.None,
            )
            Ok(user_id) ->
              case parse_language_filter(selected_language) {
                Error(message) -> #(
                  loadable.LoadError(message),
                  request_id,
                  session_id,
                  user_id,
                  option.None,
                  option.None,
                  option.None,
                  option.None,
                  option.Some(message),
                )
                Ok(language) -> #(
                  loadable.NotLoaded,
                  request_id,
                  session_id,
                  user_id,
                  language,
                  option.None,
                  option.None,
                  option.None,
                  option.None,
                )
              }
          }
      }
  }
}

import gleam/option
import glot_core/loadable
import glot_core/pagination_model
import glot_frontend/api/response as api_response

pub fn current_page(
  state: loadable.Loadable(pagination_model.CursorPage(a)),
) -> pagination_model.CursorPage(a) {
  case state {
    loadable.Loaded(page) -> page
    loadable.NotLoaded | loadable.Loading | loadable.LoadError(_) ->
      pagination_model.InitialCursorPage(items: [], next_cursor: option.None)
  }
}

pub fn next_pagination(
  state: loadable.Loadable(pagination_model.CursorPage(a)),
  limit: Int,
) -> option.Option(pagination_model.CursorPagination) {
  state
  |> current_page
  |> pagination_model.next_cursor
  |> option.map(fn(cursor) {
    pagination_model.AfterPage(cursor: cursor, limit: limit)
  })
}

pub fn previous_pagination(
  state: loadable.Loadable(pagination_model.CursorPage(a)),
  limit: Int,
) -> option.Option(pagination_model.CursorPagination) {
  state
  |> current_page
  |> pagination_model.previous_cursor
  |> option.map(fn(cursor) {
    pagination_model.BeforePage(cursor: cursor, limit: limit)
  })
}

pub fn page_from_response(
  result: api_response.Response(response),
  to_page: fn(response) -> pagination_model.CursorPage(a),
  http_error: String,
) -> loadable.Loadable(pagination_model.CursorPage(a)) {
  case result {
    api_response.Success(response) -> loadable.Loaded(to_page(response))
    api_response.ApiFailure(error) ->
      loadable.LoadError(api_response.error_message(error))
    api_response.HttpFailure(_) -> loadable.LoadError(http_error)
  }
}

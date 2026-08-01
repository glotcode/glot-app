import gleam/list
import gleam/option
import gleam/string
import gleam/uri
import glot_core/pagination_model
import youid/uuid

pub opaque type Query {
  Query(params: List(#(String, String)))
}

pub fn empty() -> Query {
  Query([])
}

pub fn parse(query: option.Option(String)) -> Query {
  case query {
    option.Some(value) ->
      case uri.parse_query(value) {
        Ok(params) -> Query(params)
        Error(_) -> Query([])
      }
    option.None -> Query([])
  }
}

pub fn value(query: Query, key: String) -> option.Option(String) {
  let Query(params) = query
  params
  |> list.find(fn(param) { param.0 == key })
  |> option_from_result
  |> option.map(fn(param) { param.1 })
}

pub fn value_or(query: Query, key: String, default: String) -> String {
  value(query, key) |> option.unwrap(default)
}

pub fn pagination(
  query: Query,
  limit: Int,
) -> pagination_model.CursorPagination {
  case value(query, "after"), value(query, "before") {
    option.Some(cursor), _ ->
      pagination_model.AfterPage(
        cursor: pagination_model.from_string(cursor),
        limit: limit,
      )
    option.None, option.Some(cursor) ->
      pagination_model.BeforePage(
        cursor: pagination_model.from_string(cursor),
        limit: limit,
      )
    option.None, option.None -> pagination_model.InitialPage(limit: limit)
  }
}

pub fn encode(
  filters: List(#(String, option.Option(String))),
  pagination: pagination_model.CursorPagination,
) -> option.Option(String) {
  let params =
    filters
    |> list.fold([], fn(params, field) {
      case field.1 |> option.map(string.trim) {
        option.Some(value) if value != "" -> [#(field.0, value), ..params]
        option.Some(_) | option.None -> params
      }
    })
    |> list.reverse
    |> list.append(pagination_params(pagination))

  case params {
    [] -> option.None
    _ -> option.Some(uri.query_to_string(params))
  }
}

pub fn initial(limit: Int) -> pagination_model.CursorPagination {
  pagination_model.InitialPage(limit: limit)
}

pub fn optional_uuid(
  value: String,
  label: String,
) -> Result(option.Option(uuid.Uuid), String) {
  case string.trim(value) {
    "" -> Ok(option.None)
    value ->
      case uuid.from_string(value) {
        Ok(id) -> Ok(option.Some(id))
        Error(_) -> Error(label <> " must be a valid UUID.")
      }
  }
}

fn pagination_params(
  pagination: pagination_model.CursorPagination,
) -> List(#(String, String)) {
  case pagination {
    pagination_model.InitialPage(_) -> []
    pagination_model.AfterPage(cursor:, ..) -> [
      #("after", pagination_model.to_string(cursor)),
    ]
    pagination_model.BeforePage(cursor:, ..) -> [
      #("before", pagination_model.to_string(cursor)),
    ]
  }
}

fn option_from_result(result: Result(a, e)) -> option.Option(a) {
  case result {
    Ok(value) -> option.Some(value)
    Error(_) -> option.None
  }
}

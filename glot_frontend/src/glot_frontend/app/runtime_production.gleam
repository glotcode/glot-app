import gleam/option
import glot_core/pageview_dto
import glot_core/route
import glot_frontend/api/public
import glot_frontend/api/response
import lustre/effect.{type Effect}
import youid/uuid

pub fn track_pageview(
  destination: route.Route,
  callback: fn(response.Response(Nil)) -> msg,
) -> Effect(msg) {
  let #(path, query) = route.path_and_query(destination)
  let full_path = case query {
    option.Some(query) -> path <> "?" <> query
    option.None -> path
  }
  public.track_pageview(
    pageview_dto.PageviewRequest(
      id: uuid.v7(),
      route: route.name(destination),
      path: full_path,
    ),
    callback,
  )
}

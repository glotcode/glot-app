import gleam/option
import glot_core/route
import glot_frontend/admin/list_query

const page_limit = 25

pub fn for_owner(username: String) -> route.Route {
  route.Admin(
    route.AdminSnippets(query: list_query.encode(
      [#("username", option.Some(username))],
      list_query.initial(page_limit),
    )),
  )
}

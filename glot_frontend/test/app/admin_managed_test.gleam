import gleam/option
import gleam/time/timestamp
import gleeunit
import glot_core/auth/session_dto
import glot_core/auth/user_model
import glot_core/email/email_address_model
import glot_core/route
import glot_frontend/api/response
import glot_frontend/app/admin_managed
import youid/uuid

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn leaving_the_admin_app_requests_a_document_navigation_test() {
  let #(model, _) = init(route.Admin(route.AdminHome))
  let destination = route.Public(route.Home)
  let #(unchanged, command) =
    update(model, admin_managed.UserNavigatedTo(destination))

  assert unchanged == model
  assert command == admin_managed.LoadRoute(destination)
}

pub fn same_route_navigation_preserves_the_current_admin_page_test() {
  let current_route = route.Admin(route.AdminHome)
  let #(model, _) = init(current_route)
  let #(unchanged, command) =
    update(model, admin_managed.UserNavigatedTo(current_route))

  assert unchanged == model
  assert command == admin_managed.None
}

pub fn lifecycle_uses_the_injected_page_contract_test() {
  let fixture_pages =
    admin_managed.Pages(
      empty: fn() { "empty" },
      init: fn(admin_route, is_admin) {
        let page = case admin_route, is_admin {
          route.AdminRateLimits, True -> "rate-limits:admin"
          _, True -> "other:admin"
          _, False -> "unauthorized"
        }
        #(page, "initial-request")
      },
      session_loaded: fn(page) { #(page <> ":session", "session-request") },
      update: fn(_page, message) { #(message, "update-request") },
      none: "none",
    )
  let #(model, initial_command) =
    admin_managed.init(
      route.Admin(route.AdminRateLimits),
      timestamp.from_unix_seconds(1),
      True,
      fixture_pages,
    )
  let assert admin_managed.Batch([
    admin_managed.RunAdmin("initial-request"),
    admin_managed.TrackPageview(route.Admin(route.AdminRateLimits)),
    admin_managed.GetSession,
    admin_managed.ScheduleTick,
  ]) = initial_command
  assert model.page_model == "unauthorized"

  let #(authenticated, command) =
    admin_managed.update(
      model,
      admin_managed.SessionLoaded(
        response.Success(option.Some(admin_session())),
      ),
      fixture_pages,
    )
  assert authenticated.page_model == "unauthorized:session"
  assert command == admin_managed.RunAdmin("session-request")

  let #(updated, command) =
    admin_managed.update(
      authenticated,
      admin_managed.AdminPagesMsg("updated-page"),
      fixture_pages,
    )
  assert updated.page_model == "updated-page"
  assert command == admin_managed.RunAdmin("update-request")
}

fn init(
  target: route.Route,
) -> #(admin_managed.Model(String), admin_managed.Command(String)) {
  admin_managed.init(target, timestamp.from_unix_seconds(1), True, pages())
}

fn update(
  model: admin_managed.Model(String),
  msg: admin_managed.Msg(String),
) -> #(admin_managed.Model(String), admin_managed.Command(String)) {
  admin_managed.update(model, msg, pages())
}

fn pages() -> admin_managed.Pages(String, String, String) {
  admin_managed.Pages(
    empty: fn() { "empty" },
    init: fn(admin_route, _) {
      let page = route.to_string(route.Admin(admin_route))
      #(page, "load:" <> page)
    },
    session_loaded: fn(page) { #(page, "session-loaded") },
    update: fn(_, msg) { #(msg, "updated") },
    none: "none",
  )
}

fn admin_session() -> session_dto.SessionResponse {
  session_dto.SessionResponse(
    id: uuid.v7(),
    user: session_dto.SessionUserResponse(
      id: uuid.v7(),
      email: email_address_model.EmailAddress("admin@example.com"),
      username: "admin",
      role: user_model.AdminUser,
    ),
    created_at: timestamp.from_unix_seconds(1),
  )
}

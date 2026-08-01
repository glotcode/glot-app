import gleam/option
import gleam/time/timestamp
import gleeunit
import glot_core/auth/session_dto
import glot_core/auth/user_model
import glot_core/email/email_address_model
import glot_core/route
import glot_frontend/app/admin_navigation
import glot_frontend/app/runtime
import youid/uuid

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn anonymous_admin_navigation_falls_back_to_login_test() {
  assert admin_navigation.authorized_route(
      route.Admin(route.AdminHome),
      runtime.AnonymousSession,
    )
    == route.Public(route.Login)
}

pub fn loading_admin_navigation_falls_back_to_home_test() {
  assert admin_navigation.authorized_route(
      route.Admin(route.AdminHome),
      runtime.LoadingSession,
    )
    == route.Public(route.Home)
}

pub fn public_navigation_is_never_rewritten_test() {
  let target = route.Public(route.Home)
  assert admin_navigation.authorized_route(target, runtime.SessionError)
    == target
}

pub fn administrators_keep_the_requested_admin_route_test() {
  let target = route.Admin(route.AdminUsers(query: option.None))
  assert admin_navigation.authorized_route(
      target,
      runtime.AuthenticatedSession(admin_session()),
    )
    == target
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

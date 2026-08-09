import gleam/list
import gleam/option
import gleam/string
import gleam/time/timestamp
import gleeunit
import glot_core/route
import glot_frontend/admin/command
import glot_frontend/admin/effect/config
import glot_frontend/admin/router_managed as router
import glot_frontend/admin/router_state
import glot_frontend/admin/router_view
import glot_frontend/api/response
import lustre/element
import youid/uuid

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn authorized_route_initialization_retains_the_loading_state_test() {
  let #(model, initial_command) = router.init(route.AdminRateLimits, True)
  let assert command.Batch([
    command.None,
    command.Config(config.GetRateLimits(complete)),
  ]) = initial_command

  // A second load attempt must be suppressed because initialization retained
  // the model transition to Loading alongside the request command.
  let #(_, duplicate_command) = router.session_loaded(model)
  assert duplicate_command == command.None

  let request_id = uuid.v7()
  let #(failed_model, next_command) =
    router.update(
      model,
      complete(
        response.ApiFailure(response.Error(
          code: "fixture",
          message: "Initial request reached the reducer.",
          request_id:,
        )),
      ),
    )
  assert next_command == command.None

  let rendered =
    router_view.view(
      router_state.page(failed_model),
      timestamp.from_unix_seconds(0),
    )
    |> element.to_document_string
  assert string.contains(rendered, "Initial request reached the reducer.")
}

pub fn every_data_backed_admin_route_starts_a_data_request_test() {
  let id = uuid.v7()
  let data_routes = [
    route.AdminAnalytics,
    route.AdminApiLogs(query: option.None),
    route.AdminApiLog(id),
    route.AdminRunLogs(query: option.None),
    route.AdminRunLog(id),
    route.AdminPeriodicJobs,
    route.AdminPeriodicJob(id),
    route.AdminUsers(query: option.None),
    route.AdminUser(id),
    route.AdminJobs(query: option.None),
    route.AdminJob(id),
    route.AdminEmailTemplates,
    route.AdminEmailTemplate("welcome"),
    route.AdminSnippets(query: option.None),
    route.AdminSnippet("fixture"),
    route.AdminJobLogs(query: option.None),
    route.AdminJobLog(id),
    route.AdminConfig,
    route.AdminRateLimits,
    route.AdminJobTypePolicies,
  ]

  list.each(data_routes, fn(admin_route) {
    let #(_, initial_command) = router.init(admin_route, True)
    assert has_data_request(initial_command)
  })

  let #(_, home_command) = router.init(route.AdminHome, True)
  assert !has_data_request(home_command)
}

fn has_data_request(command: command.Command(msg)) -> Bool {
  case command {
    command.Logs(_)
    | command.Analytics(_)
    | command.Users(_)
    | command.Jobs(_)
    | command.Content(_)
    | command.Config(_) -> True
    command.Batch(commands) -> list.any(commands, has_data_request)
    command.None
    | command.OpenDialog(_)
    | command.CloseDialog(_)
    | command.Navigate(_)
    | command.CurrentTime(_)
    | command.FormatLocalDateTime(_, _)
    | command.ParseLocalDateTime(_, _, _) -> False
  }
}

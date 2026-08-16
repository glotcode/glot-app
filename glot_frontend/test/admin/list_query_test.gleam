import gleam/option
import gleam/uri
import gleeunit
import glot_core/admin/api_log_dto
import glot_core/admin/job_dto
import glot_core/admin/job_log_dto
import glot_core/admin/run_log_dto
import glot_core/admin/snippet_dto
import glot_core/loadable
import glot_core/pagination_model
import glot_core/route
import glot_core/snippet/spam_classification
import glot_frontend/admin/api_logs/list_managed as api_logs
import glot_frontend/admin/api_logs/list_model as api_logs_model
import glot_frontend/admin/command
import glot_frontend/admin/effect/content
import glot_frontend/admin/effect/jobs
import glot_frontend/admin/effect/logs
import glot_frontend/admin/effect/users
import glot_frontend/admin/job_logs/list_managed as job_logs
import glot_frontend/admin/jobs/list_managed as admin_jobs
import glot_frontend/admin/run_logs/list_managed as run_logs
import glot_frontend/admin/snippets/list_managed as snippets
import glot_frontend/admin/snippets/list_message as snippets_message
import glot_frontend/admin/users/list_managed as admin_users
import glot_frontend/api/response
import youid/uuid

const request_id = "00000000-0000-4000-8000-000000000001"

const session_id = "00000000-0000-4000-8000-000000000002"

const user_id = "00000000-0000-4000-8000-000000000003"

const job_id = "00000000-0000-4000-8000-000000000004"

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn admin_routes_round_trip_the_feature_owned_query_test() {
  let parsed =
    route.from_uri(parse_uri("/admin/logs/api?error=errors_only&after=cursor"))
  assert parsed
    == route.Admin(
      route.AdminApiLogs(query: option.Some("error=errors_only&after=cursor")),
    )
  assert route.to_string(parsed)
    == "/admin/logs/api?error=errors_only&after=cursor"
  assert route.path_and_query(parsed)
    == #("/admin/logs/api", option.Some("error=errors_only&after=cursor"))
}

pub fn public_snippet_route_round_trips_language_filter_test() {
  let parsed =
    route.from_uri(parse_uri(
      "/snippets?after=cursor&username=petter&language=gleam",
    ))
  assert parsed
    == route.Public(route.Snippets(
      after: option.Some("cursor"),
      before: option.None,
      username: option.Some("petter"),
      language: option.Some("gleam"),
    ))
  assert route.to_string(parsed)
    == "/snippets?after=cursor&username=petter&language=gleam"
}

pub fn account_snippet_route_round_trips_language_filter_test() {
  let parsed =
    route.from_uri(parse_uri("/account/snippets?before=cursor&language=python"))
  assert parsed
    == route.Account(route.AccountSnippets(
      after: option.None,
      before: option.Some("cursor"),
      language: option.Some("python"),
    ))
  assert route.to_string(parsed)
    == "/account/snippets?before=cursor&language=python"
}

pub fn log_lists_restore_filters_and_cursor_requests_from_the_url_test() {
  let #(api_model, _) =
    api_logs.init(option.Some(
      "error=errors_only&request_id=" <> request_id <> "&after=api-cursor",
    ))
  let #(_, api_command) = api_logs.ensure_loaded(api_model)
  let assert command.Logs(logs.GetApiLogs(api_request, _)) = api_command
  assert api_request.error_filter == api_log_dto.OnlyApiLogsWithErrors
  assert_uuid(api_request.request_id, request_id)
  assert_after(api_request.pagination, "api-cursor")

  let #(run_model, _) =
    run_logs.init(option.Some(
      "outcome=failed&request_id="
      <> request_id
      <> "&session_id="
      <> session_id
      <> "&user_id="
      <> user_id
      <> "&language=python&before=run-cursor",
    ))
  let #(_, run_command) = run_logs.ensure_loaded(run_model)
  let assert command.Logs(logs.GetRunLogs(run_request, _)) = run_command
  assert run_request.outcome_filter == run_log_dto.OnlyFailedRunLogs
  assert_uuid(run_request.request_id, request_id)
  assert_uuid(run_request.session_id, session_id)
  assert_uuid(run_request.user_id, user_id)
  assert_before(run_request.pagination, "run-cursor")

  let #(job_log_model, _) =
    job_logs.init(option.Some(
      "error=errors_only&request_id=" <> request_id <> "&job_id=" <> job_id,
    ))
  let #(_, job_log_command) = job_logs.ensure_loaded(job_log_model)
  let assert command.Jobs(jobs.GetJobLogs(job_log_request, _)) = job_log_command
  assert job_log_request.error_filter == job_log_dto.OnlyJobLogsWithErrors
  assert_uuid(job_log_request.request_id, request_id)
  assert_uuid(job_log_request.job_id, job_id)
}

pub fn resource_lists_restore_filters_and_cursor_requests_from_the_url_test() {
  let #(users_model, _) =
    admin_users.init(option.Some(
      "search=person%40example.com&role=admin&state=active&tier=free&after=users-cursor",
    ))
  let #(_, users_command) = admin_users.ensure_loaded(users_model)
  let assert command.Users(users.GetUsers(users_request, _)) = users_command
  assert users_request.email == option.Some("person@example.com")
  assert_after(users_request.pagination, "users-cursor")

  let #(jobs_model, _) =
    admin_jobs.init(option.Some(
      "status=running&job_type=cleanup&before=jobs-cursor",
    ))
  let #(_, jobs_command) = admin_jobs.ensure_loaded(jobs_model)
  let assert command.Jobs(jobs.GetJobs(jobs_request, _)) = jobs_command
  assert jobs_request.status_filter == job_dto.RunningStatus
  assert jobs_request.job_type_filter == option.Some("cleanup")
  assert_before(jobs_request.pagination, "jobs-cursor")

  let #(snippets_model, _) =
    snippets.init(option.Some(
      "username=petter&classification=block&after=snippets-cursor",
    ))
  let #(_, snippets_command) = snippets.ensure_loaded(snippets_model)
  let assert command.Content(content.GetSnippets(snippets_request, _)) =
    snippets_command
  assert snippets_request.username == option.Some("petter")
  assert snippets_request.spam_classification
    == option.Some(spam_classification.Classified(spam_classification.Block))
  assert_after(snippets_request.pagination, "snippets-cursor")
}

pub fn invalid_direct_filter_is_presentable_without_starting_a_request_test() {
  let #(model, _) = api_logs.init(option.Some("request_id=not-a-uuid"))
  let assert loadable.LoadError("Request ID must be a valid UUID.") = model.page
  assert api_logs_model.is_presentable(model)
  let #(_, next_command) = api_logs.ensure_loaded(model)
  assert next_command == command.None
}

pub fn loaded_cursor_page_preserves_classification_in_the_next_page_url_test() {
  let #(model, _) = snippets.init(option.Some("classification=pass"))
  let #(loading, request_command) = snippets.ensure_loaded(model)
  let assert command.Content(content.GetSnippets(request, complete)) =
    request_command
  assert request.spam_classification
    == option.Some(spam_classification.Classified(spam_classification.Allow))
  let #(loaded, _) =
    snippets.update(
      loading,
      complete(
        response.Success(
          snippet_dto.ListSnippetsResponse(
            page: pagination_model.InitialCursorPage(
              items: [],
              next_cursor: option.Some(pagination_model.from_string("next-page")),
            ),
          ),
        ),
      ),
    )

  let #(_, navigation_command) =
    snippets.update(loaded, snippets_message.NextPageClicked)
  assert navigation_command
    == command.Navigate(
      route.Admin(
        route.AdminSnippets(query: option.Some(
          "classification=pass&after=next-page",
        )),
      ),
    )
}

pub fn unclassified_snippet_filter_is_sent_to_the_api_test() {
  let #(model, _) = snippets.init(option.Some("classification=unclassified"))
  let #(_, request_command) = snippets.ensure_loaded(model)
  let assert command.Content(content.GetSnippets(request, _)) = request_command
  assert request.spam_classification
    == option.Some(spam_classification.Unclassified)
}

fn assert_uuid(actual: option.Option(uuid.Uuid), expected: String) {
  let assert option.Some(actual) = actual
  assert uuid.to_string(actual) == expected
}

fn assert_after(
  pagination: pagination_model.CursorPagination,
  expected: String,
) {
  let assert pagination_model.AfterPage(cursor:, limit: 25) = pagination
  assert pagination_model.to_string(cursor) == expected
}

fn assert_before(
  pagination: pagination_model.CursorPagination,
  expected: String,
) {
  let assert pagination_model.BeforePage(cursor:, limit: 25) = pagination
  assert pagination_model.to_string(cursor) == expected
}

fn parse_uri(path: String) {
  let assert Ok(value) = uri.parse("https://glot.io" <> path)
  value
}

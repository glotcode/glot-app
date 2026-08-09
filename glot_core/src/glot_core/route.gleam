import gleam/list
import gleam/option
import gleam/uri.{type Uri}
import youid/uuid

pub type Route {
  Public(public_route: PublicRoute)
  Account(account_route: AccountRoute)
  Admin(admin_route: AdminRoute)
  NotFound(uri: Uri)
}

pub type PublicRoute {
  Home
  Contact
  Privacy
  Login
  Snippets(
    after: option.Option(String),
    before: option.Option(String),
    username: option.Option(String),
    language: option.Option(String),
  )
  NewSnippet(language: String)
  Snippet(slug: String)
}

pub type AccountRoute {
  AccountHome
  AccountSnippets(after: option.Option(String), before: option.Option(String))
}

pub type AdminRoute {
  AdminHome
  AdminApiLogs(query: option.Option(String))
  AdminApiLog(id: uuid.Uuid)
  AdminRunLogs(query: option.Option(String))
  AdminRunLog(id: uuid.Uuid)
  AdminPeriodicJobs
  AdminPeriodicJob(id: uuid.Uuid)
  AdminUsers(query: option.Option(String))
  AdminUser(id: uuid.Uuid)
  AdminJobs(query: option.Option(String))
  AdminJob(id: uuid.Uuid)
  AdminEmailTemplates
  AdminEmailTemplate(name: String)
  AdminSnippets(query: option.Option(String))
  AdminSnippet(slug: String)
  AdminJobLogs(query: option.Option(String))
  AdminJobLog(id: uuid.Uuid)
  AdminConfig
  AdminRateLimits
  AdminJobTypePolicies
}

pub fn from_uri(uri: Uri) -> Route {
  case uri.path_segments(uri.path) {
    [] | [""] -> Public(Home)
    ["contact"] -> Public(Contact)
    ["privacy"] -> Public(Privacy)
    ["login"] -> Public(Login)
    ["account"] -> Account(AccountHome)
    ["admin"] -> Admin(AdminHome)
    ["admin", "logs", "api"] -> Admin(AdminApiLogs(query: uri.query))
    ["admin", "logs", "api", id] ->
      case uuid.from_string(id) {
        Ok(id) -> Admin(AdminApiLog(id))
        Error(_) -> NotFound(uri:)
      }
    ["admin", "logs", "runs"] -> Admin(AdminRunLogs(query: uri.query))
    ["admin", "logs", "runs", id] ->
      case uuid.from_string(id) {
        Ok(id) -> Admin(AdminRunLog(id))
        Error(_) -> NotFound(uri:)
      }
    ["admin", "periodic-jobs"] -> Admin(AdminPeriodicJobs)
    ["admin", "periodic-jobs", job_id] ->
      case uuid.from_string(job_id) {
        Ok(id) -> Admin(AdminPeriodicJob(id))
        Error(_) -> NotFound(uri:)
      }
    ["admin", "users"] -> Admin(AdminUsers(query: uri.query))
    ["admin", "users", user_id] ->
      case uuid.from_string(user_id) {
        Ok(id) -> Admin(AdminUser(id))
        Error(_) -> NotFound(uri:)
      }
    ["admin", "jobs"] -> Admin(AdminJobs(query: uri.query))
    ["admin", "jobs", job_id] ->
      case uuid.from_string(job_id) {
        Ok(id) -> Admin(AdminJob(id))
        Error(_) -> NotFound(uri:)
      }
    ["admin", "email-templates"] -> Admin(AdminEmailTemplates)
    ["admin", "email-templates", name] -> Admin(AdminEmailTemplate(name: name))
    ["admin", "snippets"] -> Admin(AdminSnippets(query: uri.query))
    ["admin", "snippets", slug] -> Admin(AdminSnippet(slug: slug))
    ["admin", "logs", "job-logs"] -> Admin(AdminJobLogs(query: uri.query))
    ["admin", "logs", "job-logs", id] ->
      case uuid.from_string(id) {
        Ok(id) -> Admin(AdminJobLog(id))
        Error(_) -> NotFound(uri:)
      }
    ["admin", "config"] -> Admin(AdminConfig)
    ["admin", "rate-limits"] -> Admin(AdminRateLimits)
    ["admin", "job-type-policies"] -> Admin(AdminJobTypePolicies)
    ["account", "snippets"] -> {
      let #(after, before, _, _) = snippet_query_params(uri)
      Account(AccountSnippets(after:, before:))
    }
    ["snippets"] -> {
      let #(after, before, username, language) = snippet_query_params(uri)
      Public(Snippets(after:, before:, username:, language:))
    }
    ["new", language] -> Public(NewSnippet(language: language))
    ["snippets", slug] -> Public(Snippet(slug: slug))
    _ -> NotFound(uri:)
  }
}

pub fn to_string(route: Route) -> String {
  case route {
    Public(public_route) -> public_route_to_string(public_route)
    Account(account_route) -> account_route_to_string(account_route)
    Admin(admin_route) -> admin_route_to_string(admin_route)
    NotFound(_) -> ""
  }
}

pub fn name(route: Route) -> String {
  case route {
    Public(public_route) -> public_route_name(public_route)
    Account(account_route) -> account_route_name(account_route)
    Admin(admin_route) -> admin_route_name(admin_route)
    NotFound(_) -> "not_found"
  }
}

pub fn path_and_query(route: Route) -> #(String, option.Option(String)) {
  case route {
    Public(Snippets(after:, before:, username:, language:)) -> #(
      "/snippets",
      snippet_query_string(after, before, username, language),
    )
    Account(AccountSnippets(after:, before:)) -> #(
      "/account/snippets",
      snippet_query_string(after, before, option.None, option.None),
    )
    Admin(AdminApiLogs(query)) -> #("/admin/logs/api", query)
    Admin(AdminRunLogs(query)) -> #("/admin/logs/runs", query)
    Admin(AdminUsers(query)) -> #("/admin/users", query)
    Admin(AdminJobs(query)) -> #("/admin/jobs", query)
    Admin(AdminSnippets(query)) -> #("/admin/snippets", query)
    Admin(AdminJobLogs(query)) -> #("/admin/logs/job-logs", query)
    _ -> #(to_string(route), option.None)
  }
}

pub fn is_admin_route(route: Route) -> Bool {
  case route {
    Admin(_) -> True
    Public(_) | Account(_) | NotFound(_) -> False
  }
}

pub fn is_account_route(route: Route) -> Bool {
  case route {
    Account(_) -> True
    Public(_) | Admin(_) | NotFound(_) -> False
  }
}

fn public_route_to_string(route: PublicRoute) -> String {
  case route {
    Home -> "/"
    Contact -> "/contact"
    Privacy -> "/privacy"
    Login -> "/login"
    Snippets(after:, before:, username:, language:) -> {
      let query = snippet_query_string(after, before, username, language)
      case query {
        option.Some(query) -> "/snippets?" <> query
        option.None -> "/snippets"
      }
    }
    NewSnippet(language) -> "/new/" <> language
    Snippet(slug) -> "/snippets/" <> slug
  }
}

fn account_route_to_string(route: AccountRoute) -> String {
  case route {
    AccountHome -> "/account"
    AccountSnippets(after:, before:) -> {
      let query = snippet_query_string(after, before, option.None, option.None)
      case query {
        option.Some(query) -> "/account/snippets?" <> query
        option.None -> "/account/snippets"
      }
    }
  }
}

fn admin_route_to_string(route: AdminRoute) -> String {
  let path = admin_path(route)
  case admin_query(route) {
    option.Some(query) -> path <> "?" <> query
    option.None -> path
  }
}

fn admin_path(route: AdminRoute) -> String {
  case route {
    AdminHome -> "/admin"
    AdminApiLogs(_) -> "/admin/logs/api"
    AdminApiLog(id) -> "/admin/logs/api/" <> uuid.to_string(id)
    AdminRunLogs(_) -> "/admin/logs/runs"
    AdminRunLog(id) -> "/admin/logs/runs/" <> uuid.to_string(id)
    AdminPeriodicJobs -> "/admin/periodic-jobs"
    AdminPeriodicJob(id) -> "/admin/periodic-jobs/" <> uuid.to_string(id)
    AdminUsers(_) -> "/admin/users"
    AdminUser(id) -> "/admin/users/" <> uuid.to_string(id)
    AdminJobs(_) -> "/admin/jobs"
    AdminJob(id) -> "/admin/jobs/" <> uuid.to_string(id)
    AdminEmailTemplates -> "/admin/email-templates"
    AdminEmailTemplate(name) -> "/admin/email-templates/" <> name
    AdminSnippets(_) -> "/admin/snippets"
    AdminSnippet(slug) -> "/admin/snippets/" <> slug
    AdminJobLogs(_) -> "/admin/logs/job-logs"
    AdminJobLog(id) -> "/admin/logs/job-logs/" <> uuid.to_string(id)
    AdminConfig -> "/admin/config"
    AdminRateLimits -> "/admin/rate-limits"
    AdminJobTypePolicies -> "/admin/job-type-policies"
  }
}

fn admin_query(route: AdminRoute) -> option.Option(String) {
  case route {
    AdminApiLogs(query)
    | AdminRunLogs(query)
    | AdminUsers(query)
    | AdminJobs(query)
    | AdminSnippets(query)
    | AdminJobLogs(query) -> query
    _ -> option.None
  }
}

fn public_route_name(route: PublicRoute) -> String {
  case route {
    Home -> "home"
    Contact -> "contact"
    Privacy -> "privacy"
    Login -> "login"
    Snippets(_, _, _, _) -> "snippets"
    NewSnippet(_) -> "new_snippet"
    Snippet(_) -> "snippet"
  }
}

fn account_route_name(route: AccountRoute) -> String {
  case route {
    AccountHome -> "account"
    AccountSnippets(_, _) -> "account_snippets"
  }
}

fn admin_route_name(route: AdminRoute) -> String {
  case route {
    AdminHome -> "admin"
    AdminApiLogs(_) -> "admin_api_logs"
    AdminApiLog(_) -> "admin_api_log"
    AdminRunLogs(_) -> "admin_run_logs"
    AdminRunLog(_) -> "admin_run_log"
    AdminPeriodicJobs -> "admin_periodic_jobs"
    AdminPeriodicJob(_) -> "admin_periodic_job"
    AdminUsers(_) -> "admin_users"
    AdminUser(_) -> "admin_user"
    AdminJobs(_) -> "admin_jobs"
    AdminJob(_) -> "admin_job"
    AdminEmailTemplates -> "admin_email_templates"
    AdminEmailTemplate(_) -> "admin_email_template"
    AdminSnippets(_) -> "admin_snippets"
    AdminSnippet(_) -> "admin_snippet"
    AdminJobLogs(_) -> "admin_job_logs"
    AdminJobLog(_) -> "admin_job_log"
    AdminConfig -> "admin_config"
    AdminRateLimits -> "admin_rate_limits"
    AdminJobTypePolicies -> "admin_job_type_policies"
  }
}

fn snippet_query_params(
  uri: Uri,
) -> #(
  option.Option(String),
  option.Option(String),
  option.Option(String),
  option.Option(String),
) {
  case uri.query {
    option.Some(query) ->
      case uri.parse_query(query) {
        Ok(params) -> #(
          query_param(params, "after"),
          query_param(params, "before"),
          query_param(params, "username"),
          query_param(params, "language"),
        )
        Error(_) -> #(option.None, option.None, option.None, option.None)
      }
    option.None -> #(option.None, option.None, option.None, option.None)
  }
}

fn query_param(
  params: List(#(String, String)),
  key: String,
) -> option.Option(String) {
  case params |> list.filter(fn(param) { param.0 == key }) |> list.first {
    Ok(param) -> option.Some(param.1)
    Error(_) -> option.None
  }
}

fn snippet_query_string(
  after: option.Option(String),
  before: option.Option(String),
  username: option.Option(String),
  language: option.Option(String),
) -> option.Option(String) {
  let pairs =
    []
    |> prepend_query_param("after", after)
    |> prepend_query_param("before", before)
    |> prepend_query_param("username", username)
    |> prepend_query_param("language", language)
    |> list.reverse

  case pairs {
    [] -> option.None
    _ -> option.Some(uri.query_to_string(pairs))
  }
}

fn prepend_query_param(
  pairs: List(#(String, String)),
  key: String,
  value: option.Option(String),
) -> List(#(String, String)) {
  case value {
    option.Some(value) -> [#(key, value), ..pairs]
    option.None -> pairs
  }
}

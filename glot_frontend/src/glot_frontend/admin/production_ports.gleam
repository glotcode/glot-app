import gleam/list
import gleam/option
import glot_core/helpers/timestamp_helpers
import glot_core/route
import glot_frontend/admin/command
import glot_frontend/admin/effect/config
import glot_frontend/admin/effect/content
import glot_frontend/admin/effect/jobs
import glot_frontend/admin/effect/logs
import glot_frontend/admin/effect/users
import glot_frontend/admin/local_datetime
import glot_frontend/admin/ports
import glot_frontend/api/admin/config as config_api
import glot_frontend/api/admin/content as content_api
import glot_frontend/api/admin/jobs as jobs_api
import glot_frontend/api/admin/logs as logs_api
import glot_frontend/api/admin/users as users_api
import glot_frontend/platform/app_dialog
import glot_frontend/platform/clock
import glot_frontend/platform/local_datetime as local_datetime_adapter
import glot_frontend/platform/spa_navigation
import lustre/effect.{type Effect}

pub fn new() -> ports.Ports(msg) {
  ports.Ports(execute: run)
}

fn run(command: command.Command(msg)) -> Effect(msg) {
  case command {
    command.None -> effect.none()
    command.Batch(commands) -> effect.batch(list.map(commands, run))
    command.Logs(value) -> run_logs(value)
    command.Users(value) -> run_users(value)
    command.Jobs(value) -> run_jobs(value)
    command.Content(value) -> run_content(value)
    command.Config(value) -> run_config(value)
    command.OpenDialog(id) -> app_dialog.open(id)
    command.CloseDialog(id) -> app_dialog.close(id)
    command.Navigate(target) -> {
      let #(path, query) = route.path_and_query(target)
      spa_navigation.push(path, query)
    }
    command.CurrentTime(complete) ->
      effect.from(fn(dispatch) { dispatch(complete(clock.now())) })
    command.FormatLocalDateTime(value, complete) ->
      effect.from(fn(dispatch) {
        dispatch(
          complete(local_datetime.LocalDateTime(
            date: local_datetime_adapter.timestamp_to_local_date_input(value),
            time: local_datetime_adapter.timestamp_to_local_time_input(value),
          )),
        )
      })
    command.ParseLocalDateTime(date, time, complete) ->
      effect.from(fn(dispatch) {
        let milliseconds =
          local_datetime_adapter.local_date_time_to_unix_milliseconds(
            date,
            time,
          )
        let result = case milliseconds < 0 {
          True -> option.None
          False ->
            option.Some(timestamp_helpers.from_unix_milliseconds(milliseconds))
        }
        dispatch(complete(result))
      })
  }
}

fn run_logs(command: logs.Command(msg)) -> Effect(msg) {
  case command {
    logs.GetApiLogs(request, done) -> logs_api.get_admin_api_logs(request, done)
    logs.GetApiLog(request, done) -> logs_api.get_admin_api_log(request, done)
    logs.GetRunLogs(request, done) -> logs_api.get_admin_run_logs(request, done)
    logs.GetRunLog(request, done) -> logs_api.get_admin_run_log(request, done)
  }
}

fn run_users(command: users.Command(msg)) -> Effect(msg) {
  case command {
    users.GetUsers(request, done) -> users_api.get_admin_users(request, done)
    users.GetUser(request, done) -> users_api.get_admin_user(request, done)
    users.UpdateUser(request, done) ->
      users_api.update_admin_user(request, done)
    users.DeleteAccount(request, done) ->
      users_api.delete_admin_account(request, done)
  }
}

fn run_jobs(command: jobs.Command(msg)) -> Effect(msg) {
  case command {
    jobs.GetPeriodicJobs(done) -> jobs_api.get_admin_periodic_jobs(done)
    jobs.GetPeriodicJob(request, done) ->
      jobs_api.get_admin_periodic_job(request, done)
    jobs.UpdatePeriodicJob(request, done) ->
      jobs_api.update_admin_periodic_job(request, done)
    jobs.GetJobs(request, done) -> jobs_api.get_admin_jobs(request, done)
    jobs.GetJob(request, done) -> jobs_api.get_admin_job(request, done)
    jobs.CreateJob(request, done) -> jobs_api.create_admin_job(request, done)
    jobs.GetJobLogs(request, done) -> jobs_api.get_admin_job_logs(request, done)
    jobs.GetJobLog(request, done) -> jobs_api.get_admin_job_log(request, done)
  }
}

fn run_content(command: content.Command(msg)) -> Effect(msg) {
  case command {
    content.GetEmailTemplates(done) ->
      content_api.get_admin_email_templates(done)
    content.GetEmailTemplate(request, done) ->
      content_api.get_admin_email_template(request, done)
    content.UpdateEmailTemplate(request, done) ->
      content_api.update_admin_email_template(request, done)
    content.GetSnippets(request, done) ->
      content_api.get_admin_snippets(request, done)
    content.GetSnippet(request, done) ->
      content_api.get_admin_snippet(request, done)
    content.DeleteSnippet(request, done) ->
      content_api.delete_admin_snippet(request, done)
  }
}

fn run_config(command: config.Command(msg)) -> Effect(msg) {
  case command {
    config.GetRateLimits(done) -> config_api.get_admin_rate_limit_policies(done)
    config.GetAuth(done) -> config_api.get_admin_auth_config(done)
    config.GetPasskey(done) -> config_api.get_admin_passkey_config(done)
    config.GetJobTypePolicies(done) ->
      config_api.get_admin_job_type_policies(done)
    config.GetDebug(done) -> config_api.get_admin_debug_config(done)
    config.GetAvailability(done) ->
      config_api.get_admin_availability_config(done)
    config.UpsertDebug(request, done) ->
      config_api.upsert_admin_debug_config(request, done)
    config.UpsertAvailability(request, done) ->
      config_api.upsert_admin_availability_config(request, done)
    config.UpsertJobTypePolicy(request, done) ->
      config_api.upsert_admin_job_type_policy(request, done)
    config.UpsertAuth(request, done) ->
      config_api.upsert_admin_auth_config(request, done)
    config.UpsertPasskey(request, done) ->
      config_api.upsert_admin_passkey_config(request, done)
    config.GetCleanup(done) -> config_api.get_admin_cleanup_config(done)
    config.GetLogWorker(done) -> config_api.get_admin_log_worker_config(done)
    config.GetHttpPool(done) -> config_api.get_admin_http_pool_config(done)
    config.GetLanguageCache(done) ->
      config_api.get_admin_language_version_cache_worker_config(done)
    config.UpsertCleanup(request, done) ->
      config_api.upsert_admin_cleanup_config(request, done)
    config.UpsertLogWorker(request, done) ->
      config_api.upsert_admin_log_worker_config(request, done)
    config.UpsertHttpPool(request, done) ->
      config_api.upsert_admin_http_pool_config(request, done)
    config.UpsertLanguageCache(request, done) ->
      config_api.upsert_admin_language_version_cache_worker_config(
        request,
        done,
      )
    config.UpsertRateLimit(request, done) ->
      config_api.upsert_admin_rate_limit_policy(request, done)
    config.GetDockerRun(done) -> config_api.get_admin_docker_run_config(done)
    config.UpsertDockerRun(request, done) ->
      config_api.upsert_admin_docker_run_config(request, done)
    config.GetCloudflare(done) -> config_api.get_admin_cloudflare_config(done)
    config.UpsertCloudflare(request, done) ->
      config_api.upsert_admin_cloudflare_config(request, done)
    config.GetEmail(done) -> config_api.get_admin_email_config(done)
    config.UpsertEmail(request, done) ->
      config_api.upsert_admin_email_config(request, done)
  }
}

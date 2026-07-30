import glot_core/admin/api_log_dto
import glot_core/loadable
import glot_frontend/admin/api_logs/detail
import glot_frontend/admin/api_logs/detail_message
import glot_frontend/admin/api_logs/list as api_logs
import glot_frontend/admin/api_logs/list_message as api_logs_message
import glot_frontend/admin/command
import glot_frontend/admin/effect/logs
import glot_frontend/admin/email_templates/detail as email_template
import glot_frontend/admin/email_templates/detail_message as email_template_message
import glot_frontend/admin/email_templates/detail_model as email_template_model
import glot_frontend/admin/jobs/managed as job_detail
import glot_frontend/admin/jobs/message as job_message
import glot_frontend/admin/jobs/model as job_model
import glot_frontend/admin/periodic_jobs/managed as periodic_job_detail
import glot_frontend/admin/periodic_jobs/message as periodic_job_message
import glot_frontend/admin/periodic_jobs/model as periodic_job_model
import glot_frontend/admin/rate_limits/managed as rate_limits
import glot_frontend/admin/rate_limits/message as rate_limit_message
import glot_frontend/admin/rate_limits/model as rate_limit_model
import glot_frontend/admin/request_generation
import glot_frontend/admin/users/managed as user_detail
import glot_frontend/admin/users/message as user_message
import glot_frontend/admin/users/model as user_model
import glot_frontend/api/response
import glot_frontend/ui/mutation
import support/managed_scenario
import youid/uuid

type ApiLogScenario =
  managed_scenario.Scenario(detail.Model, command.Command(detail.Msg), Nil)

pub fn api_log_screen_is_driven_by_a_typed_admin_fixture_test() {
  let assert Ok(id) = uuid.from_string("00000000-0000-4000-8000-000000000001")
  let #(model, initial_command) = detail.init(id)
  assert initial_command == command.None

  let #(loading_model, request_command) = detail.ensure_loaded(model)
  assert loading_model.log == loadable.Loading
  let scenario =
    managed_scenario.start(loading_model, request_command, interpret_api_log)
  let #(request_command, scenario) =
    managed_scenario.take_next_pending(scenario)
  let assert command.Logs(logs.GetApiLog(request, complete)) = request_command
  assert request.id == id

  let failure =
    response.ApiFailure(response.Error(
      code: "fixture_error",
      message: "Fixture rejected the request.",
      request_id: id,
    ))
  let scenario =
    managed_scenario.dispatch(
      scenario,
      complete(failure),
      detail.update,
      interpret_api_log,
    )
  let failed_model = managed_scenario.model(scenario)

  let assert loadable.LoadError(message) = failed_model.log
  assert message
    == "Fixture rejected the request. Request ID: 00000000-0000-4000-8000-000000000001"
  managed_scenario.assert_no_pending(scenario)
}

fn interpret_api_log(
  scenario: ApiLogScenario,
  next_command: command.Command(detail.Msg),
) -> ApiLogScenario {
  case next_command {
    command.None -> scenario
    _ -> managed_scenario.append_pending(scenario, next_command)
  }
}

pub fn mapping_admin_commands_preserves_the_fixture_callback_test() {
  let assert Ok(id) = uuid.from_string("00000000-0000-4000-8000-000000000002")
  let #(_, request_command) =
    detail.init(id)
    |> fn(initial) { detail.ensure_loaded(initial.0) }
  let mapped = command.map(request_command, fn(message) { #(42, message) })
  let assert command.Logs(logs.GetApiLog(_, complete)) = mapped
  let failure = response.ApiFailure(response.Error("fixture", "Mapped", id))
  let #(marker, detail_message.LogLoaded(_)) = complete(failure)
  assert marker == 42
}

pub fn stale_admin_pagination_response_is_ignored_test() {
  let assert Ok(id) = uuid.from_string("00000000-0000-4000-8000-000000000004")
  let #(model, _) = api_logs.init()
  let #(model, first_command) = api_logs.ensure_loaded(model)
  let assert command.Logs(logs.GetApiLogs(_, complete_first)) = first_command

  let #(model, second_command) =
    api_logs.update(
      model,
      api_logs_message.ErrorFilterSelected(api_log_dto.OnlyApiLogsWithErrors),
    )
  let assert command.Logs(logs.GetApiLogs(_, complete_second)) = second_command

  let stale = response.ApiFailure(response.Error("stale", "Stale", id))
  let #(model_after_stale, _) = api_logs.update(model, complete_first(stale))
  assert model_after_stale == model

  let latest = response.ApiFailure(response.Error("latest", "Latest", id))
  let #(model_after_latest, _) =
    api_logs.update(model_after_stale, complete_second(latest))
  let assert loadable.LoadError(message) = model_after_latest.page
  assert message == "Latest Request ID: 00000000-0000-4000-8000-000000000004"
}

pub fn stale_admin_mutation_response_is_ignored_test() {
  let assert Ok(id) = uuid.from_string("00000000-0000-4000-8000-000000000005")
  let stale_generation = request_generation.next(request_generation.initial())
  let current_generation = request_generation.next(stale_generation)
  let model =
    email_template_model.Model(
      name: "fixture",
      template: loadable.NotLoaded,
      draft: email_template_model.Draft("subject", "text", "html"),
      save_state: mutation.Saving,
      save_generation: current_generation,
    )
  let stale = response.ApiFailure(response.Error("stale", "Stale", id))

  let #(unchanged, next_command) =
    email_template.update(
      model,
      email_template_message.SaveFinished(stale_generation, stale),
    )

  assert unchanged == model
  assert next_command == command.None
}

pub fn extracted_admin_reducers_reject_stale_fixture_responses_test() {
  let assert Ok(id) = uuid.from_string("00000000-0000-4000-8000-000000000006")
  let stale_generation = request_generation.initial()
  let current_generation = request_generation.next(stale_generation)

  let #(job, _) = job_detail.init(id)
  let job = job_model.Model(..job, logs_generation: current_generation)
  let #(unchanged_job, job_command) =
    job_detail.update(
      job,
      job_message.JobLogsLoaded(stale_generation, stale_failure(id)),
    )
  assert unchanged_job == job
  assert job_command == command.None

  let #(periodic_job, _) = periodic_job_detail.init(id)
  let periodic_job =
    periodic_job_model.Model(
      ..periodic_job,
      recent_jobs_generation: current_generation,
    )
  let #(unchanged_periodic_job, periodic_job_command) =
    periodic_job_detail.update(
      periodic_job,
      periodic_job_message.RecentJobsLoaded(stale_generation, stale_failure(id)),
    )
  assert unchanged_periodic_job == periodic_job
  assert periodic_job_command == command.None

  let #(rate_limit_model, _) = rate_limits.init()
  let rate_limit_model =
    rate_limit_model.Model(
      ..rate_limit_model,
      load_generation: current_generation,
    )
  let #(unchanged_rate_limits, rate_limit_command) =
    rate_limits.update(
      rate_limit_model,
      rate_limit_message.PoliciesLoaded(stale_generation, stale_failure(id)),
    )
  assert unchanged_rate_limits == rate_limit_model
  assert rate_limit_command == command.None

  let #(user, _) = user_detail.init(id)
  let user = user_model.Model(..user, save_generation: current_generation)
  let #(unchanged_user, user_command) =
    user_detail.update(
      user,
      user_message.SaveFinished(stale_generation, stale_failure(id)),
    )
  assert unchanged_user == user
  assert user_command == command.None
}

fn stale_failure(id: uuid.Uuid) -> response.Response(value) {
  response.ApiFailure(response.Error("stale", "Stale", id))
}

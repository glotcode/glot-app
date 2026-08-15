import gleam/dict
import gleam/erlang/process
import gleam/option
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/app_config/model/system_config
import glot_backend/app_config/worker/cache/worker as app_config_cache_worker
import glot_backend/auth/model/config as auth_feature_config
import glot_backend/email/model/config as email_feature_config
import glot_backend/logging/ingestion/model/config as logging_config
import glot_backend/request_policy/model/config as request_policy_config
import glot_backend/run_code/model/config as run_code_config
import glot_backend/system/effect/error/db_error
import glot_backend/system/lifecycle/server_mode/adapter/worker as server_mode_adapter
import glot_backend/system/lifecycle/server_mode/model as server_mode
import glot_backend/system/lifecycle/server_mode/worker as server_mode_worker
import glot_core/auth/account_model
import glot_core/availability_mode
import glot_core/public_action
import glot_core/rate_limit
import support/process as test_process

type ControlMessage {
  RegisterFetch(
    reply: process.Subject(
      Result(dynamic_config.DynamicConfig, db_error.DbQueryError),
    ),
  )
  TakeFetch(
    reply: process.Subject(
      option.Option(
        process.Subject(
          Result(dynamic_config.DynamicConfig, db_error.DbQueryError),
        ),
      ),
    ),
  )
  GetFetchCount(reply: process.Subject(Int))
  ConfigUpdated
  GetConfigUpdatedCount(reply: process.Subject(Int))
  SetNow(Int)
  GetNow(reply: process.Subject(Int))
}

type ControlState {
  ControlState(
    fetch_count: Int,
    config_updated_count: Int,
    now_ns: Int,
    pending_fetches: List(
      process.Subject(
        Result(dynamic_config.DynamicConfig, db_error.DbQueryError),
      ),
    ),
  )
}

pub fn concurrent_cold_misses_are_deduped_test() {
  let control_name = process.new_name("app_config_control")
  let worker_name = process.new_name("app_config_worker")
  let control_subject = start_control(control_name)
  let #(worker_subject, _) =
    start_worker(worker_name, control_subject, server_mode.Running)
  let result_subject = process.new_subject()

  request_config(worker_subject, result_subject)
  request_config(worker_subject, result_subject)

  assert wait_for_fetch_count(control_subject, 1) == 1

  let fetch_reply = expect_fetch(control_subject)
  process.send(fetch_reply, Ok(test_dynamic_config()))

  let first = expect_result(result_subject)
  let second = expect_result(result_subject)
  assert first == Ok(test_dynamic_config())
  assert second == Ok(test_dynamic_config())
  assert test_process.call(control_subject, GetFetchCount) == 1
  assert test_process.eventually(
      fn() { test_process.call(control_subject, GetConfigUpdatedCount) },
      fn(count) { count == 1 },
    )
    == 1
}

pub fn stale_value_is_served_while_refresh_runs_test() {
  let control_name = process.new_name("app_config_control")
  let worker_name = process.new_name("app_config_worker")
  let control_subject = start_control(control_name)
  let #(worker_subject, _) =
    start_worker(worker_name, control_subject, server_mode.Running)
  let result_subject = process.new_subject()

  request_config(worker_subject, result_subject)
  let initial_fetch_reply = expect_fetch(control_subject)
  process.send(initial_fetch_reply, Ok(test_dynamic_config()))
  assert expect_result(result_subject) == Ok(test_dynamic_config())

  process.send(control_subject, SetNow(60_000_000_001))

  let stale_result = app_config_cache_worker.get_config(worker_subject)
  assert stale_result == Ok(test_dynamic_config())

  let refresh_reply = expect_fetch(control_subject)
  process.send(refresh_reply, Ok(updated_dynamic_config()))

  assert wait_for_config(worker_subject) == Ok(updated_dynamic_config())
}

pub fn failed_refresh_keeps_stale_value_test() {
  let control_name = process.new_name("app_config_control")
  let worker_name = process.new_name("app_config_worker")
  let control_subject = start_control(control_name)
  let #(worker_subject, _) =
    start_worker(worker_name, control_subject, server_mode.Running)
  let result_subject = process.new_subject()

  request_config(worker_subject, result_subject)
  let initial_fetch_reply = expect_fetch(control_subject)
  process.send(initial_fetch_reply, Ok(test_dynamic_config()))
  assert expect_result(result_subject) == Ok(test_dynamic_config())

  process.send(control_subject, SetNow(60_000_000_001))

  let stale_result = app_config_cache_worker.get_config(worker_subject)
  assert stale_result == Ok(test_dynamic_config())

  let refresh_reply = expect_fetch(control_subject)
  process.send(refresh_reply, Error(db_error.DbQueryError("refresh failed")))

  assert app_config_cache_worker.get_config(worker_subject)
    == Ok(test_dynamic_config())
}

pub fn maintenance_mode_uses_empty_config_without_fetching_test() {
  let control_name = process.new_name("app_config_control")
  let worker_name = process.new_name("app_config_worker")
  let control_subject = start_control(control_name)
  let #(worker_subject, server_mode_subject) =
    start_worker(worker_name, control_subject, server_mode.Maintenance)

  assert app_config_cache_worker.get_config(worker_subject)
    == Ok(dynamic_config.empty())
  assert test_process.call(control_subject, GetFetchCount) == 0

  server_mode_worker.enter_running(server_mode_subject)
  let result_subject = process.new_subject()
  request_config(worker_subject, result_subject)

  assert wait_for_fetch_count(control_subject, 1) == 1
  let fetch_reply = expect_fetch(control_subject)
  process.send(fetch_reply, Ok(test_dynamic_config()))
  assert expect_result(result_subject) == Ok(test_dynamic_config())
}

fn start_worker(
  worker_name: process.Name(app_config_cache_worker.Message),
  control_subject: process.Subject(ControlMessage),
  mode: server_mode.Mode,
) -> #(
  process.Subject(app_config_cache_worker.Message),
  process.Subject(server_mode_worker.Message),
) {
  let server_mode_name = process.new_name("app_config_server_mode")
  let assert Ok(_) = server_mode_worker.start_in(server_mode_name, mode)
  let server_mode_subject = process.named_subject(server_mode_name)

  let handlers =
    app_config_cache_worker.Deps(
      fetch_config: fn() {
        let response_subject = process.new_subject()
        process.send(control_subject, RegisterFetch(reply: response_subject))
        test_process.receive(response_subject)
      },
      now_ns: fn() { test_process.call(control_subject, GetNow) },
      config_updated: fn(_) {
        process.send(control_subject, ConfigUpdated)
        Ok(Nil)
      },
    )

  let assert Ok(_) =
    app_config_cache_worker.start_with_deps(
      worker_name,
      server_mode_adapter.new(server_mode_subject),
      handlers,
    )
  #(process.named_subject(worker_name), server_mode_subject)
}

fn start_control(
  name: process.Name(ControlMessage),
) -> process.Subject(ControlMessage) {
  let subject = process.named_subject(name)
  let ready = process.new_subject()
  let _ =
    process.spawn(fn() {
      let assert Ok(Nil) = process.register(process.self(), name)
      process.send(ready, Nil)
      control_loop(
        subject,
        ControlState(
          fetch_count: 0,
          config_updated_count: 0,
          now_ns: 0,
          pending_fetches: [],
        ),
      )
    })
  let Nil = test_process.receive(ready)
  subject
}

fn control_loop(
  subject: process.Subject(ControlMessage),
  state: ControlState,
) -> Nil {
  case process.receive_forever(subject) {
    RegisterFetch(reply) ->
      control_loop(
        subject,
        ControlState(
          ..state,
          fetch_count: state.fetch_count + 1,
          pending_fetches: [reply, ..state.pending_fetches],
        ),
      )
    TakeFetch(reply) -> {
      let #(maybe_fetch, pending_fetches) = case state.pending_fetches {
        [first, ..rest] -> #(option.Some(first), rest)
        [] -> #(option.None, [])
      }
      process.send(reply, maybe_fetch)
      control_loop(
        subject,
        ControlState(..state, pending_fetches: pending_fetches),
      )
    }
    GetFetchCount(reply) -> {
      process.send(reply, state.fetch_count)
      control_loop(subject, state)
    }
    ConfigUpdated ->
      control_loop(
        subject,
        ControlState(
          ..state,
          config_updated_count: state.config_updated_count + 1,
        ),
      )
    GetConfigUpdatedCount(reply) -> {
      process.send(reply, state.config_updated_count)
      control_loop(subject, state)
    }
    SetNow(now_ns) ->
      control_loop(subject, ControlState(..state, now_ns: now_ns))
    GetNow(reply) -> {
      process.send(reply, state.now_ns)
      control_loop(subject, state)
    }
  }
}

fn request_config(
  worker_subject: process.Subject(app_config_cache_worker.Message),
  result_subject: process.Subject(
    Result(dynamic_config.DynamicConfig, db_error.DbQueryError),
  ),
) -> Nil {
  let _ =
    process.spawn_unlinked(fn() {
      let result = app_config_cache_worker.get_config(worker_subject)
      process.send(result_subject, result)
    })
  Nil
}

fn expect_fetch(
  control_subject: process.Subject(ControlMessage),
) -> process.Subject(
  Result(dynamic_config.DynamicConfig, db_error.DbQueryError),
) {
  let maybe_fetch =
    test_process.eventually(
      fn() { test_process.call(control_subject, TakeFetch) },
      fn(result) {
        case result {
          option.Some(_) -> True
          option.None -> False
        }
      },
    )
  let assert option.Some(fetch_reply) = maybe_fetch
  fetch_reply
}

fn wait_for_fetch_count(
  control_subject: process.Subject(ControlMessage),
  expected_count: Int,
) -> Int {
  test_process.eventually(
    fn() { test_process.call(control_subject, GetFetchCount) },
    fn(fetch_count) { fetch_count == expected_count },
  )
}

fn wait_for_config(
  worker_subject: process.Subject(app_config_cache_worker.Message),
) -> Result(dynamic_config.DynamicConfig, db_error.DbQueryError) {
  test_process.eventually(
    fn() { app_config_cache_worker.get_config(worker_subject) },
    fn(result) { result == Ok(updated_dynamic_config()) },
  )
}

fn expect_result(
  result_subject: process.Subject(
    Result(dynamic_config.DynamicConfig, db_error.DbQueryError),
  ),
) -> Result(dynamic_config.DynamicConfig, db_error.DbQueryError) {
  test_process.receive(result_subject)
}

fn test_dynamic_config() -> dynamic_config.DynamicConfig {
  dynamic_config.DynamicConfig(
    debug: system_config.DebugConfig(enabled: False),
    http_pool: system_config.HttpPoolConfig(16, 4, 120_000),
    availability: request_policy_config.AvailabilityConfig(
      mode: availability_mode.NormalMode,
      message: "glot.io is temporarily unavailable right now.",
      retry_after_seconds: option.None,
    ),
    auth: auth_feature_config.AuthConfig(
      login_token_max_age: 900,
      session_token_max_age: 86_400,
      session_idle_timeout_seconds: 86_400,
      session_cookie_max_age: 86_400,
      session_refresh_interval_seconds: 300,
      session_previous_token_grace_seconds: 60,
      session_heartbeat_interval_seconds: 60,
    ),
    passkey: auth_feature_config.PasskeyConfig(
      origin: "https://glot.io",
      rp_id: "glot.io",
      challenge_timeout_seconds: 120,
    ),
    cleanup: system_config.CleanupConfig(
      api_log_retention_days: 30,
      page_log_retention_days: 30,
      pageview_log_retention_days: 30,
      run_log_retention_days: 90,
      job_log_retention_days: 90,
      jobs_retention_days: 90,
      login_tokens_retention_days: 30,
      user_actions_retention_days: 90,
    ),
    log_worker: logging_config.Config(
      flush_interval_ms: 5000,
      max_batch_size: 100,
      max_buffer_size: 1000,
    ),
    language_version_cache_worker: run_code_config.LanguageVersionCacheWorkerConfig(
      refresh_interval_ms: 3_600_000,
      refresh_step_delay_ms: 1000,
      refresh_step_jitter_ms: 500,
      default_timeout_ms: 60_000,
    ),
    docker_run: option.Some(run_code_config.DockerRunConfig(
      base_url: "http://docker-run",
      access_token: "test-token",
      default_timeout_ms: 60_000,
    )),
    spam_classifier: option.None,
    cloudflare: option.None,
    email: option.Some(email_feature_config.EmailConfig(
      from_address: "sender@example.com",
      from_name: option.Some("Sender"),
      contact_address: option.None,
      default_timeout_ms: 60_000,
    )),
    rate_limit_policies: dict.from_list([
      #(
        public_action.RunAction,
        request_policy_config.RateLimitPolicy(rules: [
          request_policy_config.RateLimitRule(
            match: request_policy_config.AnonymousMatch,
            limits: [
              rate_limit.RateLimit(unit: rate_limit.Minute, max_requests: 2),
            ],
          ),
          request_policy_config.RateLimitRule(
            match: request_policy_config.AuthenticatedMatch(
              account_tiers: option.Some([
                account_model.FreeTier,
              ]),
            ),
            limits: [
              rate_limit.RateLimit(unit: rate_limit.Minute, max_requests: 5),
            ],
          ),
        ]),
      ),
    ]),
  )
}

fn updated_dynamic_config() -> dynamic_config.DynamicConfig {
  dynamic_config.DynamicConfig(
    debug: system_config.DebugConfig(enabled: True),
    http_pool: system_config.HttpPoolConfig(16, 4, 120_000),
    availability: request_policy_config.AvailabilityConfig(
      mode: availability_mode.MaintenanceMode,
      message: "Maintenance is in progress.",
      retry_after_seconds: option.Some(300),
    ),
    auth: auth_feature_config.AuthConfig(
      login_token_max_age: 900,
      session_token_max_age: 86_400,
      session_idle_timeout_seconds: 86_400,
      session_cookie_max_age: 86_400,
      session_refresh_interval_seconds: 300,
      session_previous_token_grace_seconds: 60,
      session_heartbeat_interval_seconds: 60,
    ),
    passkey: auth_feature_config.PasskeyConfig(
      origin: "https://glot.io",
      rp_id: "glot.io",
      challenge_timeout_seconds: 180,
    ),
    cleanup: system_config.CleanupConfig(
      api_log_retention_days: 30,
      page_log_retention_days: 30,
      pageview_log_retention_days: 30,
      run_log_retention_days: 90,
      job_log_retention_days: 90,
      jobs_retention_days: 90,
      login_tokens_retention_days: 30,
      user_actions_retention_days: 90,
    ),
    log_worker: logging_config.Config(
      flush_interval_ms: 2500,
      max_batch_size: 200,
      max_buffer_size: 1500,
    ),
    language_version_cache_worker: run_code_config.LanguageVersionCacheWorkerConfig(
      refresh_interval_ms: 1_800_000,
      refresh_step_delay_ms: 750,
      refresh_step_jitter_ms: 250,
      default_timeout_ms: 45_000,
    ),
    docker_run: option.Some(run_code_config.DockerRunConfig(
      base_url: "http://docker-run-2",
      access_token: "updated-token",
      default_timeout_ms: 45_000,
    )),
    spam_classifier: option.None,
    cloudflare: option.None,
    email: option.Some(email_feature_config.EmailConfig(
      from_address: "updated-sender@example.com",
      from_name: option.Some("Updated Sender"),
      contact_address: option.None,
      default_timeout_ms: 45_000,
    )),
    rate_limit_policies: dict.from_list([
      #(
        public_action.RunAction,
        request_policy_config.RateLimitPolicy(rules: [
          request_policy_config.RateLimitRule(
            match: request_policy_config.AuthenticatedMatch(
              account_tiers: option.None,
            ),
            limits: [
              rate_limit.RateLimit(unit: rate_limit.Minute, max_requests: 9),
            ],
          ),
        ]),
      ),
    ]),
  )
}

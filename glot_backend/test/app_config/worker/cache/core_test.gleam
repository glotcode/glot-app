import gleam/dict
import gleam/erlang/process
import gleam/list
import gleam/option
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/app_config/model/system_config
import glot_backend/app_config/worker/cache/core as app_config_cache_worker_core
import glot_backend/auth/model/config as auth_feature_config
import glot_backend/email/model/config as email_feature_config
import glot_backend/logging/ingestion/model/config as logging_config
import glot_backend/request_policy/model/config as request_policy_config
import glot_backend/run_code/model/config as run_code_config
import glot_backend/system/cache/cache_outcome
import glot_backend/system/cache/worker/state as cache_worker_state
import glot_backend/system/cache/worker/support as cache_worker_support
import glot_backend/system/effect/error/db_error
import glot_core/auth/account_model
import glot_core/availability_mode
import glot_core/public_action
import glot_core/rate_limit
import support/process as test_process

pub fn core_cold_miss_starts_fetch_and_waits_test() {
  let reply = process.new_subject()
  let #(state, commands) =
    app_config_cache_worker_core.on_get(
      app_config_cache_worker_core.new(),
      reply,
      0,
      True,
    )

  assert count_start_fetch(commands) == 1
  assert count_reply(commands) == 0
  let app_config_cache_worker_core.State(cache:) = state
  assert cache_worker_state.single_in_flight(cache) != option.None

  let #(_state, completed_commands) =
    app_config_cache_worker_core.on_fetch_completed(
      state,
      1,
      Ok(test_dynamic_config()),
    )
  assert count_config_updated(completed_commands) == 1
  run_core_commands(completed_commands)
  assert test_process.receive(reply)
    == cache_worker_support.Lookup(
      Ok(test_dynamic_config()),
      cache_outcome.CacheMissFetched,
    )
}

pub fn core_stale_hit_replies_immediately_and_refreshes_test() {
  let reply = process.new_subject()
  let state =
    app_config_cache_worker_core.State(cache: cache_worker_state.Single(
      cache_entry: option.Some(cache_worker_support.CacheEntry(
        value: test_dynamic_config(),
        refreshed_at_ns: 0,
      )),
      in_flight: option.None,
    ))
  let #(next_state, commands) =
    app_config_cache_worker_core.on_get(state, reply, 60_000_000_001, True)

  assert count_start_fetch(commands) == 1
  run_core_commands(commands)
  assert test_process.receive(reply)
    == cache_worker_support.Lookup(
      Ok(test_dynamic_config()),
      cache_outcome.StaleCacheHit,
    )
  let app_config_cache_worker_core.State(cache:) = next_state
  assert cache_worker_state.single_in_flight(cache) != option.None
}

pub fn core_failed_refresh_keeps_stale_cache_test() {
  let reply = process.new_subject()
  let waiter = process.new_subject()
  let state =
    app_config_cache_worker_core.State(cache: cache_worker_state.Single(
      cache_entry: option.Some(cache_worker_support.CacheEntry(
        value: test_dynamic_config(),
        refreshed_at_ns: 0,
      )),
      in_flight: option.Some(
        cache_worker_support.new_in_flight(Nil)
        |> cache_worker_support.with_waiter(waiter),
      ),
    ))
  let #(next_state, commands) =
    app_config_cache_worker_core.on_fetch_completed(
      state,
      1,
      Error(db_error.DbQueryError("refresh failed")),
    )

  run_core_commands(commands)
  assert test_process.receive(waiter)
    == cache_worker_support.Lookup(
      Error(db_error.DbQueryError("refresh failed")),
      cache_outcome.CacheMissJoined,
    )
  let app_config_cache_worker_core.State(cache:) = next_state
  assert cache_worker_state.single_in_flight(cache) == option.None
  assert cache_worker_state.single_cache_entry(cache) != option.None
  let #(lookup_state, lookup_commands) =
    app_config_cache_worker_core.on_get(next_state, reply, 1, True)
  assert count_reply(lookup_commands) == 1
  run_core_commands(lookup_commands)
  assert test_process.receive(reply)
    == cache_worker_support.Lookup(
      Ok(test_dynamic_config()),
      cache_outcome.CacheHit,
    )
  assert lookup_state == next_state
}

fn count_start_fetch(
  commands: List(app_config_cache_worker_core.Command),
) -> Int {
  list.length(
    list.filter(commands, fn(command) {
      case command {
        app_config_cache_worker_core.StartFetch -> True
        _ -> False
      }
    }),
  )
}

fn count_reply(commands: List(app_config_cache_worker_core.Command)) -> Int {
  list.length(
    list.filter(commands, fn(command) {
      case command {
        app_config_cache_worker_core.Reply(_, _) -> True
        _ -> False
      }
    }),
  )
}

fn count_config_updated(
  commands: List(app_config_cache_worker_core.Command),
) -> Int {
  list.length(
    list.filter(commands, fn(command) {
      case command {
        app_config_cache_worker_core.ConfigUpdated(_) -> True
        _ -> False
      }
    }),
  )
}

fn run_core_commands(
  commands: List(app_config_cache_worker_core.Command),
) -> Nil {
  list.each(commands, fn(command) {
    case command {
      app_config_cache_worker_core.Reply(reply, result) ->
        process.send(reply, result)
      _ -> Nil
    }
  })
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

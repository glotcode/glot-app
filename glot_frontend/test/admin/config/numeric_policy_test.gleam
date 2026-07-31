import gleam/list
import gleeunit
import glot_core/admin/auth_config_dto
import glot_core/admin/cleanup_config_dto
import glot_core/admin/http_pool_config_dto
import glot_core/admin/language_version_cache_worker_config_dto as language_dto
import glot_core/admin/log_worker_config_dto
import glot_frontend/admin/config/auth_policy
import glot_frontend/admin/config/cleanup_policy
import glot_frontend/admin/config/http_pool_policy
import glot_frontend/admin/config/language_version_cache_worker_policy as language_policy
import glot_frontend/admin/config/log_worker_policy

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn auth_policy_maps_every_field_and_builds_requests_test() {
  let response = auth_config_dto.AuthConfigResponse(1, 2, 3, 4, 5, 6, 7)
  let fields = auth_policy.from_response(response)

  assert fields == auth_policy.Fields("1", "2", "3", "4", "5", "6", "7")
  assert auth_policy.request(fields)
    == Ok(auth_config_dto.UpsertAuthConfigRequest(1, 2, 3, 4, 5, 6, 7))

  let updates = [
    #(auth_policy.LoginTokenMaxAge, "login"),
    #(auth_policy.SessionTokenMaxAge, "lifetime"),
    #(auth_policy.SessionIdleTimeout, "idle"),
    #(auth_policy.SessionCookieMaxAge, "cookie"),
    #(auth_policy.SessionRefreshInterval, "refresh"),
    #(auth_policy.PreviousTokenGrace, "grace"),
    #(auth_policy.HeartbeatInterval, "heartbeat"),
  ]
  let updated =
    list.fold(updates, auth_policy.initial(), fn(fields, update) {
      let #(field, value) = update
      auth_policy.set(fields, field, value)
    })
  assert updated
    == auth_policy.Fields(
      "login",
      "lifetime",
      "idle",
      "cookie",
      "refresh",
      "grace",
      "heartbeat",
    )
}

pub fn auth_policy_validates_every_duration_test() {
  let valid = auth_policy.Fields("1", "2", "3", "4", "5", "6", "7")
  let failures = [
    #(
      auth_policy.LoginTokenMaxAge,
      "Login token max age must be a positive integer.",
    ),
    #(
      auth_policy.SessionTokenMaxAge,
      "Session max lifetime must be a positive integer.",
    ),
    #(
      auth_policy.SessionIdleTimeout,
      "Session idle timeout must be a positive integer.",
    ),
    #(
      auth_policy.SessionCookieMaxAge,
      "Session cookie max age must be a positive integer.",
    ),
    #(
      auth_policy.SessionRefreshInterval,
      "Session rotation interval must be a positive integer.",
    ),
    #(
      auth_policy.PreviousTokenGrace,
      "Previous token grace window must be a positive integer.",
    ),
    #(
      auth_policy.HeartbeatInterval,
      "Heartbeat cadence must be a positive integer.",
    ),
  ]

  list.each(failures, fn(failure) {
    let #(field, message) = failure
    assert auth_policy.request(auth_policy.set(valid, field, "0"))
      == Error(message)
  })
}

pub fn cleanup_policy_maps_and_validates_every_retention_test() {
  let response =
    cleanup_config_dto.CleanupConfigResponse(1, 2, 3, 4, 5, 6, 7, 8)
  let fields = cleanup_policy.from_response(response)
  assert cleanup_policy.request(fields)
    == Ok(cleanup_config_dto.UpsertCleanupConfigRequest(1, 2, 3, 4, 5, 6, 7, 8))

  let failures = [
    #(cleanup_policy.ApiLog, "API log retention"),
    #(cleanup_policy.PageLog, "Page log retention"),
    #(cleanup_policy.PageviewLog, "Pageview log retention"),
    #(cleanup_policy.RunLog, "Run log retention"),
    #(cleanup_policy.JobLog, "Job log retention"),
    #(cleanup_policy.Jobs, "Jobs retention"),
    #(cleanup_policy.LoginTokens, "Login token retention"),
    #(cleanup_policy.UserActions, "User actions retention"),
  ]
  list.each(failures, fn(failure) {
    let #(field, label) = failure
    assert cleanup_policy.request(cleanup_policy.set(fields, field, "0"))
      == Error(label <> " must be a positive integer.")
  })
}

pub fn language_cache_policy_keeps_zero_jitter_as_the_only_zero_test() {
  let fields =
    language_policy.from_response(
      language_dto.LanguageVersionCacheWorkerConfigResponse(1, 2, 0, 4),
    )
  assert language_policy.request(fields)
    == Ok(language_dto.UpsertLanguageVersionCacheWorkerConfigRequest(1, 2, 0, 4))
  assert language_policy.request(language_policy.set(
      fields,
      language_policy.RefreshStepJitter,
      "-1",
    ))
    == Error("Refresh step jitter must be 0 or a positive integer.")

  let failures = [
    #(
      language_policy.RefreshInterval,
      "Refresh interval must be a positive integer.",
    ),
    #(
      language_policy.RefreshStepDelay,
      "Refresh step delay must be a positive integer.",
    ),
    #(
      language_policy.DefaultTimeout,
      "Default timeout must be a positive integer.",
    ),
  ]
  list.each(failures, fn(failure) {
    let #(field, message) = failure
    assert language_policy.request(language_policy.set(fields, field, "0"))
      == Error(message)
  })
}

pub fn http_pool_policy_maps_and_validates_all_limits_test() {
  let fields =
    http_pool_policy.from_response(http_pool_config_dto.HttpPoolConfigResponse(
      1,
      2,
      3,
    ))
  assert http_pool_policy.request(fields)
    == Ok(http_pool_config_dto.UpsertHttpPoolConfigRequest(1, 2, 3))

  let failures = [
    #(
      http_pool_policy.DockerRunMaxSessions,
      "Docker-run max sessions must be a positive integer.",
    ),
    #(
      http_pool_policy.CloudflareEmailMaxSessions,
      "Cloudflare email max sessions must be a positive integer.",
    ),
    #(
      http_pool_policy.KeepAliveTimeout,
      "Keep-alive timeout must be a positive integer.",
    ),
  ]
  list.each(failures, fn(failure) {
    let #(field, message) = failure
    assert http_pool_policy.request(http_pool_policy.set(fields, field, "0"))
      == Error(message)
  })
}

pub fn log_worker_policy_maps_and_validates_all_limits_test() {
  let fields =
    log_worker_policy.from_response(
      log_worker_config_dto.LogWorkerConfigResponse(1, 2, 3),
    )
  assert log_worker_policy.request(fields)
    == Ok(log_worker_config_dto.UpsertLogWorkerConfigRequest(1, 2, 3))

  let failures = [
    #(
      log_worker_policy.FlushInterval,
      "Flush interval must be a positive integer.",
    ),
    #(
      log_worker_policy.MaxBatchSize,
      "Max batch size must be a positive integer.",
    ),
    #(
      log_worker_policy.MaxBufferSize,
      "Max buffer size must be a positive integer.",
    ),
  ]
  list.each(failures, fn(failure) {
    let #(field, message) = failure
    assert log_worker_policy.request(log_worker_policy.set(fields, field, "0"))
      == Error(message)
  })
}

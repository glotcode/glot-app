import gleam/option
import gleam/regexp
import gleam/time/timestamp
import glot_backend/analytics/ports/store as analytics_store
import glot_backend/app_config/model/entry as app_config
import glot_backend/app_config/ports/store as app_config_store
import glot_backend/auth/passkey/ports/ceremony as passkey_ceremony
import glot_backend/auth/ports as auth_ports
import glot_backend/auth/ports/account_store
import glot_backend/auth/ports/email_change_token_store
import glot_backend/auth/ports/login_token_store
import glot_backend/auth/ports/passkey_store
import glot_backend/auth/ports/session_store
import glot_backend/auth/ports/user_store
import glot_backend/email/ports/sender as email_sender
import glot_backend/email/ports/template_store
import glot_backend/job/ports as job_ports
import glot_backend/job/ports/job_store
import glot_backend/job/ports/log_store
import glot_backend/job/ports/periodic_store
import glot_backend/job/ports/type_policy_store
import glot_backend/logging/api_log/ports/store as api_log_store
import glot_backend/logging/page_log/ports/store as page_log_store
import glot_backend/logging/pageview/ports/store as pageview_store
import glot_backend/logging/ports as logging_ports
import glot_backend/logging/run_log/ports/store as run_log_store
import glot_backend/run_code/ports/runner
import glot_backend/snippet/ports/store as snippet_store
import glot_backend/system/crypto/token
import glot_backend/system/effect/basic/basic_algebra
import glot_backend/system/effect/basic/basic_effect
import glot_backend/system/effect/basic/basic_handlers
import glot_backend/system/effect/cache_ports
import glot_backend/system/effect/database_ports
import glot_backend/system/effect/effect_trace
import glot_backend/system/effect/error
import glot_backend/system/effect/error/db_error
import glot_backend/system/effect/error/infra_error
import glot_backend/system/effect/error/run_request_error
import glot_backend/system/effect/interpreter
import glot_backend/system/effect/log
import glot_backend/system/effect/program
import glot_backend/system/effect/runtime
import glot_backend/system/effect/service_ports
import glot_backend/system/effect/system_ports
import glot_backend/system/effect/transaction/transaction_effect
import glot_backend/system/effect/transaction/transaction_port
import glot_backend/system/effect/transaction/transaction_program
import glot_backend/system/request/context
import glot_backend/user_action/ports/store as user_action_store
import glot_core/job/job_model
import glot_core/validation_error
import youid/uuid

pub fn measurement_aggregation_test() {
  let effect_runtime = test_runtime()
  let ctx = test_context()
  let measured_effect = {
    use _ <- program.and_then(basic_effect.info(log.new()))
    use _ <- program.and_then(basic_effect.info(log.new()))
    program.succeed("ok")
  }

  let #(run_result, state) =
    interpreter.run(measured_effect, effect_runtime, ctx)

  assert run_result == Ok("ok")
  let assert [
    effect_trace.EffectMeasurement(
      name: effect_trace.BasicEffectName(basic_algebra.LogEffectName(log.Info)),
      duration_ns: first,
      ..,
    ),
    effect_trace.EffectMeasurement(
      name: effect_trace.BasicEffectName(basic_algebra.LogEffectName(log.Info)),
      duration_ns: second,
      ..,
    ),
  ] = state.effect_measurements
  assert first >= 0
  assert second >= 0
}

pub fn measures_effects_in_success_test() {
  let effect_runtime = test_runtime()
  let ctx = test_context()
  let measured_effect = {
    use _ <- program.and_then(basic_effect.new_token(5, token.AlphaNumeric))
    program.succeed("ok")
  }
  let #(run_result, state) =
    interpreter.run(measured_effect, effect_runtime, ctx)

  assert run_result == Ok("ok")
  let assert [
    effect_trace.EffectMeasurement(
      name: effect_trace.BasicEffectName(basic_algebra.NewTokenEffectName),
      duration_ns: duration_ms,
      ..,
    ),
  ] = state.effect_measurements
  assert duration_ms >= 0
}

pub fn measures_effects_in_error_test() {
  let effect_runtime = test_runtime()
  let ctx = test_context()
  let failing_effect = {
    use _ <- program.and_then(basic_effect.new_token(5, token.AlphaNumeric))
    program.fail(error.validation(validation_error.InvalidLimit))
  }
  let #(run_result, state) =
    interpreter.run(failing_effect, effect_runtime, ctx)

  assert run_result == Error(error.validation(validation_error.InvalidLimit))
  let assert [
    effect_trace.EffectMeasurement(
      name: effect_trace.BasicEffectName(basic_algebra.NewTokenEffectName),
      duration_ns: duration_ms,
      ..,
    ),
  ] = state.effect_measurements
  assert duration_ms >= 0
}

pub fn suppressed_debug_log_is_not_stored_or_measured_test() {
  let effect_runtime = test_runtime()
  let ctx = test_context()
  let measured_effect = {
    use _ <- program.and_then(
      basic_effect.debug(
        log.from_list([log.string("debug_key", "debug_value")]),
      ),
    )
    program.succeed("ok")
  }

  let #(run_result, state) =
    interpreter.run(measured_effect, effect_runtime, ctx)

  assert run_result == Ok("ok")
  assert state.debug_fields == log.new()
  assert state.effect_measurements == []
}

pub fn transaction_adapter_contract_error_is_mapped_test() {
  let services =
    service_ports.ServicePorts(
      ..test_service_ports(),
      transaction: transaction_port.new(fn(_, _) { Ok(Nil) }),
    )
  let effect =
    transaction_effect.run(transaction_program.succeed("not returned"))

  let #(run_result, _) =
    interpreter.run(effect, runtime.new(services), test_context())

  assert run_result
    == Error(
      error.database_transaction_error(db_error.DbTransactionError(
        "Transaction adapter contract violation: callback_not_invoked",
      )),
    )
}

fn test_service_ports() -> service_ports.ServicePorts {
  let accounts =
    account_store.AccountStore(
      create: fn(_) { Ok(Nil) },
      update: fn(_) { Ok(Nil) },
      delete: fn(_) { Ok(Nil) },
    )
  let users =
    user_store.UserStore(
      get_by_email: fn(_, _) { Ok(option.None) },
      get_by_id: fn(_, _) { Ok(option.None) },
      get_by_id_for_update: fn(_, _) { Ok(option.None) },
      list: fn(_, _, _) { Ok([]) },
      create: fn(_) { Ok(Nil) },
      update_last_login: fn(_, _) { Ok(Nil) },
      update_email: fn(_, _, _) { Ok(Nil) },
      update_username: fn(_, _, _) { Ok(Nil) },
      update_role: fn(_, _, _) { Ok(Nil) },
      lock_email: fn(_) { Ok(Nil) },
      delete_by_account_id: fn(_) { Ok(Nil) },
    )
  let sessions =
    session_store.SessionStore(
      list_by_user_id: fn(_, _, _) { Ok([]) },
      get_by_token: fn(_, _) { Ok(option.None) },
      get_by_token_for_update: fn(_) { Ok(option.None) },
      get_by_previous_token: fn(_, _) { Ok(option.None) },
      get_by_previous_token_for_update: fn(_) { Ok(option.None) },
      create: fn(_) { Ok(Nil) },
      update: fn(_) { Ok(Nil) },
      delete: fn(_) { Ok(Nil) },
      delete_by_account_id: fn(_) { Ok(Nil) },
      delete_expired: fn(_, _) { Ok(Nil) },
    )
  let login_tokens =
    login_token_store.LoginTokenStore(
      list_by_email: fn(_, _, _) { Ok([]) },
      create: fn(_) { Ok(Nil) },
      update: fn(_) { Ok(Nil) },
      delete_before: fn(_) { Ok(Nil) },
      invalidate_by_emails: fn(_, _, _) { Ok(Nil) },
    )
  let passkeys =
    passkey_store.PasskeyStore(
      get_credential_by_credential_id: fn(_) { Ok(option.None) },
      list_credentials_by_user_id: fn(_) { Ok([]) },
      get_challenge_by_id: fn(_) { Ok(option.None) },
      create_credential: fn(_) { Ok(Nil) },
      update_credential: fn(_) { Ok(Nil) },
      delete_credential: fn(_) { Ok(Nil) },
      create_challenge: fn(_) { Ok(Nil) },
      delete_challenge: fn(_) { Ok(Nil) },
    )
  let email_change_tokens =
    email_change_token_store.EmailChangeTokenStore(
      list_by_user_id: fn(_, _, _) { Ok([]) },
      list_by_user_id_for_update: fn(_, _, _) { Ok([]) },
      create: fn(_) { Ok(Nil) },
      update: fn(_) { Ok(Nil) },
      delete_before: fn(_) { Ok(Nil) },
    )
  let auth =
    auth_ports.Ports(
      accounts: accounts,
      users: users,
      sessions: sessions,
      login_tokens: login_tokens,
      passkeys: passkeys,
      email_change_tokens: email_change_tokens,
    )
  let database =
    database_ports.fixed(
      app_config: app_config_store.Store(
        list_entries: fn() {
          Ok([
            app_config.AppConfigEntry(
              namespace: "debug",
              key: "enabled",
              value: "false",
            ),
          ])
        },
        upsert_entries: fn(_, _) { Ok(Nil) },
      ),
      analytics: analytics_store.Store(
        get_max_completed_metrics_day: fn() { Ok(option.None) },
        get_first_metrics_source_day: fn(_) { Ok(option.None) },
        insert_metrics_pageview_day: fn(_) { Ok(Nil) },
        insert_metrics_product_event_day: fn(_) { Ok(Nil) },
        insert_metrics_run_day: fn(_) { Ok(Nil) },
        insert_metrics_reliability_page_day: fn(_) { Ok(Nil) },
        insert_metrics_reliability_api_day: fn(_) { Ok(Nil) },
        insert_metrics_completed_day: fn(_) { Ok(Nil) },
      ),
      email_template: template_store.TemplateStore(
        list: fn() { Ok([]) },
        get: fn(_) { Ok(option.None) },
        update: fn(_) { Ok(Nil) },
      ),
      job: job_ports.Ports(
        jobs: job_store.JobStore(
          list_jobs: fn(_, _) { Ok([]) },
          summarize_jobs: fn(_, _) {
            Ok(job_model.Summary(
              total_count: 0,
              pending_count: 0,
              running_count: 0,
              failed_count: 0,
              done_count: 0,
              overdue_count: 0,
            ))
          },
          get_next_job: fn(_: timestamp.Timestamp, _: job_model.Status) {
            Ok(option.None)
          },
          get_expired_running_job: fn(
            _: timestamp.Timestamp,
            _: job_model.Status,
          ) {
            Ok(option.None)
          },
          get_job_by_id: fn(_) { Ok(option.None) },
          create_job: fn(_) { Ok(Nil) },
          update_job: fn(_) { Ok(Nil) },
          delete_job: fn(_) { Ok(Nil) },
          delete_before: fn(_, _) { Ok(Nil) },
        ),
        logs: log_store.LogStore(
          insert: fn(_) { Ok(Nil) },
          list: fn(_) { Ok([]) },
          get: fn(_) { Ok(option.None) },
          delete_before: fn(_) { Ok(Nil) },
        ),
        type_policies: type_policy_store.TypePolicyStore(
          list_job_type_policies: fn() { Ok([]) },
          get_job_type_policy_by_job_type: fn(_) { Ok(option.None) },
          upsert_job_type_policy: fn(_, _) { Ok(Nil) },
        ),
        periodic: periodic_store.PeriodicStore(
          list_periodic_jobs: fn() { Ok([]) },
          get_next_periodic_job: fn(_) { Ok(option.None) },
          get_periodic_job_by_id: fn(_) { Ok(option.None) },
          create_periodic_job: fn(_) { Ok(Nil) },
          update_periodic_job: fn(_) { Ok(Nil) },
        ),
      ),
      logging: logging_ports.Ports(
        api_log: api_log_store.Store(
          list: fn(_) { Ok([]) },
          get: fn(_) { Ok(option.None) },
          delete_before: fn(_) { Ok(Nil) },
        ),
        page_log: page_log_store.Store(delete_before: fn(_) { Ok(Nil) }),
        pageview: pageview_store.Store(delete_before: fn(_) { Ok(Nil) }),
        run_log: run_log_store.Store(
          create: fn(_) { Ok(Nil) },
          list: fn(_) { Ok([]) },
          get: fn(_) { Ok(option.None) },
          delete_before: fn(_) { Ok(Nil) },
        ),
      ),
      snippet: snippet_store.Store(
        get_snippet_by_id: fn(_) { Ok(option.None) },
        get_snippet_by_slug: fn(_) { Ok(option.None) },
        get_snippet_by_slug_for_update: fn(_) { Ok(option.None) },
        get_admin_snippet_by_slug: fn(_) { Ok(option.None) },
        list_snippets: fn(_, _) { Ok([]) },
        list_admin_snippets: fn(_, _) { Ok([]) },
        delete_snippet: fn(_) { Ok(Nil) },
        delete_snippets_by_account_id: fn(_) { Ok(Nil) },
        create_snippet: fn(_) { Ok(Nil) },
        update_snippet: fn(_) { Ok(Nil) },
      ),
      user_action: user_action_store.Store(
        count: fn(_) { Ok([]) },
        create: fn(_) { Ok(Nil) },
        delete_before: fn(_) { Ok(Nil) },
      ),
      auth: auth,
    )

  service_ports.ServicePorts(
    database: database,
    system: system_ports.SystemPorts(
      basic: basic_handlers.BasicHandlers(
        new_token: fn(_, _) { "random" },
        system_time: timestamp.system_time,
        uuid_v7: fn(_) { uuid.nil },
      ),
      email: email_sender.Sender(send: fn(_, _, _) {
        Error(
          error.infra(
            infra_error.EmailError(infra_error.EmailDeliveryFailed(
              "test_delivery_failure",
              infra_error.Retryable,
            )),
          ),
        )
      }),
      passkey: passkey_ceremony.Ceremony(
        new_registration_challenge: fn(_, _, _) { Error("not implemented") },
        register: fn(_, _, _) { Error("not implemented") },
        new_authentication_challenge: fn(_, _, _, _) {
          Error("not implemented")
        },
        authenticate: fn(_, _, _, _, _, _) { Error("not implemented") },
      ),
      run_code: runner.Runner(run: fn(_, _, _) {
        Error(run_request_error.ServerRunRequestError)
      }),
    ),
    caches: cache_ports.without_caches(),
    transaction: transaction_port.none(),
  )
}

fn test_runtime() -> runtime.Runtime {
  runtime.new(test_service_ports())
}

fn test_context() -> context.Context {
  let assert Ok(is_email) = regexp.from_string(".*")

  context.Context(
    config: context.Config(
      app_env: context.Dev,
      encryption_key: "test",
      listening_address: "localhost",
      listening_port: 3000,
      static_base_path: "/tmp",
      postgres: context.PostgresConfig(
        host: "localhost",
        port: 5432,
        db: "test",
        user: "test",
        pass: "test",
        pool_size: 1,
      ),
    ),
    regexes: context.Regexes(is_email: is_email),
    request_id: uuid.nil,
    started_at: 0,
    deadline_at_monotonic_ns: option.None,
    timestamp: timestamp.system_time(),
    client_info: context.ClientInfo(
      session_token: option.None,
      ip: option.None,
      user_agent: option.None,
      referrer: option.None,
    ),
  )
}

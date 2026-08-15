import gleam/dict
import gleam/option
import gleam/time/timestamp
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/job/domain/manager as job_manager_domain
import glot_backend/job/ports as job_ports
import glot_backend/job/ports/job_store
import glot_backend/snippet/ports/store as snippet_store
import glot_backend/spam_classifier/model/config as classifier_config
import glot_backend/spam_classifier/ports/client as classifier_client
import glot_backend/system/effect/database_ports
import glot_backend/system/effect/error
import glot_backend/system/effect/error/db_error
import glot_backend/system/effect/error/infra_error
import glot_backend/system/effect/service_ports
import glot_backend/system/effect/system_ports
import glot_backend/system/request/context
import glot_core/job/job_model
import glot_core/periodic_job/periodic_job_model
import glot_core/snippet/snippet_model.{type Snippet}
import glot_core/snippet/spam_classification
import support/integration/adapter/service_ports as test_service_ports
import support/integration/adapter/snippet as test_snippet_adapter
import support/integration/adapter/state
import support/integration/adapter/transaction as test_transaction_adapter
import support/integration/fixture
import support/integration/model as test_model
import support/integration/profile/job as runner
import support/integration/runner as integration_runner
import support/integration/store/common

pub fn classifier_result_and_job_completion_commit_together_test() {
  let successor_id = fixture.must_uuid("00000000-0000-0000-0000-000000000421")
  let running_job = classifier_job()
  let test_fixture =
    fixture.integration_fixture(
      next_uuids: [successor_id],
      jobs: [running_job],
      account_delete_job_id: option.None,
    )
  let initial_state = with_classifier_config(test_fixture.state, True)

  let #(run_result, db) =
    integration_runner.run_test_program_with(
      job_manager_domain.process_job(test_fixture.ctx, running_job),
      test_fixture.ctx,
      initial_state,
      classifier_services(
        _,
        test_fixture.snippet,
        spam_classification.Stored,
        False,
        False,
      ),
    )

  assert run_result == Ok(Nil)
  assert db.write_steps == ["store_spam_classification"]
  let assert Ok(completed_job) =
    dict.get(db.jobs, common.uuid_key(running_job.id))
  let assert Ok(successor_job) =
    dict.get(db.jobs, common.uuid_key(successor_id))
  assert completed_job.status == job_model.Done
  assert successor_job.status == job_model.Pending
}

pub fn classifier_result_rolls_back_when_job_completion_fails_test() {
  let successor_id = fixture.must_uuid("00000000-0000-0000-0000-000000000422")
  let running_job = classifier_job()
  let test_fixture =
    fixture.integration_fixture(
      next_uuids: [successor_id],
      jobs: [running_job],
      account_delete_job_id: option.None,
    )
  let initial_state = with_classifier_config(test_fixture.state, True)

  let #(run_result, db) =
    integration_runner.run_test_program_with(
      job_manager_domain.process_job(test_fixture.ctx, running_job),
      test_fixture.ctx,
      initial_state,
      classifier_services(
        _,
        test_fixture.snippet,
        spam_classification.Stored,
        True,
        False,
      ),
    )

  let assert Error(_) = run_result
  assert db.write_steps == []
  let assert Ok(stored_job) = dict.get(db.jobs, common.uuid_key(running_job.id))
  assert stored_job.status == job_model.Pending
  assert stored_job.last_error
    == option.Some(
      "transaction_error:InfraError(DatabaseError(CommandOperation, \"successor insert failed\"))",
    )
  assert dict.has_key(db.jobs, common.uuid_key(successor_id)) == False
}

pub fn stale_classifier_result_is_logged_and_processing_continues_test() {
  let successor_id = fixture.must_uuid("00000000-0000-0000-0000-000000000423")
  let running_job = classifier_job()
  let test_fixture =
    fixture.integration_fixture(
      next_uuids: [successor_id],
      jobs: [running_job],
      account_delete_job_id: option.None,
    )
  let initial_state = with_classifier_config(test_fixture.state, True)

  let #(run_result, db, effect_state) =
    integration_runner.run_test_program_with_effect_state(
      job_manager_domain.process_job(test_fixture.ctx, running_job),
      test_fixture.ctx,
      initial_state,
      classifier_services(
        _,
        test_fixture.snippet,
        spam_classification.Stale,
        False,
        False,
      ),
    )

  assert run_result == Ok(Nil)
  assert db.write_steps == []
  let assert Ok(completed_job) =
    dict.get(db.jobs, common.uuid_key(running_job.id))
  let assert Ok(successor_job) =
    dict.get(db.jobs, common.uuid_key(successor_id))
  assert completed_job.status == job_model.Done
  assert successor_job.status == job_model.Pending
  assert dict.has_key(effect_state.warning_fields, "spam_classification_stale")
}

pub fn disabled_periodic_job_skips_queued_execution_test() {
  let unused_successor_id =
    fixture.must_uuid("00000000-0000-0000-0000-000000000424")
  let running_job = classifier_job()
  let test_fixture =
    fixture.integration_fixture(
      next_uuids: [unused_successor_id],
      jobs: [running_job],
      account_delete_job_id: option.None,
    )
  let initial_state = with_classifier_config(test_fixture.state, False)

  let #(run_result, db) =
    integration_runner.run_test_program_with(
      job_manager_domain.process_job(test_fixture.ctx, running_job),
      test_fixture.ctx,
      initial_state,
      classifier_services(
        _,
        test_fixture.snippet,
        spam_classification.Stored,
        False,
        False,
      ),
    )

  assert run_result == Ok(Nil)
  assert db.write_steps == []
  let assert Ok(completed_job) =
    dict.get(db.jobs, common.uuid_key(running_job.id))
  assert completed_job.status == job_model.Done
  assert dict.has_key(db.jobs, common.uuid_key(unused_successor_id)) == False
}

pub fn disabling_periodic_job_during_run_stops_successor_chain_test() {
  let unused_successor_id =
    fixture.must_uuid("00000000-0000-0000-0000-000000000425")
  let running_job = classifier_job()
  let test_fixture =
    fixture.integration_fixture(
      next_uuids: [unused_successor_id],
      jobs: [running_job],
      account_delete_job_id: option.None,
    )
  let initial_state = with_classifier_config(test_fixture.state, True)

  let #(run_result, db) =
    integration_runner.run_test_program_with(
      job_manager_domain.process_job(test_fixture.ctx, running_job),
      test_fixture.ctx,
      initial_state,
      classifier_services(
        _,
        test_fixture.snippet,
        spam_classification.Stored,
        False,
        True,
      ),
    )

  assert run_result == Ok(Nil)
  assert db.write_steps == ["store_spam_classification"]
  let assert Ok(completed_job) =
    dict.get(db.jobs, common.uuid_key(running_job.id))
  assert completed_job.status == job_model.Done
  assert dict.has_key(db.jobs, common.uuid_key(unused_successor_id)) == False
}

pub fn classifier_retry_after_keeps_circuit_job_active_test() {
  let err =
    error.infra(
      infra_error.SpamClassifierError(infra_error.SpamClassifierRequestFailed(
        "classifier_busy:request_id=test",
        infra_error.RetryIndefinitelyAfter(47),
        infra_error.ServiceFailure,
      )),
    )

  assert error.failure_disposition(err)
    == infra_error.RetryIndefinitelyAfter(47)
}

pub fn classifier_auth_failure_uses_slow_circuit_retry_test() {
  let err =
    error.infra(
      infra_error.SpamClassifierError(infra_error.SpamClassifierRequestFailed(
        "status=401:request_id=test",
        infra_error.RetryIndefinitelyAfter(900),
        infra_error.ServiceFailure,
      )),
    )

  assert error.failure_disposition(err)
    == infra_error.RetryIndefinitelyAfter(900)
}

pub fn recover_next_expired_job_reschedules_running_job_test() {
  let scheduled_job =
    job_model.delete_account_job(
      fixture.must_uuid("00000000-0000-0000-0000-000000000411"),
      option.Some(fixture.test_request_id()),
      fixture.test_timestamp(),
      fixture.test_timestamp(),
      fixture.test_account_id(),
      fixture.test_email_address(),
      fixture.test_job_type_policy(job_model.DeleteAccountJob),
    )
  let expired_job =
    job_model.start(
      scheduled_job,
      timestamp.from_unix_seconds_and_nanoseconds(1_699_999_000, 0),
    )
  let ctx =
    context.Context(
      ..fixture.test_context(),
      timestamp: timestamp.from_unix_seconds_and_nanoseconds(1_700_000_000, 0),
    )
  let test_fixture =
    fixture.integration_fixture(
      next_uuids: [],
      jobs: [expired_job],
      account_delete_job_id: option.Some(expired_job.id),
    )

  let #(run_result, db) =
    runner.run_test_program(
      job_manager_domain.recover_next_expired_job(ctx, job_model.DefaultQueue),
      ctx,
      test_fixture.state,
    )

  let assert Ok(option.Some(recovered_job)) = run_result
  let assert Ok(stored_job) = dict.get(db.jobs, common.uuid_key(expired_job.id))

  assert recovered_job.status == job_model.Pending
  assert recovered_job.started_at == option.None
  assert recovered_job.lease_expires_at == option.None
  assert recovered_job.timed_out_at == option.Some(ctx.timestamp)
  assert recovered_job.last_error == option.Some("timeout_exceeded")
  assert stored_job == recovered_job
}

pub fn shutdown_interruption_requeues_running_job_test() {
  let scheduled_job =
    job_model.delete_account_job(
      fixture.must_uuid("00000000-0000-0000-0000-000000000412"),
      option.Some(fixture.test_request_id()),
      fixture.test_timestamp(),
      fixture.test_timestamp(),
      fixture.test_account_id(),
      fixture.test_email_address(),
      fixture.test_job_type_policy(job_model.DeleteAccountJob),
    )
  let running_job = job_model.start(scheduled_job, fixture.test_timestamp())
  let ctx = fixture.test_context()
  let test_fixture =
    fixture.integration_fixture(
      next_uuids: [],
      jobs: [running_job],
      account_delete_job_id: option.Some(running_job.id),
    )

  let #(run_result, db) =
    runner.run_test_program(
      job_manager_domain.interrupt_job_for_shutdown(ctx, running_job),
      ctx,
      test_fixture.state,
    )

  assert run_result == Ok(Nil)
  let assert Ok(stored_job) = dict.get(db.jobs, common.uuid_key(running_job.id))
  assert stored_job.status == job_model.Pending
  assert stored_job.run_at == fixture.test_system_time()
  assert stored_job.lease_expires_at == option.None
  assert stored_job.last_error == option.Some("interrupted_by_shutdown")
}

fn classifier_job() -> job_model.Job {
  let now = fixture.test_timestamp()
  let policy =
    job_model.JobTypePolicy(
      job_type: job_model.ClassifySnippetJob,
      queue: job_model.SpamClassifierQueue,
      max_attempts: 10,
      timeout_seconds: 3600,
      base_backoff_seconds: 5,
      max_backoff_seconds: 900,
      created_at: now,
      updated_at: now,
    )

  job_model.periodic_job_execution(
    fixture.must_uuid("00000000-0000-0000-0000-000000000420"),
    now,
    fixture.must_uuid("00000000-0000-0000-0000-000000000419"),
    job_model.ClassifySnippetJob,
    option.None,
    policy,
  )
  |> job_model.start(now)
}

fn with_classifier_config(
  db: test_model.TestState,
  enabled: Bool,
) -> test_model.TestState {
  let config =
    dynamic_config.DynamicConfig(
      ..db.dynamic_config,
      spam_classifier: option.Some(classifier_config.Config(
        base_url: "http://classifier:8081",
        auth_token: "secret",
      )),
    )
  let periodic_job =
    periodic_job_model.PeriodicJob(
      id: fixture.must_uuid("00000000-0000-0000-0000-000000000419"),
      job_type: job_model.ClassifySnippetJob,
      payload: option.None,
      interval_seconds: 60,
      enabled: enabled,
      next_run_at: fixture.test_timestamp(),
      last_enqueued_at: option.None,
      last_enqueue_error: option.None,
      created_at: fixture.test_timestamp(),
      updated_at: fixture.test_timestamp(),
    )
  test_model.TestState(
    ..db,
    dynamic_config: config,
    periodic_jobs: dict.insert(
      db.periodic_jobs,
      common.uuid_key(periodic_job.id),
      periodic_job,
    ),
  )
}

fn classifier_services(
  test_state: state.State,
  snippet: Snippet,
  store_result: spam_classification.StoreResult,
  fail_successor_creation: Bool,
  disable_periodic_during_classification: Bool,
) -> service_ports.ServicePorts {
  let services =
    test_service_ports.defaults(test_state)
    |> test_service_ports.with_app_config(test_state)
    |> test_service_ports.with_job(test_state)
  let candidate = spam_classification.Candidate(snippet, snippet.updated_at)
  let snippets =
    snippet_store.Store(
      ..test_snippet_adapter.defaults(),
      get_newest_unclassified_snippet: fn() { Ok(option.Some(candidate)) },
      increment_spam_classification_attempts: fn(_, _) {
        Ok(spam_classification.Stored)
      },
      store_spam_classification: fn(_, _, _) {
        case store_result {
          spam_classification.Stored ->
            state.update(test_state, fn(db) {
              test_model.TestState(..db, write_steps: [
                "store_spam_classification",
                ..db.write_steps
              ])
            })
          spam_classification.Stale -> Nil
        }
        Ok(store_result)
      },
    )
  let current_job_ports = database_ports.job(services.database)
  let current_job_store = current_job_ports.jobs
  let jobs =
    job_store.JobStore(..current_job_store, create_job: fn(job) {
      case fail_successor_creation {
        True -> Error(db_error.DbCommandError("successor insert failed"))
        False -> current_job_store.create_job(job)
      }
    })
  let database =
    services.database
    |> database_ports.with_snippet(snippets)
    |> database_ports.with_job(job_ports.Ports(..current_job_ports, jobs: jobs))
  let system =
    system_ports.SystemPorts(
      ..services.system,
      spam_classifier: classifier_client.Client(classify: fn(_, _, _) {
        case disable_periodic_during_classification {
          True ->
            state.update(test_state, fn(db) {
              let periodic_job_id =
                fixture.must_uuid("00000000-0000-0000-0000-000000000419")
              let assert Ok(periodic_job) =
                dict.get(db.periodic_jobs, common.uuid_key(periodic_job_id))
              test_model.TestState(
                ..db,
                periodic_jobs: dict.insert(
                  db.periodic_jobs,
                  common.uuid_key(periodic_job_id),
                  periodic_job_model.PeriodicJob(..periodic_job, enabled: False),
                ),
              )
            })
          False -> Nil
        }
        Ok(#(
          spam_classification.ServiceResponse(
            decision: spam_classification.Allow,
            confidence: 100,
            reason_code: spam_classification.None,
          ),
          "classifier-request-id",
        ))
      }),
    )

  service_ports.ServicePorts(
    ..services,
    database: database,
    system: system,
    transaction: test_transaction_adapter.new(test_state, database),
  )
}

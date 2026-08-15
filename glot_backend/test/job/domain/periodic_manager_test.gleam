import gleam/dict
import gleam/option
import gleam/time/timestamp
import glot_backend/job/domain/periodic_manager as periodic_job_manager_domain
import glot_backend/system/request/context
import glot_core/job/job_model
import glot_core/periodic_job/periodic_job_model
import support/integration/fixture
import support/integration/model
import support/integration/profile/job as runner
import support/integration/store/common
import youid/uuid

pub fn enqueue_next_due_periodic_job_creates_job_and_advances_schedule_test() {
  let periodic_job_id =
    fixture.must_uuid("00000000-0000-0000-0000-000000000801")
  let enqueued_job_id =
    fixture.must_uuid("00000000-0000-0000-0000-000000000802")
  let periodic_job =
    periodic_job_model.PeriodicJob(
      id: periodic_job_id,
      job_type: job_model.CleanApiLogJob,
      payload: option.None,
      interval_seconds: 86_400,
      enabled: True,
      next_run_at: fixture.test_timestamp(),
      last_enqueued_at: option.None,
      last_enqueue_error: option.None,
      created_at: fixture.test_timestamp(),
      updated_at: fixture.test_timestamp(),
    )
  let ctx =
    context.Context(
      ..fixture.test_context(),
      timestamp: fixture.test_timestamp(),
    )
  let clean_api_log_policy =
    job_model.JobTypePolicy(
      ..fixture.test_job_type_policy(job_model.CleanApiLogJob),
      max_attempts: 2,
      timeout_seconds: 1800,
    )
  let db =
    model.TestState(
      ..fixture.empty_test_state(),
      job_type_policies: dict.insert(
        fixture.empty_test_state().job_type_policies,
        job_model.job_type_to_string(job_model.CleanApiLogJob),
        clean_api_log_policy,
      ),
      periodic_jobs: dict.from_list([
        #(common.uuid_key(periodic_job_id), periodic_job),
      ]),
      next_uuids: [enqueued_job_id],
    )

  let #(run_result, updated_db) =
    runner.run_test_program(
      periodic_job_manager_domain.enqueue_next_due_periodic_job(ctx),
      ctx,
      db,
    )

  assert run_result == Ok(True)
  let assert Ok(enqueued_job) =
    dict.get(updated_db.jobs, common.uuid_key(enqueued_job_id))
  let assert Ok(updated_periodic_job) =
    dict.get(updated_db.periodic_jobs, common.uuid_key(periodic_job_id))

  assert enqueued_job.periodic_job_id == option.Some(periodic_job_id)
  assert enqueued_job.job_type == job_model.CleanApiLogJob
  assert enqueued_job.queue == clean_api_log_policy.queue
  assert enqueued_job.dedupe_key
    == option.Some("periodic:" <> uuid.to_string(periodic_job_id))
  assert enqueued_job.status == job_model.Pending
  assert enqueued_job.max_attempts == 2
  assert enqueued_job.timeout_seconds == 1800
  assert updated_periodic_job.last_enqueued_at
    == option.Some(fixture.test_timestamp())
  assert updated_periodic_job.last_enqueue_error == option.None
  assert updated_periodic_job.next_run_at
    == timestamp.from_unix_seconds_and_nanoseconds(1_700_086_400, 0)
}

pub fn enqueue_next_due_periodic_job_returns_false_when_no_jobs_are_due_test() {
  let periodic_job =
    periodic_job_model.PeriodicJob(
      id: fixture.must_uuid("00000000-0000-0000-0000-000000000901"),
      job_type: job_model.CleanApiLogJob,
      payload: option.None,
      interval_seconds: 86_400,
      enabled: True,
      next_run_at: timestamp.from_unix_seconds_and_nanoseconds(1_700_000_060, 0),
      last_enqueued_at: option.None,
      last_enqueue_error: option.None,
      created_at: fixture.test_timestamp(),
      updated_at: fixture.test_timestamp(),
    )
  let ctx =
    context.Context(
      ..fixture.test_context(),
      timestamp: fixture.test_timestamp(),
    )
  let db =
    model.TestState(
      ..fixture.empty_test_state(),
      periodic_jobs: dict.from_list([
        #(common.uuid_key(periodic_job.id), periodic_job),
      ]),
    )

  let #(run_result, updated_db) =
    runner.run_test_program(
      periodic_job_manager_domain.enqueue_next_due_periodic_job(ctx),
      ctx,
      db,
    )

  assert run_result == Ok(False)
  assert dict.to_list(updated_db.jobs) == []
  assert dict.get(updated_db.periodic_jobs, common.uuid_key(periodic_job.id))
    == Ok(periodic_job)
}

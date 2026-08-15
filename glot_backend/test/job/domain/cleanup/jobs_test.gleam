import gleam/dict
import gleam/option
import gleam/time/timestamp
import glot_backend/job/domain/cleanup/jobs as clean_jobs_domain
import glot_backend/system/request/context
import glot_core/job/job_model
import support/integration/fixture
import support/integration/model
import support/integration/profile/job as runner
import support/integration/store/common

pub fn clean_jobs_deletes_only_done_jobs_before_cutoff_test() {
  let old_done_job =
    job_model.Job(
      id: fixture.must_uuid("00000000-0000-0000-0000-000000000a01"),
      request_id: option.None,
      periodic_job_id: option.None,
      job_type: job_model.CleanApiLogJob,
      queue: job_model.DefaultQueue,
      dedupe_key: option.None,
      payload: option.None,
      status: job_model.Done,
      attempts: 1,
      max_attempts: 5,
      timeout_seconds: 120,
      base_backoff_seconds: 5,
      max_backoff_seconds: 300,
      run_at: timestamp.from_unix_seconds_and_nanoseconds(1_650_000_000, 0),
      started_at: option.Some(timestamp.from_unix_seconds_and_nanoseconds(
        1_650_000_010,
        0,
      )),
      lease_expires_at: option.None,
      completed_at: option.Some(timestamp.from_unix_seconds_and_nanoseconds(
        1_697_300_000,
        0,
      )),
      timed_out_at: option.None,
      last_error: option.None,
      created_at: timestamp.from_unix_seconds_and_nanoseconds(1_650_000_000, 0),
      updated_at: timestamp.from_unix_seconds_and_nanoseconds(1_697_300_000, 0),
    )
  let old_failed_job =
    job_model.Job(
      ..old_done_job,
      id: fixture.must_uuid("00000000-0000-0000-0000-000000000a02"),
      status: job_model.Failed,
    )
  let recent_done_job =
    job_model.Job(
      ..old_done_job,
      id: fixture.must_uuid("00000000-0000-0000-0000-000000000a03"),
      completed_at: option.Some(timestamp.from_unix_seconds_and_nanoseconds(
        1_699_900_000,
        0,
      )),
      updated_at: timestamp.from_unix_seconds_and_nanoseconds(1_699_900_000, 0),
    )
  let ctx =
    context.Context(
      ..fixture.test_context(),
      timestamp: timestamp.from_unix_seconds_and_nanoseconds(1_700_000_000, 0),
    )
  let db =
    model.TestState(
      ..fixture.empty_test_state(),
      jobs: dict.from_list([
        #(common.uuid_key(old_done_job.id), old_done_job),
        #(common.uuid_key(old_failed_job.id), old_failed_job),
        #(common.uuid_key(recent_done_job.id), recent_done_job),
      ]),
    )

  let #(run_result, updated_db) =
    runner.run_test_program(clean_jobs_domain.clean_jobs(ctx), ctx, db)

  assert run_result == Ok(Nil)
  assert dict.get(updated_db.jobs, common.uuid_key(old_done_job.id))
    == Error(Nil)
  assert dict.get(updated_db.jobs, common.uuid_key(old_failed_job.id))
    == Ok(old_failed_job)
  assert dict.get(updated_db.jobs, common.uuid_key(recent_done_job.id))
    == Ok(recent_done_job)
}

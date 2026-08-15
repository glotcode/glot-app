import gleam/option
import glot_backend/job/adapter/postgres/job/write
import glot_backend/system/effect/error/db_error
import glot_core/job/job_model
import support/integration/fixture

pub fn guarded_job_update_requires_one_affected_row_test() {
  let job = test_job()

  assert write.require_updated_job(job, 1) == Ok(Nil)
  assert write.require_updated_job(job, 0)
    == Error(db_error.DbCommandError(
      "guarded job update affected 0 rows for job "
      <> "00000000-0000-0000-0000-000000000411 with status pending",
    ))
  assert write.require_updated_job(job, 2)
    == Error(db_error.DbCommandError(
      "guarded job update affected 2 rows for job "
      <> "00000000-0000-0000-0000-000000000411 with status pending",
    ))
}

fn test_job() -> job_model.Job {
  job_model.delete_account_job(
    fixture.must_uuid("00000000-0000-0000-0000-000000000411"),
    option.Some(fixture.test_request_id()),
    fixture.test_timestamp(),
    fixture.test_timestamp(),
    fixture.test_account_id(),
    fixture.test_email_address(),
    fixture.test_job_type_policy(job_model.DeleteAccountJob),
  )
}

import gleam/option
import gleam/time/timestamp
import glot_backend/job/effect/algebra as job_bundle
import glot_backend/job/effect/job/algebra as job_algebra
import glot_backend/job/effect/job/effect as job_effect
import glot_backend/run_code/effect/effect as get_language_version_effect
import glot_backend/system/effect/error
import glot_backend/system/effect/error/db_error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types
import glot_backend/system/effect/transaction/transaction_effect
import glot_backend/system/effect/transaction/transaction_program
import glot_core/job/job_model
import glot_core/language
import glot_core/run
import glot_core/validation_error
import youid/uuid

type TestState {
  TestState(created_job_ids: List(String), updated_job_ids: List(String))
}

pub fn program_attempt_recovers_from_rolled_back_transaction_test() {
  let rolled_back_job =
    test_job(must_uuid("00000000-0000-0000-0000-000000000101"))
  let committed_job =
    test_job(must_uuid("00000000-0000-0000-0000-000000000102"))

  let effect =
    transaction_effect.run({
      use _ <- transaction_program.and_then(job_effect.create_job_tx(
        rolled_back_job,
      ))
      transaction_program.fail(error.validation(validation_error.InvalidLimit))
    })
    |> program.attempt(fn(_) { job_effect.create_job(committed_job) })

  let #(result, state) =
    run_program(effect, TestState(created_job_ids: [], updated_job_ids: []))

  assert result == Ok(Nil)
  assert state.created_job_ids == [uuid.to_string(committed_job.id)]
  assert state.updated_job_ids == []
}

pub fn process_job_shaped_recovery_after_rollback_test() {
  let rolled_back_job =
    test_job(must_uuid("00000000-0000-0000-0000-000000000201"))
  let rescheduled_job =
    test_job(must_uuid("00000000-0000-0000-0000-000000000202"))

  let effect =
    transaction_effect.run({
      use _ <- transaction_program.and_then(job_effect.create_job_tx(
        rolled_back_job,
      ))
      transaction_program.fail(error.validation(validation_error.InvalidLimit))
    })
    |> program.attempt(fn(_) { job_effect.update_job(rescheduled_job) })

  let #(result, state) =
    run_program(effect, TestState(created_job_ids: [], updated_job_ids: []))

  assert result == Ok(Nil)
  assert state.created_job_ids == []
  assert state.updated_job_ids == [uuid.to_string(rescheduled_job.id)]
}

pub fn program_attempt_retries_recovery_only_once_when_recovery_refails_test() {
  let rescheduled_job =
    test_job(must_uuid("00000000-0000-0000-0000-000000000203"))

  let effect =
    transaction_effect.run({
      use _ <- transaction_program.and_then(
        job_effect.create_job_tx(
          test_job(must_uuid("00000000-0000-0000-0000-000000000204")),
        ),
      )
      transaction_program.fail(error.validation(validation_error.InvalidLimit))
    })
    |> program.attempt(fn(err) {
      use _ <- program.and_then(job_effect.update_job(rescheduled_job))
      program.fail(err)
    })

  let #(result, state) =
    run_program(effect, TestState(created_job_ids: [], updated_job_ids: []))

  assert result
    == Error(
      error.database_transaction_error(db_error.DbTransactionError(
        "validation_error:limit must be greater than 0",
      )),
    )
  assert state.created_job_ids == []
  assert state.updated_job_ids == [uuid.to_string(rescheduled_job.id)]
}

pub fn program_attempt_recovers_from_non_transaction_interpreter_failure_test() {
  let fallback = successful_run("fallback")
  let effect =
    get_language_version_effect.get_language_version(
      option.None,
      language.Python,
    )
    |> program.attempt(fn(_) { program.succeed(fallback) })

  let #(result, state) =
    run_program(effect, TestState(created_job_ids: [], updated_job_ids: []))

  assert result == Ok(fallback)
  assert state.created_job_ids == []
  assert state.updated_job_ids == []
}

pub fn job_start_sets_lease_expiry_test() {
  let now = timestamp.from_unix_seconds_and_nanoseconds(1_700_000_000, 0)
  let job = test_job(must_uuid("00000000-0000-0000-0000-000000000301"))

  let started = job_model.start(job, now)

  assert started.status == job_model.Running
  assert started.attempts == 1
  assert started.started_at == option.Some(now)
  assert started.lease_expires_at
    == option.Some(timestamp.from_unix_seconds_and_nanoseconds(1_700_000_120, 0))
}

pub fn job_timed_out_clears_lease_and_sets_timestamp_test() {
  let started_at = timestamp.from_unix_seconds_and_nanoseconds(1_700_000_000, 0)
  let retry_at = timestamp.from_unix_seconds_and_nanoseconds(1_700_000_200, 0)
  let started_job =
    test_job(must_uuid("00000000-0000-0000-0000-000000000302"))
    |> job_model.start(started_at)

  let timed_out = job_model.timed_out(started_job, retry_at, retry_at)

  assert timed_out.status == job_model.Pending
  assert timed_out.started_at == option.None
  assert timed_out.lease_expires_at == option.None
  assert timed_out.timed_out_at == option.Some(retry_at)
  assert timed_out.last_error == option.Some("timeout_exceeded")
}

fn run_program(
  effect: program_types.Program(a),
  state: TestState,
) -> #(Result(a, error.Error), TestState) {
  case effect {
    program_types.Pure(value) -> #(Ok(value), state)
    program_types.Fail(err) -> #(Error(err), state)
    program_types.Attempt(program:, on_error:) ->
      case run_program(program, state) {
        #(Ok(value), next_state) -> #(Ok(value), next_state)
        #(Error(err), next_state) -> run_program(on_error(err), next_state)
      }
    program_types.Impure(effect) ->
      case effect {
        program_types.DbEffect(db_effect) -> run_db_effect(db_effect, state)
        program_types.TransactionEffect(transaction_effect) ->
          case transaction_effect {
            program_types.Run(program: tx_program) -> {
              let #(tx_result, tx_state) = run_tx_program(tx_program, state)
              case tx_result {
                Ok(next_program) -> run_program(next_program, tx_state)
                Error(err) -> #(
                  Error(
                    error.database_transaction_error(
                      db_error.DbTransactionError(error.to_string(err)),
                    ),
                  ),
                  state,
                )
              }
            }
          }
        _ -> unsupported_program_effect(state)
      }
  }
}

fn run_tx_program(
  effect: program_types.TransactionProgram(a),
  state: TestState,
) -> #(Result(a, error.Error), TestState) {
  case effect {
    program_types.TxPure(value) -> #(Ok(value), state)
    program_types.TxFail(err) -> #(Error(err), state)
    program_types.TxImpure(effect) -> run_tx_db_effect(effect, state)
  }
}

fn run_db_effect(
  effect: program_types.DbEffect(program_types.Program(a)),
  state: TestState,
) -> #(Result(a, error.Error), TestState) {
  case effect {
    program_types.JobEffect(job_bundle.Job(job_effect)) ->
      run_job_effect(job_effect, state)
    _ -> unsupported_db_effect(state)
  }
}

fn run_tx_db_effect(
  effect: program_types.DbEffect(program_types.TransactionProgram(a)),
  state: TestState,
) -> #(Result(a, error.Error), TestState) {
  case effect {
    program_types.JobEffect(job_bundle.Job(job_effect)) ->
      run_job_tx_effect(job_effect, state)
    _ -> unsupported_db_effect(state)
  }
}

fn run_job_effect(
  effect: job_algebra.JobEffect(program_types.Program(a)),
  state: TestState,
) -> #(Result(a, error.Error), TestState) {
  case effect {
    job_algebra.CreateJob(job, next) ->
      run_program(next(Ok(Nil)), insert_job(state, job))
    job_algebra.UpdateJob(job, next) ->
      run_program(next(Ok(Nil)), update_job(state, job))
    _ -> unsupported_job_effect(state)
  }
}

fn run_job_tx_effect(
  effect: job_algebra.JobEffect(program_types.TransactionProgram(a)),
  state: TestState,
) -> #(Result(a, error.Error), TestState) {
  case effect {
    job_algebra.CreateJob(job, next) ->
      run_tx_program(next(Ok(Nil)), insert_job(state, job))
    job_algebra.UpdateJob(job, next) ->
      run_tx_program(next(Ok(Nil)), update_job(state, job))
    _ -> unsupported_job_effect(state)
  }
}

fn insert_job(state: TestState, job: job_model.Job) -> TestState {
  TestState(
    created_job_ids: [uuid.to_string(job.id), ..state.created_job_ids],
    updated_job_ids: state.updated_job_ids,
  )
}

fn update_job(state: TestState, job: job_model.Job) -> TestState {
  TestState(created_job_ids: state.created_job_ids, updated_job_ids: [
    uuid.to_string(job.id),
    ..state.updated_job_ids
  ])
}

fn unsupported_program_effect(
  state: TestState,
) -> #(Result(a, error.Error), TestState) {
  #(Error(error.validation(validation_error.InvalidLimit)), state)
}

fn unsupported_db_effect(
  state: TestState,
) -> #(Result(a, error.Error), TestState) {
  #(Error(error.validation(validation_error.InvalidLimit)), state)
}

fn unsupported_job_effect(
  state: TestState,
) -> #(Result(a, error.Error), TestState) {
  #(Error(error.validation(validation_error.InvalidLimit)), state)
}

fn test_job(id: uuid.Uuid) -> job_model.Job {
  let now = timestamp.from_unix_seconds_and_nanoseconds(1_700_000_000, 0)

  job_model.Job(
    id: id,
    request_id: option.None,
    periodic_job_id: option.None,
    job_type: job_model.CleanJobsJob,
    queue: job_model.DefaultQueue,
    dedupe_key: option.None,
    payload: option.None,
    status: job_model.Pending,
    attempts: 0,
    max_attempts: 5,
    timeout_seconds: 120,
    base_backoff_seconds: 5,
    max_backoff_seconds: 300,
    run_at: now,
    started_at: option.None,
    lease_expires_at: option.None,
    completed_at: option.None,
    timed_out_at: option.None,
    last_error: option.None,
    created_at: now,
    updated_at: now,
  )
}

fn must_uuid(value: String) -> uuid.Uuid {
  let assert Ok(id) = uuid.from_string(value)
  id
}

fn successful_run(stdout: String) -> run.RunResult {
  Ok(run.SuccessfulRun(duration: 1, stdout: stdout, stderr: "", error: ""))
}

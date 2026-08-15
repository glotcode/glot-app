import gleam/erlang/process
import gleam/option
import gleam/regexp
import gleam/time/timestamp
import glot_backend/job/ports/tracker.{type Tracker}
import glot_backend/job/worker/executor/worker as job_worker
import glot_backend/system/effect/program_state
import glot_backend/system/lifecycle/server_mode/adapter/worker as server_mode_adapter
import glot_backend/system/lifecycle/server_mode/model as server_mode
import glot_backend/system/lifecycle/server_mode/worker as server_mode_worker
import glot_backend/system/request/context
import glot_core/job/job_model
import support/process as test_process
import youid/uuid

type ControlMessage {
  RecordClaim
  RecordJobStarted
  RecordJobFinished
  RecordTimeoutJob
  RecordInterruptJob
  RecordInsertJobLog
  RecordKillAttempt
  RecordTimeoutScheduled
  RecordTickScheduled
  TakeClaimJob(reply: process.Subject(option.Option(job_model.Job)))
  GetSnapshot(reply: process.Subject(ControlSnapshot))
}

type ControlSnapshot {
  ControlSnapshot(
    claim_count: Int,
    started_count: Int,
    finished_count: Int,
    timeout_job_count: Int,
    interrupt_job_count: Int,
    insert_log_count: Int,
    kill_count: Int,
    timeout_scheduled_count: Int,
    tick_scheduled_count: Int,
  )
}

type ControlState {
  ControlState(
    claim_count: Int,
    started_count: Int,
    finished_count: Int,
    timeout_job_count: Int,
    interrupt_job_count: Int,
    insert_log_count: Int,
    kill_count: Int,
    timeout_scheduled_count: Int,
    tick_scheduled_count: Int,
    claim_jobs: List(job_model.Job),
  )
}

pub fn maintenance_to_running_resumes_claiming_test() {
  let control_name = process.new_name("job_worker_control")
  let worker_name = process.new_name("job_worker_test")
  let control_subject = start_control(control_name, [])
  let server_mode_name = process.new_name("job_worker_server_mode")
  let assert Ok(_) =
    server_mode_worker.start_in(server_mode_name, server_mode.Maintenance)
  let server_mode_subject = process.named_subject(server_mode_name)

  let _ =
    job_worker.start_named_with_deps(
      worker_name,
      test_config(),
      test_regexes(),
      server_mode_adapter.new(server_mode_subject),
      test_tracker(control_subject),
      test_deps(control_subject, False),
    )

  let maintenance_state =
    wait_for_snapshot(control_subject, fn(state) {
      state.tick_scheduled_count >= 1
    })
  assert maintenance_state.claim_count == 0

  server_mode_worker.enter_running(server_mode_subject)

  assert wait_for_snapshot(control_subject, fn(state) { state.claim_count >= 1 }).claim_count
    >= 1
}

pub fn claimed_job_starts_attempt_and_schedules_timeout_test() {
  let control_name = process.new_name("job_worker_claim_control")
  let worker_name = process.new_name("job_worker_claim_test")
  let control_subject = start_control(control_name, [test_job()])
  let server_mode_name = process.new_name("job_worker_claim_server_mode")
  let assert Ok(_) =
    server_mode_worker.start_in(server_mode_name, server_mode.Running)
  let server_mode_subject = process.named_subject(server_mode_name)

  let _ =
    job_worker.start_named_with_deps(
      worker_name,
      test_config(),
      test_regexes(),
      server_mode_adapter.new(server_mode_subject),
      test_tracker(control_subject),
      test_deps(control_subject, False),
    )

  let state =
    wait_for_snapshot(control_subject, fn(state) {
      state.claim_count >= 1
      && state.started_count >= 1
      && state.timeout_scheduled_count >= 1
    })

  assert state.claim_count == 1
  assert state.started_count == 1
  assert state.timeout_scheduled_count == 1
  assert state.finished_count == 0
  assert state.insert_log_count == 0
}

pub fn timed_out_attempt_finishes_and_retries_tick_test() {
  let control_name = process.new_name("job_worker_timeout_control")
  let worker_name = process.new_name("job_worker_timeout_test")
  let control_subject = start_control(control_name, [test_job()])
  let server_mode_name = process.new_name("job_worker_timeout_server_mode")
  let assert Ok(_) =
    server_mode_worker.start_in(server_mode_name, server_mode.Running)
  let server_mode_subject = process.named_subject(server_mode_name)

  let _ =
    job_worker.start_named_with_deps(
      worker_name,
      test_config(),
      test_regexes(),
      server_mode_adapter.new(server_mode_subject),
      test_tracker(control_subject),
      test_deps(control_subject, True),
    )

  let state =
    wait_for_snapshot(control_subject, fn(state) {
      state.timeout_job_count >= 1
      && state.finished_count >= 1
      && state.insert_log_count >= 1
      && state.kill_count >= 1
    })

  assert state.started_count >= 1
  assert state.timeout_job_count == 1
  assert state.finished_count == 1
  assert state.insert_log_count == 1
  assert state.kill_count == 1
  assert state.timeout_scheduled_count >= 1
}

pub fn shutdown_interrupts_and_finishes_active_attempt_test() {
  let control_name = process.new_name("job_worker_shutdown_control")
  let worker_name = process.new_name("job_worker_shutdown_test")
  let control_subject = start_control(control_name, [test_job()])
  let server_mode_name = process.new_name("job_worker_shutdown_server_mode")
  let assert Ok(_) =
    server_mode_worker.start_in(server_mode_name, server_mode.Running)
  let server_mode_subject = process.named_subject(server_mode_name)

  let _ =
    job_worker.start_named_with_deps(
      worker_name,
      test_config(),
      test_regexes(),
      server_mode_adapter.new(server_mode_subject),
      test_tracker(control_subject),
      test_deps(control_subject, False),
    )

  let _ =
    wait_for_snapshot(control_subject, fn(state) { state.started_count == 1 })
  let assert Ok(Nil) =
    job_worker.interrupt_for_shutdown(process.named_subject(worker_name))

  let state =
    wait_for_snapshot(control_subject, fn(state) {
      state.interrupt_job_count == 1
      && state.finished_count == 1
      && state.insert_log_count == 1
      && state.kill_count >= 1
    })

  assert state.timeout_job_count == 0
  assert state.interrupt_job_count == 1
  assert state.finished_count == 1
}

fn test_deps(
  control_subject: process.Subject(ControlMessage),
  auto_fire_timeout: Bool,
) -> job_worker.Deps {
  job_worker.Deps(
    enqueue_next_due_periodic_job: fn(_) { Ok(False) },
    recover_next_expired_job: fn(_) { Ok(option.None) },
    claim_next_job: fn(_) {
      process.send(control_subject, RecordClaim)
      Ok(test_process.call(control_subject, TakeClaimJob))
    },
    process_job: fn(_, _) {
      process.receive_forever(process.new_subject())
      #(Ok(Nil), program_state.new_state())
    },
    timeout_job: fn(_, _) {
      process.send(control_subject, RecordTimeoutJob)
      Ok(Nil)
    },
    interrupt_job_for_shutdown: fn(_, _) {
      process.send(control_subject, RecordInterruptJob)
      Ok(Nil)
    },
    insert_job_log: fn(_) {
      process.send(control_subject, RecordInsertJobLog)
      Ok(Nil)
    },
    spawn_attempt: process.spawn_unlinked,
    send_after: fn(subject, _delay, message) {
      case message {
        job_worker.AttemptTimedOut(_) -> {
          process.send(control_subject, RecordTimeoutScheduled)
          case auto_fire_timeout {
            True -> process.send_after(subject, 1, message)
            False -> process.send_after(subject, 10_000, message)
          }
        }
        _ -> {
          process.send(control_subject, RecordTickScheduled)
          process.send_after(subject, 1, message)
        }
      }
    },
    cancel_timer: fn(timer) {
      let _ = process.cancel_timer(timer)
      Nil
    },
    kill: fn(pid) {
      process.send(control_subject, RecordKillAttempt)
      process.kill(pid)
    },
    now_timestamp: fn() { timestamp.from_unix_seconds(1) },
    now_monotonic_ns: fn() { 1 },
    log_error: fn(_) { Nil },
  )
}

fn test_tracker(control_subject: process.Subject(ControlMessage)) -> Tracker {
  tracker.Tracker(
    started: fn() { process.send(control_subject, RecordJobStarted) },
    finished: fn() { process.send(control_subject, RecordJobFinished) },
    count: fn() { 0 },
  )
}

fn start_control(
  name: process.Name(ControlMessage),
  claim_jobs: List(job_model.Job),
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
          claim_count: 0,
          started_count: 0,
          finished_count: 0,
          timeout_job_count: 0,
          interrupt_job_count: 0,
          insert_log_count: 0,
          kill_count: 0,
          timeout_scheduled_count: 0,
          tick_scheduled_count: 0,
          claim_jobs: claim_jobs,
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
    RecordClaim ->
      control_loop(
        subject,
        ControlState(..state, claim_count: state.claim_count + 1),
      )
    RecordJobStarted ->
      control_loop(
        subject,
        ControlState(..state, started_count: state.started_count + 1),
      )
    RecordJobFinished ->
      control_loop(
        subject,
        ControlState(..state, finished_count: state.finished_count + 1),
      )
    RecordTimeoutJob ->
      control_loop(
        subject,
        ControlState(..state, timeout_job_count: state.timeout_job_count + 1),
      )
    RecordInterruptJob ->
      control_loop(
        subject,
        ControlState(
          ..state,
          interrupt_job_count: state.interrupt_job_count + 1,
        ),
      )
    RecordInsertJobLog ->
      control_loop(
        subject,
        ControlState(..state, insert_log_count: state.insert_log_count + 1),
      )
    RecordKillAttempt ->
      control_loop(
        subject,
        ControlState(..state, kill_count: state.kill_count + 1),
      )
    RecordTimeoutScheduled ->
      control_loop(
        subject,
        ControlState(
          ..state,
          timeout_scheduled_count: state.timeout_scheduled_count + 1,
        ),
      )
    RecordTickScheduled ->
      control_loop(
        subject,
        ControlState(
          ..state,
          tick_scheduled_count: state.tick_scheduled_count + 1,
        ),
      )
    TakeClaimJob(reply) -> {
      let #(maybe_job, claim_jobs) = case state.claim_jobs {
        [job, ..rest] -> #(option.Some(job), rest)
        [] -> #(option.None, [])
      }
      process.send(reply, maybe_job)
      control_loop(subject, ControlState(..state, claim_jobs: claim_jobs))
    }
    GetSnapshot(reply) -> {
      process.send(
        reply,
        ControlSnapshot(
          claim_count: state.claim_count,
          started_count: state.started_count,
          finished_count: state.finished_count,
          timeout_job_count: state.timeout_job_count,
          interrupt_job_count: state.interrupt_job_count,
          insert_log_count: state.insert_log_count,
          kill_count: state.kill_count,
          timeout_scheduled_count: state.timeout_scheduled_count,
          tick_scheduled_count: state.tick_scheduled_count,
        ),
      )
      control_loop(subject, state)
    }
  }
}

fn wait_for_snapshot(
  control_subject: process.Subject(ControlMessage),
  predicate: fn(ControlSnapshot) -> Bool,
) -> ControlSnapshot {
  test_process.eventually(fn() { snapshot(control_subject) }, predicate)
}

fn snapshot(
  control_subject: process.Subject(ControlMessage),
) -> ControlSnapshot {
  test_process.call(control_subject, GetSnapshot)
}

fn test_config() -> context.Config {
  context.Config(
    app_env: context.Dev,
    encryption_key: "test-key",
    listening_address: "localhost",
    listening_port: 3000,
    static_base_path: "/tmp",
    postgres: context.PostgresConfig(
      host: "localhost",
      port: 5432,
      db: "glot",
      user: "glot",
      pass: "glot",
      pool_size: 1,
    ),
  )
}

fn test_regexes() -> context.Regexes {
  let assert Ok(email_regex) = regexp.from_string(".+")
  context.Regexes(is_email: email_regex)
}

fn test_job() -> job_model.Job {
  let now = timestamp.from_unix_seconds(1)
  let assert Ok(request_id) =
    uuid.from_string("0196e8d4-2cb3-7d0a-a0b5-8f5f31337d01")
  let assert Ok(job_id) =
    uuid.from_string("0196e8d4-2cb3-7d0a-a0b5-8f5f31337d02")

  job_model.Job(
    id: job_id,
    request_id: option.Some(request_id),
    periodic_job_id: option.None,
    job_type: job_model.CleanJobsJob,
    queue: job_model.DefaultQueue,
    dedupe_key: option.None,
    payload: option.None,
    status: job_model.Pending,
    attempts: 1,
    max_attempts: 3,
    timeout_seconds: 1,
    base_backoff_seconds: 5,
    max_backoff_seconds: 60,
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

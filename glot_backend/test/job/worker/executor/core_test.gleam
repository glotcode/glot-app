import gleam/dict
import gleam/erlang/process
import gleam/list
import gleam/option
import gleam/regexp
import gleam/time/timestamp
import glot_backend/job/model/log_entry
import glot_backend/job/worker/executor/core as job_worker_core
import glot_backend/system/lifecycle/server_mode/model as server_mode
import glot_backend/system/request/context
import glot_core/job/job_model
import youid/uuid

pub fn maintenance_tick_schedules_idle_poll_test() {
  let #(state, commands) =
    job_worker_core.on_tick(
      job_worker_core.new(),
      server_mode.Maintenance,
      option.None,
    )

  assert state == job_worker_core.new()
  assert commands
    == [job_worker_core.ScheduleTick(job_worker_core.idle_poll_ms)]
}

pub fn completed_attempt_clears_active_attempt_and_finishes_test() {
  let subject = process.new_subject()
  let timer = process.send_after(subject, 1000, Nil)
  let pid = process.self()
  let state = active_state(pid, timer)

  let #(next_state, commands) =
    job_worker_core.on_attempt_completed(state, pid, test_log_entry())

  assert job_worker_core.active_attempt(next_state) == option.None
  assert count_command(commands, is_cancel_timer) == 1
  assert count_command(commands, is_job_finished) == 1
  assert count_command(commands, is_insert_log) == 1
  assert count_command(commands, is_trigger_now) == 1
}

pub fn timed_out_attempt_requests_timeout_and_followup_test() {
  let subject = process.new_subject()
  let timer = process.send_after(subject, 1000, Nil)
  let pid = process.self()
  let state = active_state(pid, timer)

  let #(next_state, commands) =
    job_worker_core.on_attempt_timed_out(state, pid, test_log_entry())

  assert job_worker_core.active_attempt(next_state) == option.None
  assert count_command(commands, is_kill_attempt) == 1
  assert count_command(commands, is_timeout_job) == 1
  assert count_command(commands, is_job_finished) == 1
  assert count_command(commands, is_insert_log) == 1
  assert count_command(commands, is_trigger_now) == 1
}

pub fn interrupted_attempt_finishes_without_timeout_or_followup_test() {
  let subject = process.new_subject()
  let timer = process.send_after(subject, 1000, Nil)
  let pid = process.self()
  let state = active_state(pid, timer)

  let #(next_state, commands) =
    job_worker_core.on_attempt_interrupted_for_shutdown(
      state,
      pid,
      test_log_entry(),
    )

  assert job_worker_core.active_attempt(next_state) == option.None
  assert count_command(commands, is_job_finished) == 1
  assert count_command(commands, is_insert_log) == 1
  assert count_command(commands, is_timeout_job) == 0
  assert count_command(commands, is_trigger_now) == 0
}

fn active_state(
  pid: process.Pid,
  timer: process.Timer,
) -> job_worker_core.State {
  let #(job, ctx) = test_job_and_context()
  let #(state, _) =
    job_worker_core.on_attempt_started(
      job_worker_core.new(),
      pid,
      timer,
      job,
      ctx,
    )
  state
}

fn test_job_and_context() -> #(job_model.Job, context.Context) {
  let now = timestamp.from_unix_seconds(1)
  let assert Ok(request_id) =
    uuid.from_string("0196e8d4-2cb3-7d0a-a0b5-8f5f31337c01")
  let assert Ok(job_id) =
    uuid.from_string("0196e8d4-2cb3-7d0a-a0b5-8f5f31337c02")
  let job =
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
      timeout_seconds: 30,
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
  let assert Ok(email_regex) = regexp.from_string(".+")
  let ctx =
    context.Context(
      config: context.Config(
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
      ),
      regexes: context.Regexes(is_email: email_regex),
      request_id: request_id,
      started_at: 1,
      deadline_at_monotonic_ns: option.Some(2),
      timestamp: now,
      client_info: context.empty_client_info(),
    )
  #(job, ctx)
}

fn test_log_entry() -> log_entry.LogEntry {
  let now = timestamp.from_unix_seconds(1)
  let assert Ok(request_id) =
    uuid.from_string("0196e8d4-2cb3-7d0a-a0b5-8f5f31337c03")
  let assert Ok(job_id) =
    uuid.from_string("0196e8d4-2cb3-7d0a-a0b5-8f5f31337c04")
  let assert Ok(log_id) =
    uuid.from_string("0196e8d4-2cb3-7d0a-a0b5-8f5f31337c05")

  log_entry.LogEntry(
    id: log_id,
    request_id: option.Some(request_id),
    job_id: job_id,
    job_type: job_model.CleanJobsJob,
    attempt: 1,
    created_at: now,
    duration_ns: 1,
    info: dict.new(),
    warnings: dict.new(),
    debug: dict.new(),
    error: option.None,
    effects: [],
  )
}

fn count_command(
  commands: List(job_worker_core.Command),
  predicate: fn(job_worker_core.Command) -> Bool,
) -> Int {
  commands
  |> list.filter(predicate)
  |> list.length
}

fn is_cancel_timer(command: job_worker_core.Command) -> Bool {
  case command {
    job_worker_core.CancelTimer(_) -> True
    _ -> False
  }
}

fn is_job_finished(command: job_worker_core.Command) -> Bool {
  case command {
    job_worker_core.JobFinished -> True
    _ -> False
  }
}

fn is_insert_log(command: job_worker_core.Command) -> Bool {
  case command {
    job_worker_core.InsertJobLog(_) -> True
    _ -> False
  }
}

fn is_trigger_now(command: job_worker_core.Command) -> Bool {
  case command {
    job_worker_core.TriggerTickNow -> True
    _ -> False
  }
}

fn is_kill_attempt(command: job_worker_core.Command) -> Bool {
  case command {
    job_worker_core.KillAttempt(_) -> True
    _ -> False
  }
}

fn is_timeout_job(command: job_worker_core.Command) -> Bool {
  case command {
    job_worker_core.TimeoutJob(_, _) -> True
    _ -> False
  }
}

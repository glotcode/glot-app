import gleam/erlang/process
import gleam/option
import glot_backend/job/model/log_entry
import glot_backend/system/lifecycle/server_mode/model.{type Mode}
import glot_backend/system/request/context
import glot_core/job/job_model

pub const idle_poll_ms = 1000

pub type ActiveAttempt {
  ActiveAttempt(
    pid: process.Pid,
    timer: process.Timer,
    job: job_model.Job,
    ctx: context.Context,
  )
}

pub type State {
  State(active_attempt: option.Option(ActiveAttempt))
}

pub type Command {
  ScheduleTick(delay_ms: Int)
  TriggerTickNow
  JobStarted
  JobFinished
  CancelTimer(timer: process.Timer)
  KillAttempt(pid: process.Pid)
  TimeoutJob(ctx: context.Context, job: job_model.Job)
  InsertJobLog(entry: log_entry.LogEntry)
}

pub fn new() -> State {
  State(active_attempt: option.None)
}

pub fn active_attempt(state: State) -> option.Option(ActiveAttempt) {
  state.active_attempt
}

pub fn on_tick(
  state: State,
  mode: Mode,
  maybe_delay: option.Option(Int),
) -> #(State, List(Command)) {
  case mode {
    model.Maintenance -> #(state, [ScheduleTick(idle_poll_ms)])
    model.ShuttingDown -> #(state, [])
    model.Running ->
      case maybe_delay {
        option.Some(delay) if delay <= 0 -> #(state, [TriggerTickNow])
        option.Some(delay) -> #(state, [ScheduleTick(delay)])
        option.None -> #(state, [])
      }
  }
}

pub fn on_attempt_started(
  _state: State,
  pid: process.Pid,
  timer: process.Timer,
  job: job_model.Job,
  ctx: context.Context,
) -> #(State, List(Command)) {
  #(State(active_attempt: option.Some(ActiveAttempt(pid, timer, job, ctx))), [
    JobStarted,
  ])
}

pub fn on_attempt_completed(
  state: State,
  pid: process.Pid,
  log_entry: log_entry.LogEntry,
) -> #(State, List(Command)) {
  case state.active_attempt {
    option.Some(active) if active.pid == pid -> #(
      State(active_attempt: option.None),
      [
        CancelTimer(active.timer),
        JobFinished,
        InsertJobLog(log_entry),
        TriggerTickNow,
      ],
    )
    _ -> #(state, [])
  }
}

pub fn on_attempt_timed_out(
  state: State,
  pid: process.Pid,
  timeout_log_entry: log_entry.LogEntry,
) -> #(State, List(Command)) {
  case state.active_attempt {
    option.Some(active) if active.pid == pid -> #(
      State(active_attempt: option.None),
      [
        KillAttempt(active.pid),
        TimeoutJob(active.ctx, active.job),
        JobFinished,
        InsertJobLog(timeout_log_entry),
        TriggerTickNow,
      ],
    )
    _ -> #(state, [])
  }
}

pub fn on_attempt_interrupted_for_shutdown(
  state: State,
  pid: process.Pid,
  log_entry: log_entry.LogEntry,
) -> #(State, List(Command)) {
  case state.active_attempt {
    option.Some(active) if active.pid == pid -> #(
      State(active_attempt: option.None),
      [JobFinished, InsertJobLog(log_entry)],
    )
    _ -> #(state, [])
  }
}

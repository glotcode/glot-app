import gleam/erlang/process
import gleam/list
import gleam/option.{type Option}
import gleam/otp/actor
import gleam/otp/supervision
import gleam/time/timestamp.{type Timestamp}
import glot_backend/job/model/log_entry
import glot_backend/job/ports/tracker.{type Tracker}
import glot_backend/job/worker/executor/core
import glot_backend/system/effect/basic/basic_handlers
import glot_backend/system/effect/error
import glot_backend/system/effect/error/infra_error
import glot_backend/system/effect/program_state
import glot_backend/system/lifecycle/server_mode/model
import glot_backend/system/lifecycle/server_mode/ports/controller.{
  type Controller,
}
import glot_backend/system/request/context
import glot_backend/system/runtime/erlang
import glot_backend/system/worker/tick_support as tick_worker_support
import glot_core/job/job_model
import youid/uuid.{type Uuid}

pub type Message {
  Tick
  AttemptCompleted(pid: process.Pid, log_entry: log_entry.LogEntry)
  AttemptTimedOut(pid: process.Pid)
  InterruptForShutdown(reply: process.Subject(Result(Nil, String)))
}

pub type Deps {
  Deps(
    enqueue_next_due_periodic_job: fn(context.Context) -> Result(Bool, String),
    recover_next_expired_job: fn(context.Context) ->
      Result(Option(job_model.Job), String),
    claim_next_job: fn(context.Context) -> Result(Option(job_model.Job), String),
    process_job: fn(context.Context, job_model.Job) ->
      #(Result(Nil, error.Error), program_state.State),
    timeout_job: fn(context.Context, job_model.Job) -> Result(Nil, String),
    interrupt_job_for_shutdown: fn(context.Context, job_model.Job) ->
      Result(Nil, String),
    insert_job_log: fn(log_entry.LogEntry) -> Result(Nil, String),
    spawn_attempt: fn(fn() -> Nil) -> process.Pid,
    send_after: fn(process.Subject(Message), Int, Message) -> process.Timer,
    cancel_timer: fn(process.Timer) -> Nil,
    kill: fn(process.Pid) -> Nil,
    now_timestamp: fn() -> Timestamp,
    now_monotonic_ns: fn() -> Int,
    log_error: fn(String) -> Nil,
  )
}

type State {
  State(
    subject: process.Subject(Message),
    config: context.Config,
    regexes: context.Regexes,
    server_mode: Controller,
    tracker: Tracker,
    deps: Deps,
    tick_timer: Option(process.Timer),
    core: core.State,
  )
}

pub fn start_with_deps(
  config: context.Config,
  regexes: context.Regexes,
  server_mode: Controller,
  tracker: Tracker,
  deps: Deps,
) {
  start_with_optional_name(
    option.None,
    config,
    regexes,
    server_mode,
    tracker,
    deps,
  )
}

pub fn start_named_with_deps(
  name: process.Name(Message),
  config: context.Config,
  regexes: context.Regexes,
  server_mode: Controller,
  tracker: Tracker,
  deps: Deps,
) {
  start_with_optional_name(
    option.Some(name),
    config,
    regexes,
    server_mode,
    tracker,
    deps,
  )
}

fn start_with_optional_name(
  maybe_name: Option(process.Name(Message)),
  config: context.Config,
  regexes: context.Regexes,
  server_mode: Controller,
  tracker: Tracker,
  deps: Deps,
) {
  let actor =
    actor.new_with_initialiser(1000, fn(subject) {
      let initial_state =
        State(
          subject: subject,
          config: config,
          regexes: regexes,
          server_mode: server_mode,
          tracker: tracker,
          deps: deps,
          tick_timer: option.None,
          core: core.new(),
        )
      let _ = process.send(subject, Tick)
      let initialised = actor.initialised(initial_state)
      Ok(actor.returning(initialised, Nil))
    })
    |> actor.on_message(handle_message)

  let actor = case maybe_name {
    option.Some(name) -> actor.named(actor, name)
    option.None -> actor
  }

  actor |> actor.start
}

pub fn supervised(
  config: context.Config,
  regexes: context.Regexes,
  server_mode: Controller,
  tracker: Tracker,
  deps: Deps,
) {
  supervision.worker(fn() {
    start_with_deps(config, regexes, server_mode, tracker, deps)
  })
}

pub fn supervised_named(
  name: process.Name(Message),
  config: context.Config,
  regexes: context.Regexes,
  server_mode: Controller,
  tracker: Tracker,
  deps: Deps,
) {
  supervision.worker(fn() {
    start_named_with_deps(name, config, regexes, server_mode, tracker, deps)
  })
}

pub fn interrupt_for_shutdown(
  subject: process.Subject(Message),
) -> Result(Nil, String) {
  let reply = process.new_subject()
  process.send(subject, InterruptForShutdown(reply))
  case process.receive(reply, 7000) {
    Ok(result) -> result
    Error(_) -> Error("job executor shutdown interruption timed out")
  }
}

fn handle_message(
  state: State,
  message: Message,
) -> actor.Next(State, Message) {
  case message {
    Tick -> {
      let mode = state.server_mode.current()
      case mode {
        // The worker starts before startup migrations finish. Keep polling so
        // it can begin draining jobs once the server switches to Running.
        model.Maintenance -> {
          let #(next_core, commands) =
            core.on_tick(state.core, mode, option.None)
          actor.continue(run_commands(State(..state, core: next_core), commands))
        }
        model.ShuttingDown -> actor.continue(state)
        model.Running -> {
          let #(next_state, maybe_delay) = run_once(state)
          let #(next_core, commands) =
            core.on_tick(next_state.core, mode, maybe_delay)
          actor.continue(run_commands(
            State(..next_state, core: next_core),
            commands,
          ))
        }
      }
    }
    AttemptCompleted(pid, log_entry) -> {
      let #(next_core, commands) =
        core.on_attempt_completed(state.core, pid, log_entry)
      actor.continue(run_commands(State(..state, core: next_core), commands))
    }
    AttemptTimedOut(pid) -> {
      case core.active_attempt(state.core) {
        option.Some(active) if active.pid == pid -> {
          let timeout_log_entry =
            prepare_timeout_log_entry(active.ctx, active.job)
          let #(next_core, commands) =
            core.on_attempt_timed_out(state.core, pid, timeout_log_entry)
          actor.continue(run_commands(State(..state, core: next_core), commands))
        }
        _ -> actor.continue(state)
      }
    }
    InterruptForShutdown(reply) -> {
      let #(next_state, result) = interrupt_active_attempt(state)
      process.send(reply, result)
      actor.continue(next_state)
    }
  }
}

fn interrupt_active_attempt(state: State) -> #(State, Result(Nil, String)) {
  let state = cancel_tick(state)
  case core.active_attempt(state.core) {
    option.None -> #(state, Ok(Nil))
    option.Some(active) -> {
      state.deps.cancel_timer(active.timer)
      state.deps.kill(active.pid)
      let shutdown_ctx =
        context_from_state(state, active.job.request_id, option.Some(5))
      case state.deps.interrupt_job_for_shutdown(shutdown_ctx, active.job) {
        Error(err) -> #(state, Error(err))
        Ok(Nil) -> {
          let log_entry = prepare_interrupted_log_entry(active.ctx, active.job)
          let #(next_core, commands) =
            core.on_attempt_interrupted_for_shutdown(
              state.core,
              active.pid,
              log_entry,
            )
          let next_state = State(..state, core: next_core)
          #(run_commands(next_state, commands), Ok(Nil))
        }
      }
    }
  }
}

fn cancel_tick(state: State) -> State {
  let _ = tick_worker_support.cancel(state.tick_timer)
  State(..state, tick_timer: option.None)
}

fn schedule_tick_after(state: State, delay: Int) -> State {
  let _ = tick_worker_support.cancel(state.tick_timer)
  let timer = state.deps.send_after(state.subject, delay, Tick)
  State(..state, tick_timer: option.Some(timer))
}

fn trigger_tick_now(state: State) -> State {
  tick_worker_support.trigger_now(state.tick_timer, state.subject, Tick)
  State(..state, tick_timer: option.None)
}

fn run_once(state: State) -> #(State, Option(Int)) {
  case core.active_attempt(state.core) {
    option.Some(_) -> #(state, option.None)
    option.None -> {
      let ctx = context_from_state(state, option.None, option.None)
      let periodic_result = state.deps.enqueue_next_due_periodic_job(ctx)

      case periodic_result {
        Ok(True) -> #(state, option.Some(0))
        Ok(False) -> recover_or_claim_job(state, ctx)
        Error(err) -> {
          state.deps.log_error("Failed to enqueue periodic job: " <> err)
          recover_or_claim_job(state, ctx)
        }
      }
    }
  }
}

fn recover_or_claim_job(
  state: State,
  ctx: context.Context,
) -> #(State, Option(Int)) {
  let recovery_result = state.deps.recover_next_expired_job(ctx)

  case recovery_result {
    Ok(option.Some(recovered_job)) -> {
      let next_state =
        persist_log_entry(
          state,
          prepare_recovered_timeout_log_entry(ctx, recovered_job),
        )
      #(next_state, option.Some(0))
    }
    Ok(option.None) -> claim_and_process_job(state, ctx)
    Error(err) -> {
      state.deps.log_error("Failed to recover expired job: " <> err)
      claim_and_process_job(state, ctx)
    }
  }
}

fn claim_and_process_job(
  state: State,
  ctx: context.Context,
) -> #(State, Option(Int)) {
  let result = state.deps.claim_next_job(ctx)

  case result {
    Ok(maybe_job) ->
      case maybe_job {
        option.Some(job) -> #(start_attempt(state, job), option.None)
        option.None -> #(state, option.Some(core.idle_poll_ms))
      }
    Error(err) -> {
      state.deps.log_error("Failed to claim job: " <> err)
      #(state, option.Some(core.idle_poll_ms))
    }
  }
}

fn start_attempt(state: State, job: job_model.Job) -> State {
  let ctx =
    context_from_state(state, job.request_id, option.Some(job.timeout_seconds))
  let subject = state.subject
  let deps = state.deps

  let pid =
    deps.spawn_attempt(fn() {
      let #(result, program_state) = deps.process_job(ctx, job)
      process.send(
        subject,
        AttemptCompleted(
          process.self(),
          prepare_log_entry(ctx, program_state, job, result),
        ),
      )
    })

  let timeout_timer =
    deps.send_after(subject, job.timeout_seconds * 1000, AttemptTimedOut(pid))

  let #(next_core, commands) =
    core.on_attempt_started(state.core, pid, timeout_timer, job, ctx)
  run_commands(State(..state, core: next_core), commands)
}

fn prepare_timeout_log_entry(
  ctx: context.Context,
  job: job_model.Job,
) -> log_entry.LogEntry {
  log_entry.LogEntry(
    ..prepare_log_entry(
      ctx,
      program_state.new_state(),
      job,
      Error(error.infra(infra_error.JobTimeoutExceeded)),
    ),
    created_at: basic_handlers.system_time(),
  )
}

fn prepare_recovered_timeout_log_entry(
  ctx: context.Context,
  job: job_model.Job,
) -> log_entry.LogEntry {
  log_entry.LogEntry(
    ..prepare_timeout_log_entry(ctx, job),
    created_at: ctx.timestamp,
  )
}

fn prepare_interrupted_log_entry(
  ctx: context.Context,
  job: job_model.Job,
) -> log_entry.LogEntry {
  prepare_log_entry(
    ctx,
    program_state.new_state(),
    job,
    Error(error.infra(infra_error.JobInterruptedForShutdown)),
  )
}

fn prepare_log_entry(
  ctx: context.Context,
  state: program_state.State,
  job: job_model.Job,
  result: Result(Nil, error.Error),
) -> log_entry.LogEntry {
  let id = basic_handlers.uuid_v7(ctx.timestamp)
  let duration_ns = erlang.perf_counter_ns() - ctx.started_at

  let error = case result {
    Ok(_) -> option.None
    Error(err) -> option.Some(err)
  }

  log_entry.LogEntry(
    id: id,
    request_id: job.request_id,
    job_id: job.id,
    job_type: job.job_type,
    attempt: job.attempts,
    created_at: ctx.timestamp,
    duration_ns: duration_ns,
    info: state.info_fields,
    warnings: state.warning_fields,
    debug: state.debug_fields,
    error: error,
    effects: state.effect_measurements,
  )
}

fn context_from_state(
  state: State,
  request_id: option.Option(Uuid),
  timeout_seconds: option.Option(Int),
) -> context.Context {
  let now = state.deps.now_timestamp()
  let started_at = state.deps.now_monotonic_ns()

  context.Context(
    config: state.config,
    regexes: state.regexes,
    request_id: request_id
      |> option.lazy_unwrap(fn() { basic_handlers.uuid_v7(now) }),
    started_at: started_at,
    deadline_at_monotonic_ns: option.map(timeout_seconds, fn(seconds) {
      started_at + { seconds * 1_000_000_000 }
    }),
    timestamp: now,
    client_info: context.empty_client_info(),
  )
}

fn run_commands(state: State, commands: List(core.Command)) -> State {
  list.fold(commands, state, fn(state: State, command) {
    case command {
      core.ScheduleTick(delay_ms) -> schedule_tick_after(state, delay_ms)
      core.TriggerTickNow -> trigger_tick_now(state)
      core.JobStarted -> {
        state.tracker.started()
        state
      }
      core.JobFinished -> {
        state.tracker.finished()
        state
      }
      core.CancelTimer(timer) -> {
        state.deps.cancel_timer(timer)
        state
      }
      core.KillAttempt(pid) -> {
        state.deps.kill(pid)
        state
      }
      core.TimeoutJob(ctx, job) -> {
        case state.deps.timeout_job(ctx, job) {
          Ok(_) -> state
          Error(err) -> {
            state.deps.log_error("Failed to time out job: " <> err)
            state
          }
        }
      }
      core.InsertJobLog(entry) -> persist_log_entry(state, entry)
    }
  })
}

fn persist_log_entry(state: State, entry: log_entry.LogEntry) -> State {
  case state.deps.insert_job_log(entry) {
    Ok(_) -> state
    Error(err) -> {
      state.deps.log_error("Failed to insert job log entry: " <> err)
      state
    }
  }
}

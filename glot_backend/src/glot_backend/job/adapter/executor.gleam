import gleam/erlang/process
import gleam/result
import gleam/string
import glot_backend/job/domain/manager as job_manager_domain
import glot_backend/job/domain/periodic_manager as periodic_job_manager_domain
import glot_backend/job/ports/log_store.{type LogStore}
import glot_backend/job/worker/executor/worker
import glot_backend/system/effect/basic/basic_handlers
import glot_backend/system/effect/error/db_error
import glot_backend/system/effect/interpreter
import glot_backend/system/effect/runtime.{type Runtime}
import glot_backend/system/runtime/erlang
import glot_core/job/job_model.{type Queue}
import wisp

pub fn new(
  effect_runtime: Runtime,
  log_store: LogStore,
  queue: Queue,
) -> worker.Deps {
  worker.Deps(
    enqueue_next_due_periodic_job: fn(ctx) {
      case queue {
        job_model.DefaultQueue -> {
          let #(outcome, _) =
            periodic_job_manager_domain.enqueue_next_due_periodic_job(ctx)
            |> interpreter.run(effect_runtime, ctx)
          outcome |> result.map_error(string.inspect)
        }
        job_model.SpamClassifierQueue -> Ok(False)
      }
    },
    recover_next_expired_job: fn(ctx) {
      let #(outcome, _) =
        job_manager_domain.recover_next_expired_job(ctx, queue)
        |> interpreter.run(effect_runtime, ctx)
      outcome |> result.map_error(string.inspect)
    },
    claim_next_job: fn(ctx) {
      let #(outcome, _) =
        job_manager_domain.claim_next_job(ctx, queue)
        |> interpreter.run(effect_runtime, ctx)
      outcome |> result.map_error(string.inspect)
    },
    process_job: fn(ctx, job) {
      job_manager_domain.process_job(ctx, job)
      |> interpreter.run(effect_runtime, ctx)
    },
    timeout_job: fn(ctx, job) {
      let #(outcome, _) =
        job_manager_domain.timeout_job(ctx, job)
        |> interpreter.run(effect_runtime, ctx)
      outcome |> result.map_error(string.inspect)
    },
    interrupt_job_for_shutdown: fn(ctx, job) {
      let #(outcome, _) =
        job_manager_domain.interrupt_job_for_shutdown(ctx, job)
        |> interpreter.run(effect_runtime, ctx)
      outcome |> result.map_error(string.inspect)
    },
    insert_job_log: fn(entry) {
      log_store.insert(entry)
      |> result.map_error(fn(error) {
        let db_error.DbCommandError(message) = error
        message
      })
    },
    spawn_attempt: process.spawn_unlinked,
    send_after: fn(subject, delay, message) {
      process.send_after(subject, delay, message)
    },
    cancel_timer: fn(timer) {
      let _ = process.cancel_timer(timer)
      Nil
    },
    kill: process.kill,
    now_timestamp: basic_handlers.system_time,
    now_monotonic_ns: erlang.perf_counter_ns,
    log_error: wisp.log_error,
  )
}

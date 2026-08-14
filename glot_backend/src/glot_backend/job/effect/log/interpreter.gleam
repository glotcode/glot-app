import glot_backend/job/effect/algebra as job_effect_algebra
import glot_backend/job/effect/log/algebra as job_log_algebra
import glot_backend/job/ports/log_store.{type LogStore}
import glot_backend/system/effect/effect_trace
import glot_backend/system/effect/error
import glot_backend/system/effect/measured_interpreter
import glot_backend/system/effect/program_state

pub fn run(
  effect: job_log_algebra.JobLogEffect(next_program),
  store: LogStore,
  state: program_state.State,
  continue: fn(next_program, program_state.State) ->
    #(Result(a, error.Error), program_state.State),
) -> #(Result(a, error.Error), program_state.State) {
  case effect {
    job_log_algebra.ListJobLogs(request:, next:) ->
      measured_interpreter.run_or_fail(
        fn() { store.list(request) },
        next,
        map_error: error.database_query_error,
        name: trace_name(job_log_algebra.ListJobLogsEffectName),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    job_log_algebra.GetJobLog(id:, next:) ->
      measured_interpreter.run_or_fail(
        fn() { store.get(id) },
        next,
        map_error: error.database_query_error,
        name: trace_name(job_log_algebra.GetJobLogEffectName),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    job_log_algebra.DeleteJobLogBefore(before:, next:) ->
      measured_interpreter.run(
        fn() { store.delete_before(before) },
        next,
        name: trace_name(job_log_algebra.DeleteJobLogBeforeEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
  }
}

fn trace_name(name: job_log_algebra.EffectName) -> effect_trace.EffectName {
  effect_trace.JobEffectName(job_effect_algebra.LogName(name))
}

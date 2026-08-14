import glot_backend/job/effect/algebra as job_effect_algebra
import glot_backend/job/effect/periodic/algebra as periodic_job_algebra
import glot_backend/job/ports/periodic_store.{type PeriodicStore}
import glot_backend/system/effect/effect_trace
import glot_backend/system/effect/error
import glot_backend/system/effect/measured_interpreter
import glot_backend/system/effect/program_state

pub fn run(
  effect: periodic_job_algebra.PeriodicJobEffect(next_program),
  store: PeriodicStore,
  state: program_state.State,
  continue: fn(next_program, program_state.State) ->
    #(Result(a, error.Error), program_state.State),
) -> #(Result(a, error.Error), program_state.State) {
  case effect {
    periodic_job_algebra.ListPeriodicJobs(next:) ->
      measured_interpreter.run_or_fail(
        store.list_periodic_jobs,
        next,
        map_error: error.database_query_error,
        name: trace_name(periodic_job_algebra.ListPeriodicJobsEffectName),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    periodic_job_algebra.GetNextPeriodicJob(now:, next:) ->
      measured_interpreter.run_or_fail(
        fn() { store.get_next_periodic_job(now) },
        next,
        map_error: error.database_query_error,
        name: trace_name(periodic_job_algebra.GetNextPeriodicJobEffectName),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    periodic_job_algebra.GetPeriodicJobById(id:, next:) ->
      measured_interpreter.run_or_fail(
        fn() { store.get_periodic_job_by_id(id) },
        next,
        map_error: error.database_query_error,
        name: trace_name(periodic_job_algebra.GetPeriodicJobByIdEffectName),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    periodic_job_algebra.CreatePeriodicJob(periodic_job, next) ->
      measured_interpreter.run(
        fn() { store.create_periodic_job(periodic_job) },
        next,
        name: trace_name(periodic_job_algebra.CreatePeriodicJobEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
    periodic_job_algebra.UpdatePeriodicJob(periodic_job, next) ->
      measured_interpreter.run(
        fn() { store.update_periodic_job(periodic_job) },
        next,
        name: trace_name(periodic_job_algebra.UpdatePeriodicJobEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
  }
}

fn trace_name(
  name: periodic_job_algebra.EffectName,
) -> effect_trace.EffectName {
  effect_trace.JobEffectName(job_effect_algebra.PeriodicName(name))
}

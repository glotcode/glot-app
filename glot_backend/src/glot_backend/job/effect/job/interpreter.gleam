import glot_backend/job/effect/algebra as job_effect_algebra
import glot_backend/job/effect/job/algebra as job_algebra
import glot_backend/job/ports/job_store.{type JobStore}
import glot_backend/system/effect/effect_trace
import glot_backend/system/effect/error
import glot_backend/system/effect/measured_interpreter
import glot_backend/system/effect/program_state

pub fn run(
  effect: job_algebra.JobEffect(next_program),
  store: JobStore,
  state: program_state.State,
  continue: fn(next_program, program_state.State) ->
    #(Result(a, error.Error), program_state.State),
) -> #(Result(a, error.Error), program_state.State) {
  case effect {
    job_algebra.ListJobs(filter:, pagination:, next:) ->
      measured_interpreter.run_or_fail(
        fn() { store.list_jobs(filter, pagination) },
        next,
        map_error: error.database_query_error,
        name: trace_name(job_algebra.ListJobsEffectName),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    job_algebra.SummarizeJobs(filter:, now:, next:) ->
      measured_interpreter.run_or_fail(
        fn() { store.summarize_jobs(filter, now) },
        next,
        map_error: error.database_query_error,
        name: trace_name(job_algebra.SummarizeJobsEffectName),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    job_algebra.GetNextJob(now:, pending_status:, next:) ->
      measured_interpreter.run_or_fail(
        fn() { store.get_next_job(now, pending_status) },
        next,
        map_error: error.database_query_error,
        name: trace_name(job_algebra.GetNextJobEffectName),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    job_algebra.GetExpiredRunningJob(now:, running_status:, next:) ->
      measured_interpreter.run_or_fail(
        fn() { store.get_expired_running_job(now, running_status) },
        next,
        map_error: error.database_query_error,
        name: trace_name(job_algebra.GetExpiredRunningJobEffectName),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    job_algebra.GetJobById(id:, next:) ->
      measured_interpreter.run_or_fail(
        fn() { store.get_job_by_id(id) },
        next,
        map_error: error.database_query_error,
        name: trace_name(job_algebra.GetJobByIdEffectName),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    job_algebra.CreateJob(job, next) ->
      measured_interpreter.run(
        fn() { store.create_job(job) },
        next,
        name: trace_name(job_algebra.CreateJobEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
    job_algebra.UpdateJob(job, next) ->
      measured_interpreter.run(
        fn() { store.update_job(job) },
        next,
        name: trace_name(job_algebra.UpdateJobEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
    job_algebra.DeleteJob(id, next) ->
      measured_interpreter.run(
        fn() { store.delete_job(id) },
        next,
        name: trace_name(job_algebra.DeleteJobEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
    job_algebra.DeleteBefore(before:, statuses:, next:) ->
      measured_interpreter.run(
        fn() { store.delete_before(before, statuses) },
        next,
        name: trace_name(job_algebra.DeleteBeforeEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
  }
}

fn trace_name(name: job_algebra.EffectName) -> effect_trace.EffectName {
  effect_trace.JobEffectName(job_effect_algebra.JobName(name))
}

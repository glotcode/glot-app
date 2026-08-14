import glot_backend/job/effect/algebra as job_effect_algebra
import glot_backend/job/effect/type_policy/algebra as job_type_policy_algebra
import glot_backend/job/ports/type_policy_store.{type TypePolicyStore}
import glot_backend/system/effect/effect_trace
import glot_backend/system/effect/error
import glot_backend/system/effect/measured_interpreter
import glot_backend/system/effect/program_state

pub fn run(
  effect: job_type_policy_algebra.JobTypePolicyEffect(next_program),
  store: TypePolicyStore,
  state: program_state.State,
  continue: fn(next_program, program_state.State) ->
    #(Result(a, error.Error), program_state.State),
) -> #(Result(a, error.Error), program_state.State) {
  case effect {
    job_type_policy_algebra.ListJobTypePolicies(next:) ->
      measured_interpreter.run_or_fail(
        store.list_job_type_policies,
        next,
        map_error: error.database_query_error,
        name: trace_name(job_type_policy_algebra.ListJobTypePoliciesEffectName),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    job_type_policy_algebra.GetJobTypePolicyByJobType(job_type:, next:) ->
      measured_interpreter.run_or_fail(
        fn() { store.get_job_type_policy_by_job_type(job_type) },
        next,
        map_error: error.database_query_error,
        name: trace_name(
          job_type_policy_algebra.GetJobTypePolicyByJobTypeEffectName,
        ),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    job_type_policy_algebra.UpsertJobTypePolicy(policy:, now:, next:) ->
      measured_interpreter.run_or_fail(
        fn() { store.upsert_job_type_policy(policy, now) },
        next,
        map_error: error.database_command_error,
        name: trace_name(job_type_policy_algebra.UpsertJobTypePolicyEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
  }
}

fn trace_name(
  name: job_type_policy_algebra.EffectName,
) -> effect_trace.EffectName {
  effect_trace.JobEffectName(job_effect_algebra.TypePolicyName(name))
}

import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_backend/job/effect/effect as job_effect
import glot_backend/job/effect/type_policy/algebra as job_type_policy_algebra
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types
import glot_backend/system/effect/transaction/transaction_program
import glot_core/job/job_model

pub fn list_job_type_policies() -> program_types.Program(
  List(job_model.JobTypePolicy),
) {
  program.perform_db(
    job_effect.type_policy(job_type_policy_algebra.ListJobTypePolicies(
      next: program.succeed,
    )),
  )
}

pub fn get_job_type_policy_by_job_type(
  job_type: job_model.JobType,
) -> program_types.Program(option.Option(job_model.JobTypePolicy)) {
  program.perform_db(get_job_type_policy_by_job_type_effect(
    job_type,
    program.succeed,
  ))
}

pub fn get_job_type_policy_by_job_type_tx(
  job_type: job_model.JobType,
) -> program_types.TransactionProgram(option.Option(job_model.JobTypePolicy)) {
  transaction_program.perform(get_job_type_policy_by_job_type_effect(
    job_type,
    transaction_program.succeed,
  ))
}

fn get_job_type_policy_by_job_type_effect(
  job_type: job_model.JobType,
  next: fn(option.Option(job_model.JobTypePolicy)) -> next,
) -> program_types.DbEffect(next) {
  job_effect.type_policy(job_type_policy_algebra.GetJobTypePolicyByJobType(
    job_type: job_type,
    next: next,
  ))
}

pub fn upsert_job_type_policy(
  policy: job_model.JobTypePolicy,
  now: Timestamp,
) -> program_types.Program(Nil) {
  program.perform_db(
    job_effect.type_policy(job_type_policy_algebra.UpsertJobTypePolicy(
      policy: policy,
      now: now,
      next: program.succeed,
    )),
  )
}

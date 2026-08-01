import gleam/option
import glot_backend/job/domain/type_policy as job_type_policy_domain
import glot_backend/job/effect/job/effect as job_effect
import glot_backend/job/effect/periodic/effect as periodic_job_effect
import glot_backend/system/effect/basic/basic_effect
import glot_backend/system/effect/error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{
  type Program, type TransactionProgram,
}
import glot_backend/system/effect/transaction/transaction_effect
import glot_backend/system/effect/transaction/transaction_program
import glot_backend/system/request/context.{type Context}
import glot_core/job/job_model.{type JobTypePolicy}
import glot_core/periodic_job/periodic_job_model.{type PeriodicJob}
import youid/uuid.{type Uuid}

pub fn enqueue_next_due_periodic_job(ctx: Context) -> Program(Bool) {
  use maybe_periodic_job <- program.and_then(
    periodic_job_effect.get_next_periodic_job(ctx.timestamp),
  )

  case maybe_periodic_job {
    option.None -> program.succeed(False)
    option.Some(periodic_job) -> {
      use job_id <- program.and_then(basic_effect.uuid_v7())
      use job_type_policy <- program.and_then(
        job_type_policy_domain.require_job_type_policy(periodic_job.job_type),
      )
      use _ <- program.and_then(
        enqueue_next_due_periodic_job_tx(
          ctx,
          job_id,
          periodic_job,
          job_type_policy,
        )
        |> transaction_effect.run()
        |> program.attempt(fn(enqueue_error) {
          let failed_periodic_job =
            periodic_job_model.enqueue_failed(
              periodic_job,
              error.to_string(enqueue_error),
              ctx.timestamp,
            )
          use _ <- program.and_then(periodic_job_effect.update_periodic_job(
            failed_periodic_job,
          ))
          program.fail(enqueue_error)
        }),
      )
      program.succeed(True)
    }
  }
}

fn enqueue_next_due_periodic_job_tx(
  ctx: Context,
  job_id: Uuid,
  periodic_job: PeriodicJob,
  job_type_policy: JobTypePolicy,
) -> TransactionProgram(Nil) {
  let job =
    job_model.periodic_job_execution(
      job_id,
      ctx.timestamp,
      periodic_job.id,
      periodic_job.job_type,
      periodic_job.payload,
      job_type_policy,
    )
  let updated_periodic_job =
    periodic_job_model.enqueued(periodic_job, ctx.timestamp)

  use _ <- transaction_program.and_then(job_effect.create_job_tx(job))
  use _ <- transaction_program.and_then(
    periodic_job_effect.update_periodic_job_tx(updated_periodic_job),
  )
  transaction_program.succeed(Nil)
}

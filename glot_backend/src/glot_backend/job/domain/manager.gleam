import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}
import glot_backend/analytics/domain/aggregate_metrics as aggregate_metrics_domain
import glot_backend/auth/domain/account/delete as delete_account_domain
import glot_backend/auth/domain/cleanup/sessions as clean_sessions_domain
import glot_backend/auth/domain/cleanup/verification_tokens as clean_verification_tokens_domain
import glot_backend/email/domain/send as send_email_domain
import glot_backend/job/domain/cleanup/jobs as clean_jobs_domain
import glot_backend/job/domain/cleanup/logs as clean_job_log_domain
import glot_backend/job/effect/job/effect as job_effect
import glot_backend/logging/api_log/domain/cleanup as clean_api_log_domain
import glot_backend/logging/page_log/domain/cleanup as clean_page_log_domain
import glot_backend/logging/pageview/domain/cleanup as clean_pageview_log_domain
import glot_backend/logging/run_log/domain/cleanup as clean_run_log_domain
import glot_backend/spam_classifier/domain/classify_next as classify_snippet_domain
import glot_backend/system/effect/basic/basic_effect
import glot_backend/system/effect/error.{type Error}
import glot_backend/system/effect/error/infra_error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{
  type Program, type TransactionProgram,
}
import glot_backend/system/effect/transaction/transaction_effect
import glot_backend/system/effect/transaction/transaction_program
import glot_backend/system/request/context.{type Context}
import glot_backend/user_action/domain/cleanup as clean_user_actions_domain
import glot_core/job/job_model.{type Job, type Queue}

type HandlerOutcome {
  CompleteJob
  ContinueImmediately
}

pub fn claim_next_job(ctx: Context, queue: Queue) -> Program(Option(Job)) {
  transaction_effect.run({
    use maybe_job <- transaction_program.and_then(job_effect.get_next_job_tx(
      queue,
      ctx.timestamp,
      job_model.Pending,
    ))

    case maybe_job {
      option.None -> transaction_program.succeed(option.None)
      option.Some(next_job) -> claim_job(next_job, ctx.timestamp)
    }
  })
}

pub fn recover_next_expired_job(
  ctx: Context,
  queue: Queue,
) -> Program(Option(Job)) {
  transaction_effect.run({
    use maybe_job <- transaction_program.and_then(
      job_effect.get_expired_running_job_tx(
        queue,
        ctx.timestamp,
        job_model.Running,
      ),
    )

    case maybe_job {
      option.None -> transaction_program.succeed(option.None)
      option.Some(expired_job) -> recover_job(expired_job, ctx.timestamp)
    }
  })
}

pub fn process_job(ctx: Context, job: Job) -> Program(Nil) {
  use outcome <- program.and_then(
    delegate_job(ctx, job)
    |> program.attempt(fn(err) {
      use _ <- program.and_then(handle_failed_job(job, err))
      program.fail(err)
    }),
  )
  case outcome {
    CompleteJob -> complete_job(job)
    ContinueImmediately -> continue_job(job)
  }
}

pub fn timeout_job(_ctx: Context, job: Job) -> Program(Nil) {
  use now <- program.and_then(basic_effect.system_time())
  let timed_out_job =
    job_model.timed_out(job, add_seconds(now, backoff_seconds(job)), now)
  persist_and_release(job, timed_out_job)
}

pub fn interrupt_job_for_shutdown(_ctx: Context, job: Job) -> Program(Nil) {
  use now <- program.and_then(basic_effect.system_time())
  let interrupted_job = job_model.interrupted_for_shutdown(job, now)
  persist_and_release(job, interrupted_job)
}

fn delegate_job(ctx: Context, job: Job) -> Program(HandlerOutcome) {
  case job.job_type {
    job_model.SendEmailJob -> {
      use payload <- program.and_then(require_payload(job))
      use email <- program.and_then(send_email_domain.email_from_json(
        ctx,
        payload,
      ))
      complete_after(send_email_domain.send_email(email))
    }
    job_model.DeleteAccountJob -> {
      use payload <- program.and_then(require_payload(job))
      use payload <- program.and_then(delete_account_domain.payload_from_json(
        payload,
      ))
      complete_after(delete_account_domain.delete_account(ctx, payload))
    }
    job_model.CleanApiLogJob ->
      complete_after(clean_api_log_domain.clean_api_log(ctx))
    job_model.CleanPageLogJob ->
      complete_after(clean_page_log_domain.clean_page_log(ctx))
    job_model.CleanPageviewLogJob ->
      complete_after(clean_pageview_log_domain.clean_pageview_log(ctx))
    job_model.CleanRunLogJob ->
      complete_after(clean_run_log_domain.clean_run_log(ctx))
    job_model.CleanJobLogJob ->
      complete_after(clean_job_log_domain.clean_job_log(ctx))
    job_model.CleanJobsJob -> complete_after(clean_jobs_domain.clean_jobs(ctx))
    job_model.CleanSessionsJob ->
      complete_after(clean_sessions_domain.clean_sessions(ctx))
    job_model.CleanVerificationTokensJob ->
      complete_after(clean_verification_tokens_domain.clean_verification_tokens(
        ctx,
      ))
    job_model.CleanUserActionsJob ->
      complete_after(clean_user_actions_domain.clean_user_actions(ctx))
    job_model.AggregateMetricsJob ->
      complete_after(aggregate_metrics_domain.aggregate_metrics(ctx))
    job_model.ClassifySnippetJob ->
      classify_snippet_domain.classify_next(ctx)
      |> program.map(fn(classified) {
        case classified {
          True -> ContinueImmediately
          False -> CompleteJob
        }
      })
  }
}

fn complete_after(effect: Program(Nil)) -> Program(HandlerOutcome) {
  effect |> program.map(fn(_) { CompleteJob })
}

fn require_payload(job: Job) -> Program(String) {
  case job.payload {
    option.Some(payload) -> program.succeed(payload)
    option.None ->
      program.fail(error.infra(infra_error.JobPayloadMissing(job.job_type)))
  }
}

fn claim_job(job: Job, now: Timestamp) -> TransactionProgram(Option(Job)) {
  let started_job = job_model.start(job, now)
  case started_job.lease_expires_at {
    option.None -> transaction_program.succeed(option.None)
    option.Some(lease_expires_at) -> {
      use claimed <- transaction_program.and_then(
        job_effect.claim_queue_slot_tx(
          started_job.queue,
          started_job.id,
          lease_expires_at,
        ),
      )
      case claimed {
        False -> transaction_program.succeed(option.None)
        True -> {
          use _ <- transaction_program.and_then(job_effect.update_job_tx(
            started_job,
          ))
          transaction_program.succeed(option.Some(started_job))
        }
      }
    }
  }
}

fn recover_job(job: Job, now: Timestamp) -> TransactionProgram(Option(Job)) {
  let recovered_job =
    job_model.timed_out(job, add_seconds(now, backoff_seconds(job)), now)
  use _ <- transaction_program.and_then(job_effect.update_job_tx(recovered_job))
  use _ <- transaction_program.and_then(release_queue_slot(job))
  transaction_program.succeed(option.Some(recovered_job))
}

fn complete_job(job: Job) -> Program(Nil) {
  use now <- program.and_then(basic_effect.system_time())
  let completed_job = job_model.done(job, now)
  persist_and_release(job, completed_job)
}

fn continue_job(job: Job) -> Program(Nil) {
  use now <- program.and_then(basic_effect.system_time())
  use successor_id <- program.and_then(basic_effect.uuid_v7())
  let completed_job = job_model.done(job, now)
  let successor_job = job_model.immediate_successor(successor_id, job, now)
  transaction_effect.run(
    transaction_program.sequence([
      job_effect.update_job_tx(completed_job),
      release_queue_slot(job),
      job_effect.create_job_tx(successor_job),
    ]),
  )
}

fn reschedule_job(job: Job, err: Error) -> Program(Nil) {
  use now <- program.and_then(basic_effect.system_time())
  let rescheduled_job =
    job_model.reschedule(
      job,
      add_seconds(now, backoff_seconds(job)),
      option.Some(error.to_string(err)),
      now,
    )
  persist_and_release(job, rescheduled_job)
}

fn handle_failed_job(job: Job, err: Error) -> Program(Nil) {
  case error.failure_disposition(err) {
    infra_error.PermanentFailure -> fail_job(job, err)
    infra_error.RetryWithBackoff -> reschedule_job(job, err)
    infra_error.RetryAfter(seconds) -> reschedule_job_after(job, err, seconds)
    infra_error.RetryIndefinitelyWithBackoff ->
      reschedule_job_indefinitely(job, err, backoff_seconds(job))
    infra_error.RetryIndefinitelyAfter(seconds) ->
      reschedule_job_indefinitely(job, err, seconds)
  }
}

fn reschedule_job_indefinitely(
  job: Job,
  err: Error,
  seconds: Int,
) -> Program(Nil) {
  use now <- program.and_then(basic_effect.system_time())
  let rescheduled_job =
    job_model.reschedule_indefinitely(
      job,
      add_seconds(now, seconds),
      option.Some(error.to_string(err)),
      now,
    )
  persist_and_release(job, rescheduled_job)
}

fn reschedule_job_after(job: Job, err: Error, seconds: Int) -> Program(Nil) {
  use now <- program.and_then(basic_effect.system_time())
  let rescheduled_job =
    job_model.reschedule(
      job,
      add_seconds(now, seconds),
      option.Some(error.to_string(err)),
      now,
    )
  persist_and_release(job, rescheduled_job)
}

fn fail_job(job: Job, err: Error) -> Program(Nil) {
  use now <- program.and_then(basic_effect.system_time())
  let failed_job = job_model.fail(job, option.Some(error.to_string(err)), now)
  persist_and_release(job, failed_job)
}

fn persist_and_release(current_job: Job, updated_job: Job) -> Program(Nil) {
  transaction_effect.run(
    transaction_program.sequence([
      job_effect.update_job_tx(updated_job),
      release_queue_slot(current_job),
    ]),
  )
}

fn release_queue_slot(job: Job) -> TransactionProgram(Nil) {
  case job.lease_expires_at {
    option.Some(lease_expires_at) ->
      job_effect.release_queue_slot_tx(job.id, lease_expires_at)
    option.None -> transaction_program.succeed(Nil)
  }
}

fn backoff_seconds(job: Job) -> Int {
  capped_backoff(
    job.base_backoff_seconds,
    job.max_backoff_seconds,
    job.attempts - 1,
  )
}

fn capped_backoff(candidate: Int, maximum: Int, doublings: Int) -> Int {
  case candidate >= maximum || doublings <= 0 {
    True -> maximum_if_exceeded(candidate, maximum)
    False -> capped_backoff(candidate * 2, maximum, doublings - 1)
  }
}

fn maximum_if_exceeded(candidate: Int, maximum: Int) -> Int {
  case candidate > maximum {
    True -> maximum
    False -> candidate
  }
}

fn add_seconds(ts: Timestamp, seconds_to_add: Int) -> Timestamp {
  let #(seconds, nanos) = timestamp.to_unix_seconds_and_nanoseconds(ts)
  timestamp.from_unix_seconds_and_nanoseconds(seconds + seconds_to_add, nanos)
}

import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}
import glot_backend/analytics/domain/aggregate_metrics as aggregate_metrics_domain
import glot_backend/auth/domain/account/delete as delete_account_domain
import glot_backend/auth/domain/cleanup/login_tokens as clean_login_tokens_domain
import glot_backend/auth/domain/cleanup/sessions as clean_sessions_domain
import glot_backend/email/domain/send as send_email_domain
import glot_backend/job/domain/cleanup/jobs as clean_jobs_domain
import glot_backend/job/domain/cleanup/logs as clean_job_log_domain
import glot_backend/job/effect/job/effect as job_effect
import glot_backend/logging/api_log/domain/cleanup as clean_api_log_domain
import glot_backend/logging/page_log/domain/cleanup as clean_page_log_domain
import glot_backend/logging/pageview/domain/cleanup as clean_pageview_log_domain
import glot_backend/logging/run_log/domain/cleanup as clean_run_log_domain
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
import glot_core/job/job_model.{type Job}

pub fn claim_next_job(ctx: Context) -> Program(Option(Job)) {
  transaction_effect.run({
    use maybe_job <- transaction_program.and_then(job_effect.get_next_job_tx(
      ctx.timestamp,
      job_model.Pending,
    ))

    case maybe_job {
      option.None -> transaction_program.succeed(option.None)
      option.Some(next_job) -> claim_job(next_job, ctx.timestamp)
    }
  })
}

pub fn recover_next_expired_job(ctx: Context) -> Program(Option(Job)) {
  transaction_effect.run({
    use maybe_job <- transaction_program.and_then(
      job_effect.get_expired_running_job_tx(ctx.timestamp, job_model.Running),
    )

    case maybe_job {
      option.None -> transaction_program.succeed(option.None)
      option.Some(expired_job) -> recover_job(expired_job, ctx.timestamp)
    }
  })
}

pub fn process_job(ctx: Context, job: Job) -> Program(Nil) {
  use _ <- program.and_then(
    delegate_job(ctx, job)
    |> program.attempt(fn(err) {
      use _ <- program.and_then(handle_failed_job(job, err))
      program.fail(err)
    }),
  )
  complete_job(job)
}

pub fn timeout_job(_ctx: Context, job: Job) -> Program(Nil) {
  use now <- program.and_then(basic_effect.system_time())
  let timed_out_job =
    job_model.timed_out(job, add_seconds(now, backoff_seconds(job)), now)
  job_effect.update_job(timed_out_job)
}

fn delegate_job(ctx: Context, job: Job) -> Program(Nil) {
  case job.job_type {
    job_model.SendEmailJob -> {
      use payload <- program.and_then(require_payload(job))
      use email <- program.and_then(send_email_domain.email_from_json(
        ctx,
        payload,
      ))
      send_email_domain.send_email(email)
    }
    job_model.DeleteAccountJob -> {
      use payload <- program.and_then(require_payload(job))
      use payload <- program.and_then(delete_account_domain.payload_from_json(
        payload,
      ))
      delete_account_domain.delete_account(ctx, payload)
    }
    job_model.CleanApiLogJob -> clean_api_log_domain.clean_api_log(ctx)
    job_model.CleanPageLogJob -> clean_page_log_domain.clean_page_log(ctx)
    job_model.CleanPageviewLogJob ->
      clean_pageview_log_domain.clean_pageview_log(ctx)
    job_model.CleanRunLogJob -> clean_run_log_domain.clean_run_log(ctx)
    job_model.CleanJobLogJob -> clean_job_log_domain.clean_job_log(ctx)
    job_model.CleanJobsJob -> clean_jobs_domain.clean_jobs(ctx)
    job_model.CleanSessionsJob -> clean_sessions_domain.clean_sessions(ctx)
    job_model.CleanLoginTokensJob ->
      clean_login_tokens_domain.clean_login_tokens(ctx)
    job_model.CleanUserActionsJob ->
      clean_user_actions_domain.clean_user_actions(ctx)
    job_model.AggregateMetricsJob ->
      aggregate_metrics_domain.aggregate_metrics(ctx)
  }
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
  use _ <- transaction_program.and_then(job_effect.update_job_tx(started_job))
  transaction_program.succeed(option.Some(started_job))
}

fn recover_job(job: Job, now: Timestamp) -> TransactionProgram(Option(Job)) {
  let recovered_job =
    job_model.timed_out(job, add_seconds(now, backoff_seconds(job)), now)
  use _ <- transaction_program.and_then(job_effect.update_job_tx(recovered_job))
  transaction_program.succeed(option.Some(recovered_job))
}

fn complete_job(job: Job) -> Program(Nil) {
  use now <- program.and_then(basic_effect.system_time())
  let completed_job = job_model.done(job, now)
  job_effect.update_job(completed_job)
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
  job_effect.update_job(rescheduled_job)
}

fn handle_failed_job(job: Job, err: Error) -> Program(Nil) {
  case error.retryable(err) {
    True -> reschedule_job(job, err)
    False -> fail_job(job, err)
  }
}

fn fail_job(job: Job, err: Error) -> Program(Nil) {
  use now <- program.and_then(basic_effect.system_time())
  let failed_job = job_model.fail(job, option.Some(error.to_string(err)), now)
  job_effect.update_job(failed_job)
}

fn backoff_seconds(job: Job) -> Int {
  let exponent = case job.attempts <= 1 {
    True -> 0
    False -> job.attempts - 1
  }
  let multiplier = power_of_two(exponent)
  let candidate = job.base_backoff_seconds * multiplier

  case candidate < job.max_backoff_seconds {
    True -> candidate
    False -> job.max_backoff_seconds
  }
}

fn power_of_two(exponent: Int) -> Int {
  case exponent <= 0 {
    True -> 1
    False -> 2 * power_of_two(exponent - 1)
  }
}

fn add_seconds(ts: Timestamp, seconds_to_add: Int) -> Timestamp {
  let #(seconds, nanos) = timestamp.to_unix_seconds_and_nanoseconds(ts)
  timestamp.from_unix_seconds_and_nanoseconds(seconds + seconds_to_add, nanos)
}

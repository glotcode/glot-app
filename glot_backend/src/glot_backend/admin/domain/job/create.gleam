import gleam/dynamic.{type Dynamic}
import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_backend/auth/domain/session/current as current_session
import glot_backend/job/domain/type_policy as job_type_policy_domain
import glot_backend/job/effect/job/effect as job_effect
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/system/effect/basic/basic_effect
import glot_backend/system/effect/error.{type Error}
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/admin/job_dto.{type CreateJobRequest, type GetJobResponse}
import glot_core/admin_action
import glot_core/api_action
import glot_core/job/job_model.{type Job, type JobType, type JobTypePolicy}
import glot_core/validation_error
import youid/uuid.{type Uuid}

pub fn create_job(
  request_ctx: RequestContext,
  request: CreateJobRequest,
) -> Program(GetJobResponse) {
  let ctx = request_ctx.context

  use session <- program.and_then(current_session.require_session(request_ctx))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.admin(admin_action.CreateAdminJobAction),
    actor: api_action_policy.actor_from_user(option.Some(session.user)),
  ))
  use job_type <- program.and_then(
    validate_request(request)
    |> program.from_result(),
  )
  use job_id <- program.and_then(basic_effect.uuid_v7())
  use job_type_policy <- program.and_then(
    job_type_policy_domain.require_job_type_policy(job_type),
  )

  let job =
    new_job(
      request: request,
      job_type: job_type,
      job_type_policy: job_type_policy,
      job_id: job_id,
      request_id: ctx.request_id,
      now: ctx.timestamp,
    )

  use _ <- program.and_then(job_effect.create_job(job))
  use _ <- program.and_then(user_action_effect.create_user_action(user_action))

  program.succeed(job_dto.from_job_detail(job, ctx.timestamp))
}

pub fn request_from_dynamic(data: Dynamic) -> Program(CreateJobRequest) {
  program.decode_dynamic(data, job_dto.create_request_decoder())
}

fn validate_request(request: CreateJobRequest) -> Result(JobType, Error) {
  case request.max_attempts > 0 {
    False ->
      Error(
        error.validation(validation_error.MustBeGreaterThan("max_attempts", 0)),
      )
    True ->
      case request.timeout_seconds > 0 {
        False ->
          Error(
            error.validation(validation_error.MustBeGreaterThan(
              "timeout_seconds",
              0,
            )),
          )
        True ->
          case job_model.job_type_from_string(request.job_type) {
            Ok(job_type) -> Ok(job_type)
            Error(err) -> Error(error.validation(err))
          }
      }
  }
}

fn new_job(
  request request: CreateJobRequest,
  job_type job_type: JobType,
  job_type_policy job_type_policy: JobTypePolicy,
  job_id job_id: Uuid,
  request_id request_id: Uuid,
  now now: Timestamp,
) -> Job {
  job_model.Job(
    id: job_id,
    request_id: option.Some(request_id),
    periodic_job_id: request.periodic_job_id,
    job_type: job_type,
    queue: job_type_policy.queue,
    dedupe_key: option.None,
    payload: request.payload,
    status: job_model.Pending,
    attempts: 0,
    max_attempts: request.max_attempts,
    timeout_seconds: request.timeout_seconds,
    base_backoff_seconds: job_type_policy.base_backoff_seconds,
    max_backoff_seconds: job_type_policy.max_backoff_seconds,
    run_at: request.run_at,
    started_at: option.None,
    lease_expires_at: option.None,
    completed_at: option.None,
    timed_out_at: option.None,
    last_error: option.None,
    created_at: now,
    updated_at: now,
  )
}

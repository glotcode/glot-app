import gleam/dynamic.{type Dynamic}
import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_backend/auth/domain/session/current as current_session
import glot_backend/job/effect/type_policy/effect as job_type_policy_effect
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/system/effect/error
import glot_backend/system/effect/error/resource_error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/admin/job_type_policy_dto.{
  type JobTypePolicyResponse, type UpsertJobTypePolicyRequest,
}
import glot_core/admin_action
import glot_core/api_action
import glot_core/job/job_model.{type JobTypePolicy}
import glot_core/validation_error

pub fn upsert_job_type_policy(
  request_ctx: RequestContext,
  request: UpsertJobTypePolicyRequest,
) -> Program(JobTypePolicyResponse) {
  let ctx = request_ctx.context

  use session <- program.and_then(current_session.require_session(request_ctx))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.admin(admin_action.UpsertAdminJobTypePolicyAction),
    actor: api_action_policy.actor_from_user(option.Some(session.user)),
  ))
  use policy <- program.and_then(policy_from_request(request, ctx.timestamp))
  use _ <- program.and_then(validate_policy(policy))
  use _ <- program.and_then(job_type_policy_effect.upsert_job_type_policy(
    policy,
    ctx.timestamp,
  ))
  use saved_policy <- program.and_then(
    job_type_policy_effect.get_job_type_policy_by_job_type(policy.job_type)
    |> program.require(error.resource(resource_error.JobTypePolicyNotFound)),
  )
  use _ <- program.and_then(user_action_effect.create_user_action(user_action))

  program.succeed(job_type_policy_dto.from_job_type_policy(saved_policy))
}

pub fn request_from_dynamic(
  data: Dynamic,
) -> Program(UpsertJobTypePolicyRequest) {
  program.decode_dynamic(data, job_type_policy_dto.request_decoder())
}

fn policy_from_request(
  request: UpsertJobTypePolicyRequest,
  now: Timestamp,
) -> Program(JobTypePolicy) {
  case job_model.job_type_from_string(request.job_type) {
    Error(err) -> program.fail(error.validation(err))
    Ok(job_type) ->
      case job_model.queue_from_string(request.queue_name) {
        Error(_) ->
          program.fail(
            error.validation(validation_error.InvalidJobQueue(
              request.queue_name,
            )),
          )
        Ok(queue) ->
          program.succeed(job_model.JobTypePolicy(
            job_type: job_type,
            queue: queue,
            max_attempts: request.max_attempts,
            timeout_seconds: request.timeout_seconds,
            base_backoff_seconds: request.base_backoff_seconds,
            max_backoff_seconds: request.max_backoff_seconds,
            created_at: now,
            updated_at: now,
          ))
      }
  }
}

fn validate_policy(policy: JobTypePolicy) -> Program(Nil) {
  use _ <- program.and_then(require_positive(
    policy.max_attempts,
    "max_attempts",
  ))
  use _ <- program.and_then(require_positive(
    policy.timeout_seconds,
    "timeout_seconds",
  ))
  use _ <- program.and_then(require_positive(
    policy.base_backoff_seconds,
    "base_backoff_seconds",
  ))
  use _ <- program.and_then(require_positive(
    policy.max_backoff_seconds,
    "max_backoff_seconds",
  ))
  use _ <- program.and_then(require_gte_field(
    policy.max_backoff_seconds,
    "max_backoff_seconds",
    policy.base_backoff_seconds,
    "base_backoff_seconds",
  ))

  program.succeed(Nil)
}

fn require_positive(value: Int, field: String) -> Program(Nil) {
  case value > 0 {
    True -> program.succeed(Nil)
    False ->
      program.fail(
        error.validation(validation_error.MustBeGreaterThan(field, 0)),
      )
  }
}

fn require_gte_field(
  value: Int,
  field: String,
  other_value: Int,
  other_field: String,
) -> Program(Nil) {
  case value >= other_value {
    True -> program.succeed(Nil)
    False ->
      program.fail(
        error.validation(validation_error.MustBeGreaterThanOrEqualField(
          field,
          other_field,
        )),
      )
  }
}

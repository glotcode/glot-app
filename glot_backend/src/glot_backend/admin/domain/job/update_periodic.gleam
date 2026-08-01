import gleam/dynamic.{type Dynamic}
import gleam/option
import glot_backend/auth/domain/session/current as current_session
import glot_backend/job/effect/periodic/effect as periodic_job_effect
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/system/effect/error
import glot_backend/system/effect/error/resource_error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/admin/periodic_job_dto.{
  type UpdatePeriodicJobRequest, type UpdatePeriodicJobResponse,
}
import glot_core/admin_action
import glot_core/api_action
import glot_core/periodic_job/periodic_job_model
import glot_core/validation_error

pub fn update_periodic_job(
  request_ctx: RequestContext,
  request: UpdatePeriodicJobRequest,
) -> Program(UpdatePeriodicJobResponse) {
  let ctx = request_ctx.context

  use session <- program.and_then(current_session.require_session(request_ctx))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.admin(admin_action.UpdateAdminPeriodicJobAction),
    actor: api_action_policy.actor_from_user(option.Some(session.user)),
  ))
  use _ <- program.and_then(validate_request(request))
  use periodic_job <- program.and_then(
    periodic_job_effect.get_periodic_job_by_id(request.id)
    |> program.require(error.resource(resource_error.PeriodicJobNotFound)),
  )

  let updated_periodic_job =
    periodic_job_model.PeriodicJob(
      ..periodic_job,
      payload: request.payload,
      interval_seconds: request.interval_seconds,
      enabled: request.enabled,
      next_run_at: request.next_run_at,
      updated_at: ctx.timestamp,
    )

  use _ <- program.and_then(periodic_job_effect.update_periodic_job(
    updated_periodic_job,
  ))
  use _ <- program.and_then(user_action_effect.create_user_action(user_action))

  program.succeed(periodic_job_dto.from_updated_periodic_job(
    updated_periodic_job,
  ))
}

pub fn request_from_dynamic(
  data: Dynamic,
) -> Program(UpdatePeriodicJobRequest) {
  program.decode_dynamic(data, periodic_job_dto.update_request_decoder())
}

fn validate_request(request: UpdatePeriodicJobRequest) -> Program(Nil) {
  case request.interval_seconds <= 0 {
    True ->
      program.fail(
        error.validation(validation_error.MustBeGreaterThan(
          "interval_seconds",
          0,
        )),
      )
    False -> program.succeed(Nil)
  }
}

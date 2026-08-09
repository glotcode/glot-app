import gleam/dynamic.{type Dynamic}
import gleam/option
import gleam/time/calendar
import gleam/time/duration
import gleam/time/timestamp
import glot_backend/analytics/effect/effect as analytics_effect
import glot_backend/auth/domain/session/current as current_session
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/system/effect/error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/admin/analytics_dto.{
  type AnalyticsResponse, type GetAnalyticsRequest,
}
import glot_core/admin_action
import glot_core/api_action
import glot_core/validation_error

const max_days = 366

pub fn get_analytics(
  request_ctx: RequestContext,
  request: GetAnalyticsRequest,
) -> Program(AnalyticsResponse) {
  use _ <- program.and_then(validate_days(request.days))
  use session <- program.and_then(current_session.require_session(request_ctx))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.admin(admin_action.GetAdminAnalyticsAction),
    actor: api_action_policy.actor_from_user(option.Some(session.user)),
  ))

  let #(end_day, _) =
    timestamp.to_calendar(request_ctx.context.timestamp, calendar.utc_offset)
  let #(start_day, _) =
    request_ctx.context.timestamp
    |> timestamp.subtract(duration.seconds(request.days * 86_400))
    |> timestamp.to_calendar(calendar.utc_offset)

  use metrics <- program.and_then(analytics_effect.get_analytics(
    request.days,
    start_day,
    end_day,
  ))
  use _ <- program.and_then(user_action_effect.create_user_action(user_action))
  program.succeed(metrics)
}

pub fn request_from_dynamic(data: Dynamic) -> Program(GetAnalyticsRequest) {
  program.decode_dynamic(data, analytics_dto.request_decoder())
}

fn validate_days(days: Int) -> Program(Nil) {
  case days {
    days if days <= 0 ->
      program.fail(
        error.validation(validation_error.MustBeGreaterThan("days", 0)),
      )
    days if days > max_days ->
      program.fail(
        error.validation(validation_error.MustBeLessThanOrEqual(
          "days",
          max_days,
        )),
      )
    _ -> program.succeed(Nil)
  }
}

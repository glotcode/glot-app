import gleam/option.{type Option}
import glot_backend/auth/domain/session/current as current_session
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/system/effect/basic/basic_effect
import glot_backend/system/effect/log
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/api_action
import glot_core/auth/session_dto.{type SessionResponse}
import glot_core/public_action

pub fn get_session(
  request_ctx: RequestContext,
) -> Program(Option(SessionResponse)) {
  use maybe_session <- program.and_then(current_session.get_session(request_ctx))
  let maybe_session_id =
    option.map(maybe_session, fn(session) { session.identity.id })
  let maybe_user_id =
    option.map(maybe_session, fn(session) { session.user.identity.id })

  use _ <- program.and_then(
    basic_effect.info(
      log.from_list([
        log.optional_uuid("session_id", maybe_session_id),
        log.optional_uuid("user_id", maybe_user_id),
      ]),
    ),
  )

  let actor =
    maybe_session
    |> option.map(fn(session) { session.user })
    |> api_action_policy.actor_from_user

  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.public(public_action.GetSessionAction),
    actor: actor,
  ))
  use _ <- program.and_then(user_action_effect.create_user_action(user_action))

  maybe_session
  |> option.map(session_dto.from_session)
  |> program.succeed
}

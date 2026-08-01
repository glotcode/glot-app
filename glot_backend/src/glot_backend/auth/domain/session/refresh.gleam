import gleam/int
import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/auth/domain/session/current as current_session
import glot_backend/auth/effect/session as session_effect
import glot_backend/auth/error as auth_error
import glot_backend/auth/model/config.{type AuthConfig}
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/system/crypto/token
import glot_backend/system/effect/basic/basic_effect
import glot_backend/system/effect/error
import glot_backend/system/effect/log
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{
  type Program, type TransactionProgram,
}
import glot_backend/system/effect/transaction/transaction_effect
import glot_backend/system/effect/transaction/transaction_program
import glot_backend/system/request/context.{type Context}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/api_action
import glot_core/auth/refresh_session_dto.{type RefreshSessionResponse}
import glot_core/auth/session_model.{type Session}
import glot_core/helpers/timestamp_helpers
import glot_core/public_action
import glot_core/user_action.{type UserAction}

pub type RefreshSessionResult {
  RefreshSessionResult(
    session_token: String,
    session_cookie_max_age: Int,
    response: RefreshSessionResponse,
  )
}

pub fn refresh_session(
  request_ctx: RequestContext,
) -> Program(RefreshSessionResult) {
  let ctx = request_ctx.context
  let config = request_ctx.dynamic_config

  use session <- program.and_then(current_session.require_session(request_ctx))

  use _ <- program.and_then(
    basic_effect.info(
      log.from_list([
        log.uuid("session_id", session.identity.id),
        log.uuid("user_id", session.user.identity.id),
      ]),
    ),
  )

  let auth_config = dynamic_config.auth_config(config)

  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.public(public_action.RefreshSessionAction),
    actor: api_action_policy.KnownUser(
      user_id: session.user.identity.id,
      account_state: session.user.account.identity.account_state,
      account_tier: session.user.account.identity.account_tier,
      role: session.user.identity.role,
    ),
  ))

  use session_token <- program.and_then(basic_effect.new_token(
    32,
    token.AlphaNumeric,
  ))

  use rotation_outcome <- program.and_then(
    transaction_effect.run(refresh_session_tx(
      ctx,
      session_token,
      user_action,
      auth_config,
    )),
  )

  use _ <- program.and_then(
    basic_effect.info(
      log.from_list([
        log.uuid("session_id", session.identity.id),
        log.uuid("user_id", session.user.identity.id),
        log.bool("token_rotated", rotation_outcome.rotated),
        log.int(
          "next_heartbeat_in_seconds",
          rotation_outcome.next_heartbeat_in_seconds,
        ),
      ]),
    ),
  )

  program.succeed(RefreshSessionResult(
    session_token: rotation_outcome.session_token,
    session_cookie_max_age: auth_config.session_cookie_max_age,
    response: refresh_session_dto.RefreshSessionResponse(
      next_heartbeat_in_seconds: rotation_outcome.next_heartbeat_in_seconds,
    ),
  ))
}

type RotationOutcome {
  RotationOutcome(
    rotated: Bool,
    session_token: String,
    next_heartbeat_in_seconds: Int,
  )
}

type PreparedRotation {
  PreparedRotation(session: Session, outcome: RotationOutcome)
}

fn refresh_session_tx(
  ctx: Context,
  session_token: String,
  user_action: UserAction,
  auth_config: AuthConfig,
) -> TransactionProgram(RotationOutcome) {
  use token <- transaction_program.and_then(transaction_program.from_option(
    ctx.client_info.session_token,
    error.auth(auth_error.MissingSessionToken),
  ))
  use session <- transaction_program.and_then(
    get_session_by_client_token_for_update(token, ctx.timestamp),
  )

  let prepared = prepare_rotation(session, session_token, ctx, auth_config)

  transaction_program.sequence([
    session_effect.update_session_tx(prepared.session),
    user_action_effect.create_user_action_tx(user_action),
  ])
  |> transaction_program.map(fn(_) { prepared.outcome })
}

fn prepare_rotation(
  session: Session,
  session_token: String,
  ctx: Context,
  auth_config: AuthConfig,
) -> PreparedRotation {
  let token_rotated =
    should_rotate_session_token(
      session,
      ctx.timestamp,
      auth_config.session_refresh_interval_seconds,
    )

  let next_session = case token_rotated {
    True ->
      session
      |> session_model.rotate_token(
        session_token,
        ctx.timestamp,
        timestamp_helpers.add_seconds(
          ctx.timestamp,
          auth_config.session_previous_token_grace_seconds,
        ),
      )
    False -> session_model.touch(session, ctx.timestamp)
  }

  PreparedRotation(
    session: next_session,
    outcome: RotationOutcome(
      rotated: token_rotated,
      session_token: next_session.token,
      next_heartbeat_in_seconds: next_heartbeat_in_seconds(
        next_session,
        ctx.timestamp,
        auth_config,
      ),
    ),
  )
}

fn get_session_by_client_token_for_update(
  token: String,
  now: Timestamp,
) -> TransactionProgram(Session) {
  use maybe_session <- transaction_program.and_then(
    session_effect.get_session_by_token_for_update_tx(token),
  )
  case maybe_session {
    option.Some(session) -> transaction_program.succeed(session)
    option.None -> get_valid_previous_session_for_update(token, now)
  }
}

fn get_valid_previous_session_for_update(
  token: String,
  now: Timestamp,
) -> TransactionProgram(Session) {
  use session <- transaction_program.and_then(transaction_program.require(
    session_effect.get_session_by_previous_token_for_update_tx(token),
    error.auth(auth_error.SessionNotFound),
  ))
  use _ <- transaction_program.and_then(
    transaction_program.from_result(current_session.validate_previous_token(
      session,
      now,
    )),
  )
  transaction_program.succeed(session)
}

fn should_rotate_session_token(
  session: Session,
  now: Timestamp,
  session_refresh_interval_seconds: Int,
) -> Bool {
  elapsed_seconds(session.token_updated_at, now)
  >= session_refresh_interval_seconds
}

fn elapsed_seconds(from: Timestamp, to: Timestamp) -> Int {
  let #(from_seconds, _) = timestamp.to_unix_seconds_and_nanoseconds(from)
  let #(to_seconds, _) = timestamp.to_unix_seconds_and_nanoseconds(to)
  int.absolute_value(to_seconds - from_seconds)
}

fn next_heartbeat_in_seconds(
  session: Session,
  now: Timestamp,
  auth_config: AuthConfig,
) -> Int {
  let remaining =
    remaining_seconds_until_rotation(
      session.token_updated_at,
      now,
      auth_config.session_refresh_interval_seconds,
    )

  case remaining <= 0 {
    True -> auth_config.session_heartbeat_interval_seconds
    False -> min_int(auth_config.session_heartbeat_interval_seconds, remaining)
  }
}

fn remaining_seconds_until_rotation(
  session_token_updated_at: Timestamp,
  now: Timestamp,
  session_refresh_interval_seconds: Int,
) -> Int {
  session_refresh_interval_seconds
  - elapsed_seconds(session_token_updated_at, now)
}

fn min_int(a: Int, b: Int) -> Int {
  case a <= b {
    True -> a
    False -> b
  }
}

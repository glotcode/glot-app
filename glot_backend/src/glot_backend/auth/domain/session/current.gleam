import gleam/option.{type Option}
import gleam/result
import gleam/time/timestamp.{type Timestamp}
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/auth/effect/session as session_effect
import glot_backend/auth/error as auth_error
import glot_backend/auth/model/config.{type AuthConfig}
import glot_backend/system/effect/error.{type Error}
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/context.{type Context}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_core/auth/session_model.{type HydratedSession, type Session}

pub fn get_session(
  request_ctx: RequestContext,
) -> Program(Option(HydratedSession)) {
  get_validated_session(
    request_ctx.context,
    dynamic_config.auth_config(request_ctx.dynamic_config),
  )
  |> program.map(option.from_result)
}

pub fn require_session(
  request_ctx: RequestContext,
) -> Program(HydratedSession) {
  get_validated_session(
    request_ctx.context,
    dynamic_config.auth_config(request_ctx.dynamic_config),
  )
  |> program.and_then(program.from_result)
}

fn get_validated_session(
  ctx: Context,
  auth_config: AuthConfig,
) -> Program(Result(HydratedSession, Error)) {
  use session_result <- program.and_then(get_session_from_context(ctx))

  session_result
  |> result.try(validate_session(
    _,
    ctx.timestamp,
    auth_config.session_token_max_age,
    auth_config.session_idle_timeout_seconds,
  ))
  |> program.succeed
}

fn get_session_from_context(
  ctx: Context,
) -> Program(Result(HydratedSession, Error)) {
  case ctx.client_info.session_token {
    option.Some(token) -> get_session_by_client_token(ctx.timestamp, token)
    option.None ->
      program.succeed(Error(error.auth(auth_error.MissingSessionToken)))
  }
}

fn get_session_by_client_token(
  now: Timestamp,
  token: String,
) -> Program(Result(HydratedSession, Error)) {
  use maybe_session <- program.and_then(session_effect.get_session_by_token(
    token,
  ))
  case maybe_session {
    option.Some(session) -> program.succeed(Ok(session))
    option.None ->
      session_effect.get_session_by_previous_token(token)
      |> program.map(result_from_previous_token(_, now))
  }
}

fn validate_session(
  session: HydratedSession,
  now: Timestamp,
  session_max_lifetime: Int,
  session_idle_timeout_seconds: Int,
) -> Result(HydratedSession, Error) {
  let expired =
    is_expired(session.identity.created_at, now, session_max_lifetime)
    || is_expired(
      session.identity.last_activity_at,
      now,
      session_idle_timeout_seconds,
    )

  case expired {
    True -> Error(error.auth(auth_error.SessionExpired))
    False -> Ok(session)
  }
}

fn result_from_previous_token(
  maybe_session: Option(HydratedSession),
  now: Timestamp,
) -> Result(HydratedSession, Error) {
  use session <- result.try(option.to_result(
    maybe_session,
    error.auth(auth_error.SessionNotFound),
  ))
  use _ <- result.try(validate_previous_token(session.identity, now))
  Ok(session)
}

pub fn validate_previous_token(
  session: Session,
  now: Timestamp,
) -> Result(Nil, Error) {
  use valid_until <- result.try(option.to_result(
    session.previous_token_valid_until,
    error.auth(auth_error.SessionNotFound),
  ))
  case timestamp_is_on_or_before(now, valid_until) {
    True -> Ok(Nil)
    False -> Error(error.auth(auth_error.SessionNotFound))
  }
}

fn is_expired(created_at: Timestamp, now: Timestamp, max_age: Int) -> Bool {
  let #(created_seconds, _) =
    timestamp.to_unix_seconds_and_nanoseconds(created_at)
  let #(now_seconds, _) = timestamp.to_unix_seconds_and_nanoseconds(now)

  now_seconds >= created_seconds && now_seconds - created_seconds > max_age
}

fn timestamp_is_on_or_before(left: Timestamp, right: Timestamp) -> Bool {
  let #(left_seconds, left_nanos) =
    timestamp.to_unix_seconds_and_nanoseconds(left)
  let #(right_seconds, right_nanos) =
    timestamp.to_unix_seconds_and_nanoseconds(right)

  left_seconds < right_seconds
  || { left_seconds == right_seconds && left_nanos <= right_nanos }
}

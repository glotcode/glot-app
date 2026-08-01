import gleam/option
import glot_backend/auth/model/browser_info
import glot_backend/system/crypto/token
import glot_backend/system/effect/basic/basic_effect
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/context.{type Context}
import glot_core/auth/session_model.{type Session}
import youid/uuid.{type Uuid}

pub type SessionIssueResult {
  SessionIssueResult(session_token: String, session_cookie_max_age: Int)
}

pub type SessionIssue {
  SessionIssue(session: Session, session_token: String)
}

pub fn issue_session_for_user(
  ctx: Context,
  user_id: Uuid,
) -> Program(SessionIssue) {
  use session_id <- program.and_then(basic_effect.uuid_v7())
  use session_token <- program.and_then(basic_effect.new_token(
    32,
    token.AlphaNumeric,
  ))
  let browser_info = browser_info.from_user_agent(ctx.client_info.user_agent)

  let session =
    session_model.Session(
      id: session_id,
      user_id: user_id,
      token: session_token,
      previous_token: option.None,
      previous_token_valid_until: option.None,
      ip: ctx.client_info.ip,
      os_name: browser_info.os_name,
      browser_name: browser_info.browser_name,
      user_agent: ctx.client_info.user_agent,
      created_at: ctx.timestamp,
      token_updated_at: ctx.timestamp,
      last_activity_at: ctx.timestamp,
    )

  program.succeed(SessionIssue(session: session, session_token: session_token))
}

import glot_backend/app_config/domain/retention
import glot_backend/auth/effect/login_token as login_token_effect
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/context.{type Context}

pub fn clean_login_tokens(ctx: Context) -> Program(Nil) {
  use cutoff <- program.and_then(retention.cutoff(
    ctx.timestamp,
    retention.LoginTokens,
  ))
  login_token_effect.delete_login_tokens_before(cutoff)
}

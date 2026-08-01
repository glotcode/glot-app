import glot_backend/app_config/domain/retention
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/context.{type Context}
import glot_backend/user_action/effect/effect as user_action_effect

pub fn clean_user_actions(ctx: Context) -> Program(Nil) {
  use cutoff <- program.and_then(retention.cutoff(
    ctx.timestamp,
    retention.UserActions,
  ))
  user_action_effect.delete_before(cutoff)
}

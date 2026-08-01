import glot_backend/app_config/domain/retention
import glot_backend/logging/run_log/effect/effect as run_log_effect
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/context.{type Context}

pub fn clean_run_log(ctx: Context) -> Program(Nil) {
  use cutoff <- program.and_then(retention.cutoff(
    ctx.timestamp,
    retention.RunLog,
  ))
  run_log_effect.delete_before(cutoff)
}

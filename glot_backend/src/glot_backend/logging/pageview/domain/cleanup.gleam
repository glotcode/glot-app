import glot_backend/app_config/domain/retention
import glot_backend/logging/pageview/effect/effect as pageview_log_effect
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/context.{type Context}

pub fn clean_pageview_log(ctx: Context) -> Program(Nil) {
  use cutoff <- program.and_then(retention.cutoff(
    ctx.timestamp,
    retention.PageviewLog,
  ))
  pageview_log_effect.delete_before(cutoff)
}

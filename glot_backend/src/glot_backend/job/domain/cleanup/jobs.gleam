import glot_backend/app_config/domain/retention
import glot_backend/job/effect/job/effect as job_effect
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/context.{type Context}
import glot_core/job/job_model

pub fn clean_jobs(ctx: Context) -> Program(Nil) {
  use cutoff <- program.and_then(retention.cutoff(ctx.timestamp, retention.Jobs))
  job_effect.delete_before(cutoff, [job_model.Done])
}

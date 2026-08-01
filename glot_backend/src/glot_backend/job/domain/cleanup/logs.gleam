import glot_backend/app_config/domain/retention
import glot_backend/job/effect/log/effect as job_log_effect
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/context.{type Context}

pub fn clean_job_log(ctx: Context) -> Program(Nil) {
  use cutoff <- program.and_then(retention.cutoff(
    ctx.timestamp,
    retention.JobLog,
  ))
  job_log_effect.delete_before(cutoff)
}

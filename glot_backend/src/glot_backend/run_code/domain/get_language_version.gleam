import gleam/dynamic.{type Dynamic}
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/run_code/effect/effect as run_code_effect
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_core/run.{type GetLanguageVersionRequest, type RunResult}

pub fn get_language_version(
  request_ctx: RequestContext,
  request: GetLanguageVersionRequest,
) -> Program(RunResult) {
  let config = request_ctx.dynamic_config

  run_code_effect.get_language_version(
    dynamic_config.docker_run_config(config),
    request.language,
  )
}

pub fn request_from_dynamic(
  data: Dynamic,
) -> Program(GetLanguageVersionRequest) {
  program.decode_dynamic(data, run.get_language_version_request_decoder())
}

import gleam/option
import glot_backend/run_code/effect/algebra
import glot_backend/run_code/model/config.{type DockerRunConfig}
import glot_backend/run_code/ports/language_version_cache.{
  type LanguageVersionCache,
}
import glot_backend/run_code/ports/runner.{type Runner}
import glot_backend/system/effect/effect_trace
import glot_backend/system/effect/error/run_request_error
import glot_backend/system/effect/measured_interpreter
import glot_backend/system/effect/program_state
import glot_backend/system/effect/program_types
import glot_backend/system/request/context
import glot_core/language
import glot_core/run
import wisp

pub fn run(
  effect: algebra.RunCodeEffect(program_types.Program(a)),
  cache: option.Option(LanguageVersionCache),
  runner: Runner,
  ctx: context.Context,
  state: program_state.State,
  continue: fn(program_types.Program(a), program_state.State) ->
    #(b, program_state.State),
) -> #(b, program_state.State) {
  case effect {
    algebra.RunCode(config, request, next) ->
      measured_interpreter.run(
        fn() { run_with_runner(config, request, runner, ctx) },
        next,
        name: effect_trace.RunCodeEffectName(algebra.RunCodeEffectName),
        kind: effect_trace.DockerCallEffect,
        state: state,
        continue: continue,
      )
    algebra.GetLanguageVersion(config, requested_language, next) ->
      measured_interpreter.run_with_kind(
        fn() {
          case cache {
            option.Some(port) -> {
              let #(result, outcome) = port.lookup(requested_language)
              #(result, effect_trace.CacheReadEffect(outcome))
            }
            option.None -> #(
              run_with_runner(
                config,
                language_version_request(requested_language),
                runner,
                ctx,
              ),
              effect_trace.DockerCallEffect,
            )
          }
        },
        next,
        name: effect_trace.RunCodeEffectName(
          algebra.GetLanguageVersionEffectName,
        ),
        state: state,
        continue: continue,
      )
  }
}

fn run_with_runner(
  config: option.Option(DockerRunConfig),
  request: run.RunRequest,
  runner: Runner,
  ctx: context.Context,
) -> Result(run.RunResult, run_request_error.RunRequestError) {
  case config {
    option.Some(docker_run) ->
      runner.run(
        docker_run,
        request,
        option.unwrap(
          context.remaining_timeout_ms(ctx),
          docker_run.default_timeout_ms,
        ),
      )
    option.None -> {
      wisp.log_error("Missing docker_run app_config")
      Error(run_request_error.ServerRunRequestError)
    }
  }
}

fn language_version_request(language: language.Language) -> run.RunRequest {
  run.RunRequest(
    image: language.container_image(language),
    payload: run.RunRequestPayload(
      run_instructions: language.version_run_instructions(language),
      files: [],
      stdin: option.None,
    ),
  )
}

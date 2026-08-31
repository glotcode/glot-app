import gleam/int
import gleam/option
import glot_backend/spam_classifier/effect/algebra
import glot_backend/spam_classifier/ports/client.{type Client}
import glot_backend/system/effect/effect_trace
import glot_backend/system/effect/error
import glot_backend/system/effect/measured_interpreter
import glot_backend/system/effect/program_state
import glot_backend/system/effect/program_types
import glot_backend/system/request/context.{type Context}

const service_timeout_ms = 3_330_000

pub fn run(
  effect: algebra.Effect(program_types.Program(a)),
  client: Client,
  ctx: Context,
  state: program_state.State,
  continue: fn(program_types.Program(a), program_state.State) ->
    #(Result(a, error.Error), program_state.State),
) -> #(Result(a, error.Error), program_state.State) {
  case effect {
    algebra.Classify(config, request, next) ->
      measured_interpreter.run(
        fn() {
          client.classify(
            config,
            request,
            context.remaining_timeout_ms(ctx)
              |> option.map(fn(remaining) {
                int.min(remaining, service_timeout_ms)
              })
              |> option.unwrap(service_timeout_ms),
          )
        },
        next,
        name: effect_trace.SpamClassifierEffectName(
          algebra.ClassifySnippetEffectName,
        ),
        kind: effect_trace.SpamClassifierCallEffect,
        state: state,
        continue: continue,
      )
  }
}

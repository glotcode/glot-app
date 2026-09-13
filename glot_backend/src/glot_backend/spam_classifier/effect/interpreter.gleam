import glot_backend/spam_classifier/effect/algebra
import glot_backend/spam_classifier/effect/classification
import glot_backend/spam_classifier/effect/indexing
import glot_backend/spam_classifier/ports.{type Ports}
import glot_backend/system/effect/effect_trace
import glot_backend/system/effect/error
import glot_backend/system/effect/measured_interpreter
import glot_backend/system/effect/program_state
import glot_backend/system/effect/program_types
import glot_backend/system/request/context.{type Context}

pub fn run(
  effect: algebra.Effect(program_types.Program(a)),
  ports: Ports,
  ctx: Context,
  state: program_state.State,
  continue: fn(program_types.Program(a), program_state.State) ->
    #(Result(a, error.Error), program_state.State),
) -> #(Result(a, error.Error), program_state.State) {
  case effect {
    algebra.IndexBatch(next) ->
      measured_interpreter.run(
        fn() { indexing.run(ports.storage) },
        next,
        name: effect_trace.SpamClassifierEffectName(
          algebra.IndexBatchEffectName,
        ),
        kind: effect_trace.SpamClassifierCallEffect,
        state: state,
        continue: continue,
      )
    algebra.Classify(config, request, next) ->
      measured_interpreter.run(
        fn() { classification.run(config, request, ports, ctx) },
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

import gleam/list
import glot_backend/app_config/effect/interpreter as app_config_interpreter
import glot_backend/auth/passkey/effect/interpreter as webauthn_interpreter
import glot_backend/email/effect/delivery/interpreter as email_interpreter
import glot_backend/run_code/effect/interpreter as run_code_interpreter
import glot_backend/spam_classifier/effect/interpreter as spam_classifier_interpreter
import glot_backend/system/effect/basic/basic_interpreter
import glot_backend/system/effect/database_ports
import glot_backend/system/effect/db_interpreter
import glot_backend/system/effect/error
import glot_backend/system/effect/program_state
import glot_backend/system/effect/program_types
import glot_backend/system/effect/runtime
import glot_backend/system/effect/transaction/transaction_interpreter
import glot_backend/system/request/context

pub fn run(
  effect: program_types.Program(a),
  runtime: runtime.Runtime,
  ctx: context.Context,
) -> #(Result(a, error.Error), program_state.State) {
  let #(result, state) =
    run_with_state(effect, runtime, ctx, program_state.new_state())
  #(
    result,
    program_state.State(
      ..state,
      effect_measurements: list.reverse(state.effect_measurements),
    ),
  )
}

pub fn run_with_state(
  effect: program_types.Program(a),
  runtime: runtime.Runtime,
  ctx: context.Context,
  state: program_state.State,
) -> #(Result(a, error.Error), program_state.State) {
  let continue = fn(next_effect, next_state) {
    run_with_state(next_effect, runtime, ctx, next_state)
  }

  case effect {
    program_types.Pure(value) -> #(Ok(value), state)
    program_types.Fail(error) -> #(Error(error), state)
    program_types.Impure(effect) ->
      run_effect(effect, runtime, ctx, state, continue)
    program_types.Attempt(program:, on_error:) ->
      case run_with_state(program, runtime, ctx, state) {
        #(Ok(value), next_state) -> #(Ok(value), next_state)
        #(Error(err), next_state) ->
          run_with_state(on_error(err), runtime, ctx, next_state)
      }
  }
}

fn run_effect(
  effect: program_types.Effect(program_types.Program(a)),
  runtime: runtime.Runtime,
  ctx: context.Context,
  state: program_state.State,
  continue: fn(program_types.Program(a), program_state.State) ->
    #(Result(a, error.Error), program_state.State),
) -> #(Result(a, error.Error), program_state.State) {
  let effect_runtime =
    runtime.with_timeout(runtime, context.remaining_timeout_ms(ctx))

  case effect {
    program_types.AppConfigEffect(effect) ->
      app_config_interpreter.run(
        effect,
        database_ports.app_config(effect_runtime.services.database),
        effect_runtime.services.caches.app_config_cache,
        state,
        continue,
      )
    program_types.BasicEffect(effect) ->
      basic_interpreter.run(effect, ctx, effect_runtime, state, continue)
    program_types.EmailEffect(effect) ->
      email_interpreter.run(
        effect,
        ctx,
        effect_runtime.services.system.email,
        effect_runtime.services.caches.app_config_cache,
        database_ports.app_config(effect_runtime.services.database),
        state,
        continue,
      )
    program_types.WebauthnEffect(effect) ->
      webauthn_interpreter.run(
        effect,
        effect_runtime.services.system.passkey,
        state,
        continue,
      )
    program_types.RunCodeEffect(effect) ->
      run_code_interpreter.run(
        effect,
        effect_runtime.services.caches.language_version_cache,
        effect_runtime.services.system.run_code,
        ctx,
        state,
        continue,
      )
    program_types.SpamClassifierEffect(effect) ->
      spam_classifier_interpreter.run(
        effect,
        effect_runtime.services.system.spam_classifier,
        ctx,
        state,
        continue,
      )
    program_types.DbEffect(effect) ->
      db_interpreter.run(
        effect,
        ctx,
        effect_runtime.services.database,
        state,
        continue,
      )
    program_types.TransactionEffect(effect) ->
      transaction_interpreter.run(effect, effect_runtime, ctx, state, continue)
  }
}

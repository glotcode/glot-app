import gleam/option
import gleam/result
import glot_backend/app_config/decoder/config as config_decoder
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/system/effect/basic/basic_algebra
import glot_backend/system/effect/database_ports
import glot_backend/system/effect/effect_trace
import glot_backend/system/effect/error
import glot_backend/system/effect/error/db_error
import glot_backend/system/effect/log
import glot_backend/system/effect/measured_interpreter
import glot_backend/system/effect/program_state
import glot_backend/system/effect/program_types
import glot_backend/system/effect/runtime
import glot_backend/system/request/context

pub fn run(
  effect: basic_algebra.BasicEffect(program_types.Program(a)),
  ctx: context.Context,
  runtime: runtime.Runtime,
  state: program_state.State,
  continue: fn(program_types.Program(a), program_state.State) ->
    #(Result(a, error.Error), program_state.State),
) -> #(Result(a, error.Error), program_state.State) {
  case effect {
    basic_algebra.NewToken(length, alphabet, next) ->
      measured_interpreter.run(
        fn() { runtime.services.system.basic.new_token(length, alphabet) },
        next,
        name: effect_trace.BasicEffectName(basic_algebra.NewTokenEffectName),
        kind: effect_trace.RuntimeEffect,
        state: state,
        continue: continue,
      )
    basic_algebra.SystemTime(next) ->
      measured_interpreter.run(
        runtime.services.system.basic.system_time,
        next,
        name: effect_trace.BasicEffectName(basic_algebra.SystemTimeEffectName),
        kind: effect_trace.RuntimeEffect,
        state: state,
        continue: continue,
      )
    basic_algebra.UuidV7(next) ->
      measured_interpreter.run(
        fn() { runtime.services.system.basic.uuid_v7(ctx.timestamp) },
        next,
        name: effect_trace.BasicEffectName(basic_algebra.UuidV7EffectName),
        kind: effect_trace.RuntimeEffect,
        state: state,
        continue: continue,
      )
    basic_algebra.Log(level, fields, next) -> {
      case level {
        log.Info ->
          measured_interpreter.run_with_state(
            fn(state) { #(next, program_state.add_info_fields(state, fields)) },
            fn(next) { next },
            name: effect_trace.BasicEffectName(basic_algebra.LogEffectName(
              level,
            )),
            kind: effect_trace.LogEffect,
            state: state,
            continue: continue,
          )
        log.Warn ->
          measured_interpreter.run_with_state(
            fn(state) {
              #(next, program_state.add_warning_fields(state, fields))
            },
            fn(next) { next },
            name: effect_trace.BasicEffectName(basic_algebra.LogEffectName(
              level,
            )),
            kind: effect_trace.LogEffect,
            state: state,
            continue: continue,
          )
        log.Debug ->
          case debug_enabled(runtime) {
            True ->
              measured_interpreter.run_with_state(
                fn(state) {
                  #(next, program_state.add_debug_fields(state, fields))
                },
                fn(next) { next },
                name: effect_trace.BasicEffectName(basic_algebra.LogEffectName(
                  level,
                )),
                kind: effect_trace.LogEffect,
                state: state,
                continue: continue,
              )
            False -> continue(next, state)
          }
      }
    }
  }
}

fn debug_enabled(runtime: runtime.Runtime) -> Bool {
  let config_result = case runtime.services.caches.app_config_cache {
    option.Some(port) -> {
      let #(result, _) = port.lookup()
      result
    }
    option.None ->
      database_ports.app_config(runtime.services.database).list_entries()
      |> result.try(fn(entries) {
        config_decoder.from_entries(entries)
        |> result.map_error(db_error.DbQueryError)
      })
  }

  case config_result {
    Ok(config) -> dynamic_config.debug_config(config).enabled
    Error(_) -> False
  }
}

import gleam/option
import gleam/result
import glot_backend/app_config/decoder/config as config_decoder
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/app_config/ports/cache.{type Cache}
import glot_backend/app_config/ports/store.{type Store}
import glot_backend/email/effect/delivery/algebra as email_algebra
import glot_backend/email/ports/sender.{type Sender}
import glot_backend/system/effect/effect_trace
import glot_backend/system/effect/error
import glot_backend/system/effect/error/db_error
import glot_backend/system/effect/error/resource_error
import glot_backend/system/effect/measured_interpreter
import glot_backend/system/effect/program_state
import glot_backend/system/effect/program_types
import glot_backend/system/request/context
import wisp

pub fn run(
  effect: email_algebra.EmailEffect(program_types.Program(a)),
  ctx: context.Context,
  sender: Sender,
  app_config_cache: option.Option(Cache),
  app_config_store: Store,
  state: program_state.State,
  continue: fn(program_types.Program(a), program_state.State) ->
    #(Result(a, error.Error), program_state.State),
) -> #(Result(a, error.Error), program_state.State) {
  case effect {
    email_algebra.SendEmail(message, next) ->
      measured_interpreter.run(
        fn() {
          load_config(app_config_cache, app_config_store)
          |> result.try(fn(config) {
            let email_config = dynamic_config.email_config(config)
            case dynamic_config.cloudflare_config(config) {
              option.Some(cloudflare) ->
                sender.send(
                  cloudflare,
                  message,
                  option.unwrap(
                    context.remaining_timeout_ms(ctx),
                    email_config.default_timeout_ms,
                  ),
                )
              option.None -> {
                wisp.log_error(
                  "Missing cloudflare app_config for email sending",
                )
                Error(error.resource(resource_error.CloudflareConfigNotFound))
              }
            }
          })
        },
        next,
        name: effect_trace.EmailEffectName(email_algebra.SendEmailEffectName),
        kind: effect_trace.EmailCallEffect,
        state: state,
        continue: continue,
      )
  }
}

fn load_config(
  cache: option.Option(Cache),
  store: Store,
) -> Result(dynamic_config.DynamicConfig, error.Error) {
  case cache {
    option.Some(port) -> {
      let #(config_result, _) = port.lookup()
      config_result
      |> result.map_error(error.database_query_error)
    }
    option.None ->
      store.list_entries()
      |> result.map_error(error.database_query_error)
      |> result.try(fn(entries) {
        config_decoder.from_entries(entries)
        |> result.map_error(fn(message) {
          error.database_query_error(db_error.DbQueryError(message))
        })
      })
  }
}

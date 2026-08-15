import gleam/option
import gleam/result
import gleam/time/timestamp.{type Timestamp}
import glot_backend/app_config/decoder/config as config_decoder
import glot_backend/app_config/domain/updates
import glot_backend/app_config/effect/algebra
import glot_backend/app_config/model/config
import glot_backend/app_config/model/entry.{type AppConfigEntry}
import glot_backend/app_config/ports/cache.{type Cache}
import glot_backend/app_config/ports/store.{type Store}
import glot_backend/system/effect/effect_trace
import glot_backend/system/effect/error
import glot_backend/system/effect/error/db_error
import glot_backend/system/effect/measured_interpreter
import glot_backend/system/effect/program_state
import glot_backend/system/effect/program_types

pub fn run(
  effect: algebra.AppConfigEffect(program_types.Program(a)),
  store: Store,
  cache: option.Option(Cache),
  state: program_state.State,
  continue: fn(program_types.Program(a), program_state.State) ->
    #(b, program_state.State),
) -> #(b, program_state.State) {
  case effect {
    algebra.GetDynamicConfig(next:) ->
      get_dynamic_config(store, cache, next, state, continue)
    algebra.UpsertDebugConfig(config:, updated_at:, next:) ->
      upsert(
        store,
        cache,
        updates.debug(config),
        updated_at,
        algebra.UpsertDebugConfigEffectName,
        next,
        state,
        continue,
      )
    algebra.UpsertAvailabilityConfig(config:, updated_at:, next:) ->
      upsert(
        store,
        cache,
        updates.availability(config),
        updated_at,
        algebra.UpsertAvailabilityConfigEffectName,
        next,
        state,
        continue,
      )
    algebra.UpsertAuthConfig(config:, updated_at:, next:) ->
      upsert(
        store,
        cache,
        updates.auth(config),
        updated_at,
        algebra.UpsertAuthConfigEffectName,
        next,
        state,
        continue,
      )
    algebra.UpsertPasskeyConfig(config:, updated_at:, next:) ->
      upsert(
        store,
        cache,
        updates.passkey(config),
        updated_at,
        algebra.UpsertPasskeyConfigEffectName,
        next,
        state,
        continue,
      )
    algebra.UpsertCleanupConfig(config:, updated_at:, next:) ->
      upsert(
        store,
        cache,
        updates.cleanup(config),
        updated_at,
        algebra.UpsertCleanupConfigEffectName,
        next,
        state,
        continue,
      )
    algebra.UpsertLogWorkerConfig(config:, updated_at:, next:) ->
      upsert(
        store,
        cache,
        updates.log_worker(config),
        updated_at,
        algebra.UpsertLogWorkerConfigEffectName,
        next,
        state,
        continue,
      )
    algebra.UpsertHttpPoolConfig(config:, updated_at:, next:) ->
      upsert(
        store,
        cache,
        updates.http_pool(config),
        updated_at,
        algebra.UpsertHttpPoolConfigEffectName,
        next,
        state,
        continue,
      )
    algebra.UpsertLanguageVersionCacheWorkerConfig(config:, updated_at:, next:) ->
      upsert(
        store,
        cache,
        updates.language_version_cache_worker(config),
        updated_at,
        algebra.UpsertLanguageVersionCacheWorkerConfigEffectName,
        next,
        state,
        continue,
      )
    algebra.UpsertRateLimitPolicy(action:, policy:, updated_at:, next:) ->
      upsert(
        store,
        cache,
        updates.rate_limit(action, policy),
        updated_at,
        algebra.UpsertRateLimitPolicyEffectName,
        next,
        state,
        continue,
      )
    algebra.UpsertDockerRunConfig(config:, updated_at:, next:) ->
      upsert(
        store,
        cache,
        updates.docker_run(config),
        updated_at,
        algebra.UpsertDockerRunConfigEffectName,
        next,
        state,
        continue,
      )
    algebra.UpsertSpamClassifierConfig(config:, updated_at:, next:) ->
      upsert(
        store,
        cache,
        updates.spam_classifier(config),
        updated_at,
        algebra.UpsertSpamClassifierConfigEffectName,
        next,
        state,
        continue,
      )
    algebra.UpsertCloudflareConfig(config:, updated_at:, next:) ->
      upsert(
        store,
        cache,
        updates.cloudflare(config),
        updated_at,
        algebra.UpsertCloudflareConfigEffectName,
        next,
        state,
        continue,
      )
    algebra.UpsertEmailConfig(config:, updated_at:, next:) ->
      upsert(
        store,
        cache,
        updates.email(config),
        updated_at,
        algebra.UpsertEmailConfigEffectName,
        next,
        state,
        continue,
      )
  }
}

fn get_dynamic_config(
  store: Store,
  cache: option.Option(Cache),
  next: fn(Result(config.DynamicConfig, db_error.DbQueryError)) ->
    program_types.Program(a),
  state: program_state.State,
  continue: fn(program_types.Program(a), program_state.State) ->
    #(b, program_state.State),
) -> #(b, program_state.State) {
  measured_interpreter.run_with_kind(
    fn() {
      case cache {
        option.Some(port) -> {
          let #(result, outcome) = port.lookup()
          #(result, effect_trace.CacheReadEffect(outcome))
        }
        option.None -> #(
          load_from_store(store),
          effect_trace.DatabaseReadEffect,
        )
      }
    },
    next,
    name: effect_trace.AppConfigEffectName(algebra.GetDynamicConfigEffectName),
    state: state,
    continue: continue,
  )
}

fn upsert(
  store: Store,
  cache: option.Option(Cache),
  entries: List(AppConfigEntry),
  updated_at: Timestamp,
  effect_name: algebra.EffectName,
  next: fn(Result(config.DynamicConfig, error.Error)) ->
    program_types.Program(a),
  state: program_state.State,
  continue: fn(program_types.Program(a), program_state.State) ->
    #(b, program_state.State),
) -> #(b, program_state.State) {
  measured_interpreter.run(
    fn() {
      store.upsert_entries(entries, updated_at)
      |> result.map_error(error.database_command_error)
      |> result.try(fn(_) { refresh_dynamic_config(store, cache) })
    },
    next,
    name: effect_trace.AppConfigEffectName(effect_name),
    kind: effect_trace.DatabaseWriteEffect,
    state: state,
    continue: continue,
  )
}

fn refresh_dynamic_config(
  store: Store,
  cache: option.Option(Cache),
) -> Result(config.DynamicConfig, error.Error) {
  case cache {
    option.Some(port) ->
      port.refresh()
      |> result.map_error(error.database_query_error)
    option.None ->
      load_from_store(store)
      |> result.map_error(error.database_query_error)
  }
}

fn load_from_store(
  store: Store,
) -> Result(config.DynamicConfig, db_error.DbQueryError) {
  store.list_entries()
  |> result.try(fn(entries) {
    config_decoder.from_entries(entries)
    |> result.map_error(db_error.DbQueryError)
  })
}

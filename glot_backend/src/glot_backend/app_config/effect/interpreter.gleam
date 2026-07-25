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
import glot_backend/system/effect/program_state
import glot_backend/system/effect/program_types
import glot_backend/system/runtime/erlang

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
  let started_at = erlang.perf_counter_ns()
  let #(load_result, category) = case cache {
    option.Some(port) -> {
      let #(result, outcome) = port.lookup()
      #(result, effect_trace.CacheReadEffect(outcome))
    }
    option.None -> #(load_from_store(store), effect_trace.DatabaseReadEffect)
  }

  continue(
    next(load_result),
    program_state.add_effect_measurement(
      state,
      effect_trace.AppConfigEffectName(algebra.GetDynamicConfigEffectName),
      category,
      started_at,
    ),
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
  let started_at = erlang.perf_counter_ns()
  let upsert_result =
    store.upsert_entries(entries, updated_at)
    |> result.map_error(error.database_command_error)
    |> result.try(fn(_) { refresh_dynamic_config(store, cache) })

  continue(
    next(upsert_result),
    program_state.add_effect_measurement(
      state,
      effect_trace.AppConfigEffectName(effect_name),
      effect_trace.DatabaseWriteEffect,
      started_at,
    ),
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

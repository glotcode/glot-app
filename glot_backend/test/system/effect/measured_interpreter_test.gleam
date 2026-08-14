import gleam/option
import glot_backend/system/cache/cache_outcome
import glot_backend/system/effect/basic/basic_algebra
import glot_backend/system/effect/effect_trace
import glot_backend/system/effect/error
import glot_backend/system/effect/error/db_error
import glot_backend/system/effect/log
import glot_backend/system/effect/measured_interpreter
import glot_backend/system/effect/program_state

pub fn successful_operation_continues_with_measurement_test() {
  let #(result, state) =
    measured_interpreter.run(
      fn() { 41 },
      fn(value) { value + 1 },
      name: effect_trace.BasicEffectName(basic_algebra.NewTokenEffectName),
      kind: effect_trace.DatabaseWriteEffect,
      state: program_state.new_state(),
      continue: fn(value, state) { #(Ok(value), state) },
    )

  assert result == Ok(42)
  let assert [
    effect_trace.EffectMeasurement(
      name: effect_trace.BasicEffectName(basic_algebra.NewTokenEffectName),
      category: effect_trace.WriteCategory,
      source: option.Some(effect_trace.DatabaseEffectSource),
      duration_ns: duration_ns,
    ),
  ] = state.effect_measurements
  assert duration_ns >= 0
}

pub fn failed_operation_maps_error_without_continuing_test() {
  let operation: fn() -> Result(Int, db_error.DbQueryError) = fn() {
    Error(db_error.DbQueryError("query failed"))
  }
  let #(result, state) =
    measured_interpreter.run_or_fail(
      operation,
      fn(_) { panic as "next must not be called for a failed operation" },
      map_error: error.database_query_error,
      name: effect_trace.BasicEffectName(basic_algebra.SystemTimeEffectName),
      kind: effect_trace.DatabaseReadEffect,
      state: program_state.new_state(),
      continue: fn(_, _) {
        panic as "continue must not be called for a failed operation"
      },
    )

  assert result
    == Error(error.database_query_error(db_error.DbQueryError("query failed")))
  let assert [
    effect_trace.EffectMeasurement(
      name: effect_trace.BasicEffectName(basic_algebra.SystemTimeEffectName),
      category: effect_trace.ReadCategory,
      source: option.Some(effect_trace.DatabaseEffectSource),
      duration_ns: duration_ns,
    ),
  ] = state.effect_measurements
  assert duration_ns >= 0
}

pub fn classified_operation_records_returned_effect_kind_test() {
  let #(result, state) =
    measured_interpreter.run_with_kind(
      fn() { #("cached", effect_trace.CacheReadEffect(cache_outcome.CacheHit)) },
      fn(value) { value <> " value" },
      name: effect_trace.BasicEffectName(basic_algebra.SystemTimeEffectName),
      state: program_state.new_state(),
      continue: fn(value, state) { #(Ok(value), state) },
    )

  assert result == Ok("cached value")
  let assert [
    effect_trace.EffectMeasurement(
      name: effect_trace.BasicEffectName(basic_algebra.SystemTimeEffectName),
      category: effect_trace.ReadCategory,
      source: option.Some(effect_trace.CacheEffectSource(cache_outcome.CacheHit)),
      duration_ns: duration_ns,
    ),
  ] = state.effect_measurements
  assert duration_ns >= 0
}

pub fn stateful_operation_preserves_updated_state_and_measurement_test() {
  let fields = log.singleton(log.string("operation", "completed"))
  let #(result, state) =
    measured_interpreter.run_with_state(
      fn(state) { #("value", program_state.add_info_fields(state, fields)) },
      fn(value) { value <> " continued" },
      name: effect_trace.BasicEffectName(basic_algebra.LogEffectName(log.Info)),
      kind: effect_trace.LogEffect,
      state: program_state.new_state(),
      continue: fn(value, state) { #(Ok(value), state) },
    )

  assert result == Ok("value continued")
  assert state.info_fields == fields
  let assert [
    effect_trace.EffectMeasurement(
      name: effect_trace.BasicEffectName(basic_algebra.LogEffectName(log.Info)),
      category: effect_trace.LogCategory,
      source: option.None,
      duration_ns: duration_ns,
    ),
  ] = state.effect_measurements
  assert duration_ns >= 0
}

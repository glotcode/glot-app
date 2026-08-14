import gleam/list
import gleam/option
import glot_backend/system/effect/db_effect
import glot_backend/system/effect/error
import glot_backend/system/effect/program_types

pub fn succeed(value: a) -> program_types.TransactionProgram(a) {
  program_types.TxPure(value)
}

pub fn fail(error: error.Error) -> program_types.TransactionProgram(a) {
  program_types.TxFail(error)
}

pub fn perform(
  effect: program_types.DbEffect(program_types.TransactionProgram(a)),
) -> program_types.TransactionProgram(a) {
  program_types.TxImpure(effect)
}

pub fn and_then(
  program: program_types.TransactionProgram(a),
  f: fn(a) -> program_types.TransactionProgram(b),
) -> program_types.TransactionProgram(b) {
  case program {
    program_types.TxPure(value) -> f(value)
    program_types.TxFail(error) -> program_types.TxFail(error)
    program_types.TxImpure(effect) ->
      program_types.TxImpure(
        db_effect.map(effect, fn(value) { and_then(value, f) }),
      )
  }
}

pub fn map(
  program: program_types.TransactionProgram(a),
  f: fn(a) -> b,
) -> program_types.TransactionProgram(b) {
  and_then(program, fn(value) { succeed(f(value)) })
}

pub fn from_result(
  value: Result(a, error.Error),
) -> program_types.TransactionProgram(a) {
  case value {
    Ok(v) -> program_types.TxPure(v)
    Error(err) -> program_types.TxFail(err)
  }
}

pub fn from_mapped_result(
  value: Result(a, source_error),
  map_error map_error: fn(source_error) -> error.Error,
) -> program_types.TransactionProgram(a) {
  case value {
    Ok(v) -> program_types.TxPure(v)
    Error(err) -> program_types.TxFail(map_error(err))
  }
}

pub fn from_option(
  value: option.Option(a),
  err: error.Error,
) -> program_types.TransactionProgram(a) {
  case value {
    option.Some(v) -> program_types.TxPure(v)
    option.None -> program_types.TxFail(err)
  }
}

pub fn require(
  value: program_types.TransactionProgram(option.Option(a)),
  err: error.Error,
) -> program_types.TransactionProgram(a) {
  and_then(value, fn(inner) { from_option(inner, err) })
}

pub fn sequence(
  programs: List(program_types.TransactionProgram(Nil)),
) -> program_types.TransactionProgram(Nil) {
  list.fold(programs, succeed(Nil), fn(acc, p) { and_then(acc, fn(_) { p }) })
}

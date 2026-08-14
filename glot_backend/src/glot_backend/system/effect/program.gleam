import gleam/dynamic
import gleam/dynamic/decode
import gleam/json
import gleam/option
import gleam/result
import glot_backend/app_config/effect/algebra as app_config_algebra
import glot_backend/auth/passkey/effect/algebra as webauthn_algebra
import glot_backend/email/effect/delivery/algebra as email_algebra
import glot_backend/run_code/effect/algebra as run_code_algebra
import glot_backend/system/effect/basic/basic_algebra
import glot_backend/system/effect/db_effect
import glot_backend/system/effect/error
import glot_backend/system/effect/program_types
import glot_backend/system/effect/transaction/transaction_algebra

pub fn succeed(value: a) -> program_types.Program(a) {
  program_types.Pure(value)
}

pub fn fail(error: error.Error) -> program_types.Program(a) {
  program_types.Fail(error)
}

pub fn perform(
  effect: program_types.Effect(program_types.Program(a)),
) -> program_types.Program(a) {
  program_types.Impure(effect)
}

pub fn perform_db(
  effect: program_types.DbEffect(program_types.Program(a)),
) -> program_types.Program(a) {
  perform(program_types.DbEffect(effect))
}

pub fn and_then(
  effect: program_types.Program(a),
  f: fn(a) -> program_types.Program(b),
) -> program_types.Program(b) {
  case effect {
    program_types.Pure(value) -> f(value)
    program_types.Fail(error) -> program_types.Fail(error)
    program_types.Impure(effect) ->
      program_types.Impure(map_effect(effect, fn(value) { and_then(value, f) }))
    program_types.Attempt(program:, on_error:) ->
      program_types.Attempt(program: and_then(program, f), on_error: fn(err) {
        and_then(on_error(err), f)
      })
  }
}

pub fn map(
  effect: program_types.Program(a),
  f: fn(a) -> b,
) -> program_types.Program(b) {
  and_then(effect, fn(value) { succeed(f(value)) })
}

/// Runs a program and, if it fails at any layer of interpretation, continues
/// with the provided recovery program instead.
pub fn attempt(
  effect: program_types.Program(a),
  on_error: fn(error.Error) -> program_types.Program(a),
) -> program_types.Program(a) {
  program_types.Attempt(program: effect, on_error: on_error)
}

pub fn from_result(value: Result(a, error.Error)) -> program_types.Program(a) {
  case value {
    Ok(v) -> program_types.Pure(v)
    Error(err) -> program_types.Fail(err)
  }
}

pub fn from_mapped_result(
  value: Result(a, source_error),
  map_error map_error: fn(source_error) -> error.Error,
) -> program_types.Program(a) {
  value
  |> result.map_error(map_error)
  |> from_result
}

pub fn from_option(
  value: option.Option(a),
  err: error.Error,
) -> program_types.Program(a) {
  case value {
    option.Some(v) -> program_types.Pure(v)
    option.None -> program_types.Fail(err)
  }
}

pub fn require(
  value: program_types.Program(option.Option(a)),
  err: error.Error,
) -> program_types.Program(a) {
  and_then(value, fn(value) { from_option(value, err) })
}

pub fn parse_json(
  json_str: String,
  decoder: decode.Decoder(a),
) -> program_types.Program(a) {
  json.parse(json_str, decoder)
  |> result.map_error(error.json_parse_error)
  |> from_result
}

pub fn decode_dynamic(
  data: dynamic.Dynamic,
  decoder: decode.Decoder(a),
) -> program_types.Program(a) {
  decode.run(data, decoder)
  |> result.map_error(error.decode_error)
  |> from_result
}

pub fn when(
  condition: Bool,
  if_true: program_types.Program(Nil),
) -> program_types.Program(Nil) {
  case condition {
    True -> if_true
    False -> program_types.Pure(Nil)
  }
}

fn map_effect(
  effect: program_types.Effect(a),
  f: fn(a) -> b,
) -> program_types.Effect(b) {
  case effect {
    program_types.AppConfigEffect(effect) ->
      program_types.AppConfigEffect(app_config_algebra.map(effect, f))
    program_types.BasicEffect(effect) ->
      program_types.BasicEffect(basic_algebra.map(effect, f))
    program_types.EmailEffect(effect) ->
      program_types.EmailEffect(email_algebra.map(effect, f))
    program_types.WebauthnEffect(effect) ->
      program_types.WebauthnEffect(webauthn_algebra.map(effect, f))
    program_types.RunCodeEffect(effect) ->
      program_types.RunCodeEffect(run_code_algebra.map(effect, f))
    program_types.DbEffect(effect) ->
      program_types.DbEffect(db_effect.map(effect, f))
    program_types.TransactionEffect(effect) ->
      program_types.TransactionEffect(transaction_algebra.map(effect, f))
  }
}

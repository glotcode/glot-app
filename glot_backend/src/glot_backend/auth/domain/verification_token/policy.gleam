import gleam/int
import gleam/list
import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}
import glot_core/helpers/timestamp_helpers

pub const valid_token_count = 2

pub const max_attempts = 10

pub const token_length = 8

pub fn created_since(now: Timestamp, max_age_seconds: Int) -> Timestamp {
  timestamp_helpers.subtract_seconds(now, max_age_seconds)
}

pub fn shared_attempt_count(
  tokens: List(token),
  attempt_count: fn(token) -> Int,
) -> Int {
  list.fold(tokens, 0, fn(count, token) { int.max(count, attempt_count(token)) })
}

pub fn attempts_exhausted(shared_attempt_count: Int) -> Bool {
  shared_attempt_count >= max_attempts
}

pub fn find_matching(
  tokens: List(token),
  provided_token: String,
  token_value: fn(token) -> String,
) -> Option(token) {
  tokens
  |> list.find(fn(token) { token_value(token) == provided_token })
  |> option.from_result()
}

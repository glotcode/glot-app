import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/time/timestamp.{type Timestamp}

pub fn encode(ts: Timestamp) -> json.Json {
  let #(secs, nanos) = timestamp.to_unix_seconds_and_nanoseconds(ts)
  json.object([
    #("seconds", json.int(secs)),
    #("nanos", json.int(nanos)),
  ])
}

pub fn decoder() -> decode.Decoder(Timestamp) {
  use secs <- decode.field("seconds", decode.int)
  use nanos <- decode.field("nanos", decode.int)

  decode.success(timestamp.from_unix_seconds_and_nanoseconds(secs, nanos))
}

pub fn to_microseconds(ts: Timestamp) -> Int {
  let #(seconds, nanos) = timestamp.to_unix_seconds_and_nanoseconds(ts)
  seconds * 1_000_000 + nanos / 1000
}

pub fn from_unix_milliseconds(ms: Int) -> Timestamp {
  let seconds = ms / 1000
  let millis = ms - seconds * 1000
  timestamp.from_unix_seconds_and_nanoseconds(seconds, millis * 1_000_000)
}

pub fn add_seconds(value: Timestamp, seconds_to_add: Int) -> Timestamp {
  let #(seconds, nanos) = timestamp.to_unix_seconds_and_nanoseconds(value)
  timestamp.from_unix_seconds_and_nanoseconds(seconds + seconds_to_add, nanos)
}

pub fn subtract_seconds(
  value: Timestamp,
  seconds_to_subtract: Int,
) -> Timestamp {
  add_seconds(value, -seconds_to_subtract)
}

pub fn relative_label(value: Timestamp, now: Timestamp) -> String {
  let #(value_seconds, _) = timestamp.to_unix_seconds_and_nanoseconds(value)
  let #(now_seconds, _) = timestamp.to_unix_seconds_and_nanoseconds(now)
  let delta_seconds = value_seconds - now_seconds
  let absolute_delta = int.absolute_value(delta_seconds)

  case absolute_delta < 60 {
    True -> "now"
    False -> relative_label_with_direction(delta_seconds, absolute_delta)
  }
}

fn relative_label_with_direction(
  delta_seconds: Int,
  absolute_delta: Int,
) -> String {
  let #(count, unit) = relative_unit(absolute_delta)
  let phrase = int.to_string(count) <> " " <> pluralize(unit, count)

  case delta_seconds < 0 {
    True -> phrase <> " ago"
    False -> "in " <> phrase
  }
}

fn relative_unit(absolute_delta: Int) -> #(Int, String) {
  first_matching_relative_unit(absolute_delta, [
    #(31_536_000, "year"),
    #(2_592_000, "month"),
    #(604_800, "week"),
    #(86_400, "day"),
    #(3600, "hour"),
    #(60, "minute"),
  ])
}

fn first_matching_relative_unit(
  absolute_delta: Int,
  units: List(#(Int, String)),
) -> #(Int, String) {
  case units {
    [#(seconds_per_unit, unit), ..rest] ->
      case absolute_delta >= seconds_per_unit {
        True -> #(absolute_delta / seconds_per_unit, unit)
        False -> first_matching_relative_unit(absolute_delta, rest)
      }
    [] -> #(absolute_delta, "second")
  }
}

fn pluralize(unit: String, count: Int) -> String {
  case count == 1 {
    True -> unit
    False -> unit <> "s"
  }
}

pub fn one_day_ago(now: Timestamp) -> Timestamp {
  let #(seconds, nanos) = timestamp.to_unix_seconds_and_nanoseconds(now)
  timestamp.from_unix_seconds_and_nanoseconds(seconds - 86_400, nanos)
}

pub fn days_ago(now: Timestamp, days: Int) -> Timestamp {
  let #(seconds, nanos) = timestamp.to_unix_seconds_and_nanoseconds(now)
  timestamp.from_unix_seconds_and_nanoseconds(seconds - days * 86_400, nanos)
}

pub fn one_hour_ago(now: Timestamp) -> Timestamp {
  let #(seconds, nanos) = timestamp.to_unix_seconds_and_nanoseconds(now)
  timestamp.from_unix_seconds_and_nanoseconds(seconds - 3600, nanos)
}

pub fn one_minute_ago(now: Timestamp) -> Timestamp {
  let #(seconds, nanos) = timestamp.to_unix_seconds_and_nanoseconds(now)
  timestamp.from_unix_seconds_and_nanoseconds(seconds - 60, nanos)
}

pub fn one_second_ago(now: Timestamp) -> Timestamp {
  let #(seconds, nanos) = timestamp.to_unix_seconds_and_nanoseconds(now)
  timestamp.from_unix_seconds_and_nanoseconds(seconds - 1, nanos)
}

pub fn duration_in_ns(a: Timestamp, b: Timestamp) -> Int {
  let #(a_seconds, a_nanos) = timestamp.to_unix_seconds_and_nanoseconds(a)
  let #(b_seconds, b_nanos) = timestamp.to_unix_seconds_and_nanoseconds(b)

  let a_total = a_seconds * 1_000_000_000 + a_nanos
  let b_total = b_seconds * 1_000_000_000 + b_nanos

  int.absolute_value(a_total - b_total)
}

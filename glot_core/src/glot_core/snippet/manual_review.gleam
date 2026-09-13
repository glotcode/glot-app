import gleam/dynamic/decode
import gleam/json
import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_core/helpers/timestamp_helpers
import glot_core/helpers/uuid_helpers
import youid/uuid.{type Uuid}

pub type Verdict {
  Spam
  NotSpam
}

pub type ManualReview {
  ManualReview(
    verdict: option.Option(Verdict),
    reviewer_id: option.Option(Uuid),
    reviewed_at: option.Option(Timestamp),
    version: Int,
  )
}

pub fn empty() -> ManualReview {
  ManualReview(option.None, option.None, option.None, 0)
}

pub fn to_string(verdict: Verdict) -> String {
  case verdict {
    Spam -> "spam"
    NotSpam -> "not_spam"
  }
}

pub fn from_string(value: String) -> Result(Verdict, String) {
  case value {
    "spam" -> Ok(Spam)
    "not_spam" -> Ok(NotSpam)
    _ -> Error("Invalid manual verdict")
  }
}

pub fn verdict_decoder() -> decode.Decoder(Verdict) {
  use value <- decode.then(decode.string)
  case from_string(value) {
    Ok(verdict) -> decode.success(verdict)
    Error(message) -> decode.failure(Spam, message)
  }
}

pub fn version_decoder() -> decode.Decoder(Int) {
  use value <- decode.then(decode.int)
  case value >= 0 {
    True -> decode.success(value)
    False -> decode.failure(0, "Nonnegative review version")
  }
}

pub fn decoder() -> decode.Decoder(ManualReview) {
  use verdict <- decode.field("verdict", decode.optional(verdict_decoder()))
  use reviewer_id <- decode.field(
    "reviewerId",
    decode.optional(uuid_helpers.decoder()),
  )
  use reviewed_at <- decode.field(
    "reviewedAt",
    decode.optional(timestamp_helpers.decoder()),
  )
  use version <- decode.field("version", version_decoder())
  decode.success(ManualReview(verdict:, reviewer_id:, reviewed_at:, version:))
}

pub fn encode(review: ManualReview) -> json.Json {
  json.object([
    #(
      "verdict",
      json.nullable(review.verdict, fn(value) { json.string(to_string(value)) }),
    ),
    #(
      "reviewerId",
      json.nullable(review.reviewer_id, fn(value) {
        json.string(uuid.to_string(value))
      }),
    ),
    #("reviewedAt", json.nullable(review.reviewed_at, timestamp_helpers.encode)),
    #("version", json.int(review.version)),
  ])
}

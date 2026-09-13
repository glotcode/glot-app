import gleam/dynamic/decode
import gleam/json
import gleam/option
import glot_core/language.{type Language}
import glot_core/snippet/spam_classification.{type ReasonCode}

pub type DecisionFilter {
  AllDecisions
  Flagged
  Allow
  Review
  Block
  Unclassified
}

pub type ManualStatus {
  AllManual
  Unreviewed
  Spam
  NotSpam
}

pub type SpamReviewFilter {
  SpamReviewFilter(
    decision: DecisionFilter,
    reason: option.Option(ReasonCode),
    confidence_min: option.Option(Int),
    confidence_max: option.Option(Int),
    manual: ManualStatus,
    username: option.Option(String),
    language: option.Option(Language),
  )
}

pub fn all() -> SpamReviewFilter {
  SpamReviewFilter(
    AllDecisions,
    option.None,
    option.None,
    option.None,
    AllManual,
    option.None,
    option.None,
  )
}

pub fn default() -> SpamReviewFilter {
  SpamReviewFilter(..all(), decision: Flagged, manual: Unreviewed)
}

pub fn decision_to_string(value: DecisionFilter) -> String {
  case value {
    AllDecisions -> "all"
    Flagged -> "flagged"
    Allow -> "allow"
    Review -> "review"
    Block -> "block"
    Unclassified -> "unclassified"
  }
}

pub fn decision_from_string(value: String) -> Result(DecisionFilter, String) {
  case value {
    "all" -> Ok(AllDecisions)
    "flagged" -> Ok(Flagged)
    "allow" -> Ok(Allow)
    "review" -> Ok(Review)
    "block" -> Ok(Block)
    "unclassified" -> Ok(Unclassified)
    _ -> Error("Invalid automated decision filter")
  }
}

pub fn manual_to_string(value: ManualStatus) -> String {
  case value {
    AllManual -> "all"
    Unreviewed -> "unreviewed"
    Spam -> "spam"
    NotSpam -> "not_spam"
  }
}

pub fn manual_from_string(value: String) -> Result(ManualStatus, String) {
  case value {
    "all" -> Ok(AllManual)
    "unreviewed" -> Ok(Unreviewed)
    "spam" -> Ok(Spam)
    "not_spam" -> Ok(NotSpam)
    _ -> Error("Invalid manual status filter")
  }
}

pub fn decoder() -> decode.Decoder(SpamReviewFilter) {
  use decision <- decode.field(
    "decision",
    enum_decoder(decision_from_string, AllDecisions),
  )
  use reason <- decode.field(
    "reason",
    decode.optional(spam_classification.reason_code_decoder()),
  )
  use confidence_min <- decode.field(
    "confidenceMin",
    decode.optional(spam_classification.confidence_decoder()),
  )
  use confidence_max <- decode.field(
    "confidenceMax",
    decode.optional(spam_classification.confidence_decoder()),
  )
  use manual <- decode.field(
    "manual",
    enum_decoder(manual_from_string, AllManual),
  )
  use username <- decode.field("username", decode.optional(decode.string))
  use language <- decode.field("language", decode.optional(language.decoder()))
  let filter =
    SpamReviewFilter(
      decision:,
      reason:,
      confidence_min:,
      confidence_max:,
      manual:,
      username:,
      language:,
    )
  case confidence_min, confidence_max {
    option.Some(min), option.Some(max) if min > max ->
      decode.failure(all(), "Minimum confidence must not exceed maximum")
    _, _ -> decode.success(filter)
  }
}

fn enum_decoder(
  parse: fn(String) -> Result(a, String),
  fallback: a,
) -> decode.Decoder(a) {
  use value <- decode.then(decode.string)
  case parse(value) {
    Ok(value) -> decode.success(value)
    Error(message) -> decode.failure(fallback, message)
  }
}

pub fn encode(filter: SpamReviewFilter) -> json.Json {
  json.object([
    #("decision", json.string(decision_to_string(filter.decision))),
    #(
      "reason",
      json.nullable(filter.reason, fn(value) {
        json.string(spam_classification.reason_code_to_string(value))
      }),
    ),
    #("confidenceMin", json.nullable(filter.confidence_min, json.int)),
    #("confidenceMax", json.nullable(filter.confidence_max, json.int)),
    #("manual", json.string(manual_to_string(filter.manual))),
    #("username", json.nullable(filter.username, json.string)),
    #("language", json.nullable(filter.language, language.encode)),
  ])
}

import gleam/int
import gleam/option
import gleam/result
import gleam/uri
import glot_core/language
import glot_core/pagination_model.{type CursorPagination}
import glot_core/snippet/spam_classification
import glot_core/snippet/spam_review_filter.{type SpamReviewFilter}
import glot_frontend/admin/list_query

pub type Draft {
  Draft(
    decision: String,
    reason: String,
    minimum: String,
    maximum: String,
    manual: String,
    username: String,
    language: String,
  )
}

pub fn parse(raw: option.Option(String)) -> Draft {
  let query = list_query.parse(raw)
  Draft(
    list_query.value_or(query, "decision", "flagged"),
    list_query.value_or(query, "reason", ""),
    list_query.value_or(query, "min", ""),
    list_query.value_or(query, "max", ""),
    list_query.value_or(query, "manual", "unreviewed"),
    list_query.value_or(query, "username", ""),
    list_query.value_or(query, "language", ""),
  )
}

pub fn all() -> Draft {
  Draft("all", "", "", "", "all", "", "")
}

pub fn validate(draft: Draft) -> Result(SpamReviewFilter, String) {
  use decision <- result.try(spam_review_filter.decision_from_string(
    draft.decision,
  ))
  use manual <- result.try(spam_review_filter.manual_from_string(draft.manual))
  use reason <- result.try(optional(
    draft.reason,
    spam_classification.reason_code_from_string,
  ))
  use confidence_min <- result.try(optional(draft.minimum, confidence))
  use confidence_max <- result.try(optional(draft.maximum, confidence))
  use language <- result.try(
    optional(draft.language, fn(value) {
      language.from_string(value) |> option.to_result("Invalid language")
    }),
  )
  case confidence_min, confidence_max {
    option.Some(min), option.Some(max) if min > max ->
      Error("Minimum confidence must not exceed maximum.")
    _, _ ->
      Ok(
        spam_review_filter.SpamReviewFilter(
          decision:,
          manual:,
          reason:,
          confidence_min:,
          confidence_max:,
          language:,
          username: case draft.username {
            "" -> option.None
            value -> option.Some(value)
          },
        ),
      )
  }
}

fn confidence(value: String) -> Result(Int, String) {
  use value <- result.try(
    int.parse(value)
    |> result.map_error(fn(_) { "Confidence must be an integer from 0 to 100." }),
  )
  spam_classification.confidence_from_int(value)
}

fn optional(
  value: String,
  parse: fn(String) -> Result(a, String),
) -> Result(option.Option(a), String) {
  case value {
    "" -> Ok(option.None)
    _ -> parse(value) |> result.map(option.Some)
  }
}

pub fn encode(
  draft: Draft,
  pagination: CursorPagination,
) -> option.Option(String) {
  list_query.encode(
    [
      #("decision", option.Some(draft.decision)),
      #("reason", option.Some(draft.reason)),
      #("min", option.Some(draft.minimum)),
      #("max", option.Some(draft.maximum)),
      #("manual", option.Some(draft.manual)),
      #("username", option.Some(draft.username)),
      #("language", option.Some(draft.language)),
    ],
    pagination,
  )
}

pub fn focus(
  raw: option.Option(String),
  slug: String,
) -> option.Option(String) {
  let base =
    encode(parse(raw), pagination_model.InitialPage(1)) |> option.unwrap("")
  option.Some(base <> "&" <> uri.query_to_string([#("focus", slug)]))
}

pub type Field {
  Decision
  Reason
  Minimum
  Maximum
  Manual
  Username
  Language
}

pub fn set(draft: Draft, field: Field, value: String) -> Draft {
  case field {
    Decision -> Draft(..draft, decision: value)
    Reason -> Draft(..draft, reason: value)
    Minimum -> Draft(..draft, minimum: value)
    Maximum -> Draft(..draft, maximum: value)
    Manual -> Draft(..draft, manual: value)
    Username -> Draft(..draft, username: value)
    Language -> Draft(..draft, language: value)
  }
}

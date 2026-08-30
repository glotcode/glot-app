import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_core/snippet/snippet_model.{type Snippet}

pub type Candidate {
  Candidate(snippet: Snippet, expected_updated_at: Timestamp, attempts: Int)
}

pub type CheckResult {
  CheckResult(is_runnable: Bool, checked_at: Timestamp)
}

pub type CheckFailure {
  CheckFailure(error_code: String, failed_at: Timestamp)
}

pub type StoreResult {
  Stored
  Stale
}

pub type RunnabilityMetadata {
  RunnabilityMetadata(
    is_runnable: option.Option(Bool),
    checked_at: option.Option(Timestamp),
    attempts: Int,
    last_error: option.Option(String),
    failed_at: option.Option(Timestamp),
  )
}

pub fn attempts_from_int(value: Int) -> Result(Int, String) {
  case value >= 0 {
    True -> Ok(value)
    False -> Error("Runnability check attempts cannot be negative")
  }
}

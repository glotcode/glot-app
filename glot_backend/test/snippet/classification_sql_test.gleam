import gleam/option
import gleam/string
import gleam/time/timestamp
import glot_backend/sql

pub fn updating_classification_does_not_update_snippet_timestamp_test() {
  let #(statement, _) =
    sql.update_spam_classification(
      option.None,
      option.None,
      option.None,
      option.None,
      <<>>,
      timestamp.from_unix_seconds(0),
    )
  let assert [set_clause, _] = string.split(statement, on: "WHERE")

  assert !string.contains(set_clause, "updated_at")
}

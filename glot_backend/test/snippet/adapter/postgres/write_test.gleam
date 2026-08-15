import glot_backend/snippet/adapter/postgres/write
import glot_backend/system/effect/error/db_error
import glot_core/snippet/spam_classification
import support/integration/fixture

pub fn guarded_classification_update_distinguishes_stale_rows_test() {
  let snippet_id = fixture.test_snippet_id()

  assert write.classification_store_result(snippet_id, 0)
    == Ok(spam_classification.Stale)
  assert write.classification_store_result(snippet_id, 1)
    == Ok(spam_classification.Stored)
  assert write.classification_store_result(snippet_id, 2)
    == Error(db_error.DbCommandError(
      "guarded spam classification update affected 2 rows for snippet "
      <> "00000000-0000-0000-0000-000000000013",
    ))
}

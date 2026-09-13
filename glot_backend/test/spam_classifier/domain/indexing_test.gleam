import gleam/erlang/process
import gleam/list
import gleam/option
import glot_backend/spam_classifier/effect/indexing
import glot_backend/spam_classifier/model/fingerprint.{type StoredFingerprint}
import glot_backend/spam_classifier/ports/storage
import support/integration/fixture
import support/spam_classifier_storage

pub fn indexing_is_bounded_and_reports_stale_revisions_test() {
  let fixture =
    fixture.integration_fixture(
      next_uuids: [],
      jobs: [],
      account_delete_job_id: option.None,
    )
  let writes = process.new_subject()
  let port =
    storage.Storage(
      ..spam_classifier_storage.defaults(),
      index_batch: fn(version) {
        assert version == "local-v1"
        Ok(list.repeat(fixture.snippet, 101))
      },
      store: fn(value: StoredFingerprint) {
        assert value.snippet_id == fixture.snippet.id
        assert value.revision == fixture.snippet.updated_at
        process.send(writes, value)
        Ok(False)
      },
    )
  let assert Ok(report) = indexing.run(port)
  assert report.scanned == 100
  assert report.stored == 0
  assert report.stale == 100
  list.each(list.repeat(Nil, 100), fn(_) {
    let assert Ok(_) = process.receive(writes, 0)
  })
  assert process.receive(writes, 0) == Error(Nil)
}

pub fn empty_reconciliation_does_not_write_test() {
  let port =
    storage.Storage(..spam_classifier_storage.defaults(), index_batch: fn(_) {
      Ok([])
    })
  let assert Ok(report) = indexing.run(port)
  assert report.scanned == 0
}

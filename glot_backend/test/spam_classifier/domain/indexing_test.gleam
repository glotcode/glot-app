import gleam/erlang/process
import gleam/list
import gleam/option
import glot_backend/spam_classifier/effect/indexing
import glot_backend/spam_classifier/model/fingerprint.{type StoredFingerprint}
import glot_backend/spam_classifier/ports/storage
import support/integration/fixture
import support/spam_classifier_storage

pub fn indexing_commits_one_bounded_batch_and_reports_stale_revisions_test() {
  let fixture = fixture.integration_fixture([], [], option.None)
  let writes = process.new_subject()
  let port =
    storage.Storage(
      ..spam_classifier_storage.defaults(),
      index_batch: fn(version) {
        assert version == "local-v1"
        Ok(fingerprint.IndexBatch(7, list.repeat(fixture.snippet, 101)))
      },
      commit_index_batch: fn(version, generation, after_id, values) {
        assert version == "local-v1"
        assert generation == 7
        assert after_id == option.Some(fixture.snippet.id)
        assert list.length(values) == 100
        list.each(values, fn(value: StoredFingerprint) {
          assert value.snippet_id == fixture.snippet.id
          assert value.revision == fixture.snippet.updated_at
        })
        process.send(writes, Nil)
        Ok(option.Some(93))
      },
    )
  let assert Ok(report) = indexing.run(port)
  assert report.scanned == 100
  assert report.stored == 93
  assert report.stale == 7
  let assert Ok(Nil) = process.receive(writes, 0)
  assert process.receive(writes, 0) == Error(Nil)
}

pub fn empty_reconciliation_resets_cursor_without_fingerprints_test() {
  let port =
    storage.Storage(
      ..spam_classifier_storage.defaults(),
      index_batch: fn(_) { Ok(fingerprint.IndexBatch(8, [])) },
      commit_index_batch: fn(_, generation, after_id, values) {
        assert generation == 8
        assert after_id == option.None
        assert values == []
        Ok(option.Some(0))
      },
    )
  let assert Ok(report) = indexing.run(port)
  assert report.scanned == 0
}

pub fn short_final_batch_resets_cursor_test() {
  let fixture = fixture.integration_fixture([], [], option.None)
  let port =
    storage.Storage(
      ..spam_classifier_storage.defaults(),
      index_batch: fn(_) { Ok(fingerprint.IndexBatch(9, [fixture.snippet])) },
      commit_index_batch: fn(_, _, after_id, values) {
        assert after_id == option.None
        assert list.length(values) == 1
        Ok(option.Some(1))
      },
    )
  let assert Ok(report) = indexing.run(port)
  assert report.scanned == 1
  assert report.stored == 1
}

pub fn superseded_cursor_does_not_schedule_another_continuation_test() {
  let fixture = fixture.integration_fixture([], [], option.None)
  let port =
    storage.Storage(
      ..spam_classifier_storage.defaults(),
      index_batch: fn(_) {
        Ok(fingerprint.IndexBatch(0, list.repeat(fixture.snippet, 100)))
      },
      commit_index_batch: fn(_, _, _, _) { Ok(option.None) },
    )
  let assert Ok(report) = indexing.run(port)
  assert report.scanned == 0
  assert report.stored == 0
  assert report.stale == 0
}

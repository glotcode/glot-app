import gleam/list
import gleam/result
import glot_backend/spam_classifier/domain/features
import glot_backend/spam_classifier/domain/scoring
import glot_backend/spam_classifier/domain/similarity
import glot_backend/spam_classifier/model/fingerprint
import glot_backend/spam_classifier/ports/storage.{type Storage}
import glot_backend/system/effect/error.{type Error}

pub fn run(storage: Storage) -> Result(fingerprint.IndexReport, Error) {
  use batch <- result.try(storage.index_batch(scoring.version))
  // Persisted fingerprints are the checkpoint. A restart or edit simply leaves
  // a missing current revision for the next pass; no classifications are read.
  list.try_fold(
    list.take(batch, 100),
    fingerprint.IndexReport(0, 0, 0),
    fn(report, snippet) {
      let extracted = features.snippet(snippet, True)
      let evidence = extracted.evidence
      use stored <- result.try(
        storage.store(fingerprint.StoredFingerprint(
          snippet.id,
          snippet.updated_at,
          scoring.version,
          similarity.fingerprint(extracted.tokens),
          evidence.promotional_phrase
            || evidence.gambling_promotion
            || evidence.obfuscated_url
            || evidence.keyword_stuffing,
          extracted.urls,
        )),
      )
      Ok(case stored {
        True ->
          fingerprint.IndexReport(
            report.scanned + 1,
            report.stored + 1,
            report.stale,
          )
        False ->
          fingerprint.IndexReport(
            report.scanned + 1,
            report.stored,
            report.stale + 1,
          )
      })
    },
  )
}

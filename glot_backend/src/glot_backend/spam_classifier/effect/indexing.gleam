import gleam/list
import gleam/option
import gleam/result
import glot_backend/spam_classifier/domain/features
import glot_backend/spam_classifier/domain/scoring
import glot_backend/spam_classifier/domain/similarity
import glot_backend/spam_classifier/model/fingerprint
import glot_backend/spam_classifier/ports/storage.{type Storage}
import glot_backend/system/effect/error.{type Error}

pub fn run(storage: Storage) -> Result(fingerprint.IndexReport, Error) {
  use batch <- result.try(storage.index_batch(scoring.version))
  let snippets = list.take(batch.snippets, 100)
  let scanned = list.length(snippets)
  // Prepare fingerprints outside the atomic write. Advance past stale revisions;
  // the next pass reconciles them, including edits behind the current cursor.
  let fingerprints =
    list.map(snippets, fn(snippet) {
      let extracted = features.snippet(snippet, True)
      let evidence = extracted.evidence
      fingerprint.StoredFingerprint(
        snippet.id,
        snippet.updated_at,
        scoring.version,
        similarity.fingerprint(extracted.tokens),
        evidence.promotional_phrase
          || evidence.gambling_promotion
          || evidence.obfuscated_url
          || evidence.keyword_stuffing,
        extracted.urls,
      )
    })
  let after_id = case scanned == 100 {
    True ->
      list.last(snippets)
      |> result.map(fn(snippet) { snippet.id })
      |> option.from_result
    False -> option.None
  }
  use stored <- result.try(storage.commit_index_batch(
    scoring.version,
    batch.generation,
    after_id,
    fingerprints,
  ))
  case stored {
    option.Some(stored) ->
      Ok(fingerprint.IndexReport(scanned, stored, scanned - stored))
    // Another worker already committed this cursor generation. Its batch owns
    // continuation, so this attempt must neither write nor rewind the cursor.
    option.None -> Ok(fingerprint.IndexReport(0, 0, 0))
  }
}

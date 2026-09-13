import gleam/int
import gleam/list
import gleam/option
import gleam/string
import glot_backend/spam_classifier/domain/features
import glot_backend/spam_classifier/domain/similarity
import glot_backend/spam_classifier/effect/classification
import glot_backend/spam_classifier/model/config
import glot_backend/spam_classifier/model/fingerprint
import glot_backend/spam_classifier/ports
import glot_backend/spam_classifier/ports/client
import glot_backend/spam_classifier/ports/storage
import glot_core/snippet/classifier_provider
import glot_core/snippet/snippet_model
import glot_core/snippet/spam_classification
import support/integration/fixture
import support/spam_classifier_storage

pub fn independently_suspicious_neighbors_contribute_campaign_signal_test() {
  let test_fixture =
    fixture.integration_fixture(
      next_uuids: [],
      jobs: [],
      account_delete_job_id: option.None,
    )
  let snippet =
    snippet_model.Snippet(
      ..test_fixture.snippet,
      title: "Buy now this promotional campaign contains enough words to be compared with earlier snippets sharing the same text and changing only their destinations",
    )
  let signature = similarity.fingerprint(features.snippet(snippet, True).tokens)
  let neighbors = [
    fingerprint.Candidate(
      fixture.must_uuid("00000000-0000-0000-0000-000000000111"),
      snippet.updated_at,
      "first",
      signature,
      True,
      16,
    ),
    fingerprint.Candidate(
      fixture.must_uuid("00000000-0000-0000-0000-000000000112"),
      snippet.updated_at,
      "second",
      signature,
      True,
      16,
    ),
  ]
  let classify = fn(neighbors) {
    classification.run(
      config.Config("", "", classifier_provider.Local),
      spam_classification.ServiceRequest(snippet, True),
      ports.Ports(
        external: client.Client(classify: fn(_, _, _) {
          panic as "local mode called external service"
        }),
        storage: storage.Storage(
          ..spam_classifier_storage.empty_index(),
          candidates: fn(_, _, _) { Ok(neighbors) },
        ),
      ),
      test_fixture.ctx,
    )
  }
  let assert Ok(result) = classify(neighbors)
  assert result.response.decision == spam_classification.Review
  let assert Ok(single) = classify(list.take(neighbors, 1))
  assert single.response.decision == spam_classification.Allow
  let assert Ok(harmless) =
    classify(
      list.map(neighbors, fn(candidate) {
        fingerprint.Candidate(..candidate, independently_suspicious: False)
      }),
    )
  assert harmless.response.decision == spam_classification.Allow
  let assert Ok(self) =
    classify(
      list.map(neighbors, fn(candidate) {
        fingerprint.Candidate(..candidate, snippet_id: snippet.id)
      }),
    )
  assert self.response.decision == spam_classification.Allow

  let many =
    list.index_map(list.repeat(Nil, 201), fn(_, offset) {
      let index = offset + 1
      fingerprint.Candidate(
        fixture.must_uuid(
          "00000000-0000-0000-0001-"
          <> string.pad_start(int.to_string(index), 12, "0"),
        ),
        snippet.updated_at,
        int.to_string(index),
        signature,
        index >= 200,
        16,
      )
    })
  let assert Ok(bounded) = classify(many)
  // The 201st candidate must not supply the second campaign vote.
  assert bounded.response.decision == spam_classification.Allow
  let assert option.Some(explanation) = bounded.explanation
  assert list.map(explanation.neighbors, fn(neighbor) { neighbor.slug })
    == ["200", "199", "198", "197", "196"]
}

import gleam/list
import glot_backend/spam_classifier/domain/scoring
import glot_core/snippet/spam_classification

fn ordinary() -> scoring.Evidence {
  scoring.Evidence(True, 0, False, False, False, False, False, False, False, 0)
}

pub fn runnability_alone_is_not_evidence_test() {
  let result =
    scoring.assess(scoring.Evidence(..ordinary(), is_runnable: False))
  assert result.score == 0
  assert result.decision == spam_classification.Allow
  assert result.reason_code == spam_classification.None
}

pub fn broken_documentation_link_requires_review_test() {
  let result =
    scoring.assess(
      scoring.Evidence(..ordinary(), is_runnable: False, url_count: 1),
    )
  assert result.score == 40
  assert result.decision == spam_classification.Review
  assert result.reason_code == spam_classification.Ambiguous
}

pub fn runnable_promotional_content_can_be_likely_spam_test() {
  let result =
    scoring.assess(
      scoring.Evidence(
        ..ordinary(),
        url_count: 2,
        promotional_phrase: True,
        contact_solicitation: True,
      ),
    )
  assert result.score == 75
  assert result.decision == spam_classification.Block
  assert result.reason_code == spam_classification.PromotionalContent
}

pub fn all_signals_contribute_once_and_score_is_capped_test() {
  let result =
    scoring.assess(scoring.Evidence(
      False,
      100,
      True,
      True,
      True,
      True,
      True,
      True,
      True,
      100,
    ))
  assert result.score == 100
  assert list.length(result.signals) == 10
  assert result.reason_code == spam_classification.LinkSpam
}

pub fn legitimate_neighbors_do_not_create_spam_evidence_test() {
  let result =
    scoring.assess(
      scoring.Evidence(..ordinary(), independently_suspicious_neighbors: 100),
    )
  assert result.score == 0
}

pub fn campaign_requires_two_neighbors_and_current_suspicion_test() {
  let one =
    scoring.Evidence(
      ..ordinary(),
      promotional_phrase: True,
      independently_suspicious_neighbors: 1,
    )
  assert scoring.assess(one).score == 0
  assert scoring.assess(
      scoring.Evidence(..one, independently_suspicious_neighbors: 2),
    ).score
    == 30
}

pub fn confidence_is_distance_from_nearest_boundary_test() {
  assert scoring.rule_confidence(30) == 50
  assert scoring.rule_confidence(70) == 50
  assert scoring.rule_confidence(29) == 51
  assert scoring.rule_confidence(69) == 51
  assert scoring.rule_confidence(50) == 70
  assert scoring.rule_confidence(100) == 80
}

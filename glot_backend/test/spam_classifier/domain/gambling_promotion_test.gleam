import gleam/list
import gleam/option
import glot_backend/spam_classifier/domain/features
import glot_backend/spam_classifier/domain/scoring
import glot_core/snippet/snippet_model
import glot_core/snippet/spam_classification
import support/gambling_example
import support/integration/fixture

pub fn reported_betting_article_has_promotional_reason_test() {
  let fixture = fixture.integration_fixture([], [], option.None)
  let snippet =
    snippet_model.Snippet(
      ..fixture.snippet,
      title: gambling_example.title,
      stdin: "",
      run_instructions: option.None,
      files: [snippet_model.File("post.txt", gambling_example.text)],
    )
  let extracted = features.snippet(snippet, False)
  assert extracted.evidence.url_count == 1
  let result = scoring.assess(extracted.evidence)
  assert result.score == 90
  assert result.decision == spam_classification.Block
  assert result.reason_code == spam_classification.PromotionalContent
  assert list.contains(result.signals, scoring.GamblingPromotion)
  let runnable = features.snippet(snippet, True).evidence |> scoring.assess
  assert runnable.score == 50
  assert runnable.reason_code == spam_classification.PromotionalContent
}

pub fn promotion_requires_topic_call_to_action_and_destination_test() {
  let evidence = fn(text) { features.extract(text, False).evidence }
  assert evidence("Sports betting: Recommended service https://example.org").gambling_promotion
  assert evidence("CASINO: SIGN UP https://example.org").gambling_promotion
  assert !evidence("Sports betting: Recommended service").gambling_promotion
  assert !evidence("Sports betting probability calculation https://example.org").gambling_promotion
  assert !evidence("Visit https://docs.python.org for recommended tutorials").gambling_promotion
  assert !evidence(
    "casino_visit = recommended_betting_apps # https://example.org",
  ).gambling_promotion
}

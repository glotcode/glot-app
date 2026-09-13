import gleam/int
import gleam/list
import gleam/string
import glot_backend/spam_classifier/domain/features
import glot_backend/spam_classifier/domain/scoring
import glot_core/snippet/spam_classification
import support/link_dump_example

pub fn reported_link_dump_is_likely_spam_with_link_reason_test() {
  let extracted = features.extract(link_dump_example.text, False)
  assert extracted.evidence.url_count == 210
  let result = scoring.assess(extracted.evidence)
  assert result.score == 100
  assert result.decision == spam_classification.Block
  assert result.reason_code == spam_classification.LinkSpam
  assert list.contains(result.signals, scoring.NonRunnableLinkContent)
}

fn urls(count) {
  list.repeat(Nil, count)
  |> list.index_map(fn(_, index) {
    "https://example.org/" <> int.to_string(index)
  })
  |> string.join("\n")
}

pub fn link_dump_requires_volume_density_and_non_runnability_test() {
  let assess = fn(text, runnable) {
    features.extract(text, runnable).evidence |> scoring.assess
  }
  assert assess("References\n" <> urls(19), False).score == 55
  assert assess(urls(20), False).reason_code == spam_classification.LinkSpam
  assert assess("References\n" <> urls(20), True).score == 15
  assert assess(
      "References\n" <> string.repeat("https://example.org/\n", 100),
      False,
    ).score
    == 40
  let documentation =
    string.repeat("This documentation explains a code example. ", 100)
    <> urls(20)
  assert assess(documentation, False).score == 55
}

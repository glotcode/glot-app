import gleam/int
import gleam/io
import gleam/list
import glot_backend/spam_classifier/domain/features
import glot_backend/spam_classifier/domain/scoring
import glot_core/snippet/spam_classification
import support/gambling_example
import support/link_dump_example
import support/single_link_example

/// Synthetic and user-labeled examples. Labels describe content intent, not
/// expected rule output. This is a regression corpus, not an accuracy estimate.
pub type Example {
  Example(name: String, spam: Bool, runnable: Bool, text: String)
}

pub fn examples() -> List(Example) {
  [
    Example("sanitized link dump", True, False, link_dump_example.text),
    Example("sanitized single link", True, False, single_link_example.text),
    Example("sanitized betting promotion", True, False, gambling_example.text),
    Example("hello world", False, True, "print('hello world')"),
    Example("broken code", False, False, "def hello(: print('oops')"),
    Example(
      "documentation link",
      False,
      True,
      "# https://docs.python.org/3/ print('hello')",
    ),
    Example(
      "broken documentation example",
      False,
      False,
      "# https://docs.python.org/3/ def broken(:",
    ),
    Example(
      "two references",
      False,
      True,
      "# https://docs.python.org https://www.rust-lang.org",
    ),
    Example(
      "ordinary identifiers",
      False,
      False,
      "let buy_now = casino_loan + contact_me",
    ),
    Example(
      "hidden character comment",
      False,
      True,
      "# invisible\u{200b} marker print(1)",
    ),
    Example(
      "hidden comment and link",
      False,
      True,
      "# invisible\u{200b} marker https://example.com print(1)",
    ),
    Example("unicode program", False, True, "print('日本語 🦊 é')"),
    Example("website string", False, True, "url = 'www.example.com'"),
    Example(
      "contact address example",
      False,
      True,
      "link = 'mailto:developer@example.org'",
    ),
    Example(
      "security tutorial quotes promotion",
      False,
      True,
      "# Detect the phrase buy now or contact me at https://example.com https://example.org",
    ),
    Example(
      "sales promotion",
      True,
      False,
      "Buy now https://offers.example.com",
    ),
    Example(
      "runnable promotion",
      True,
      True,
      "# buy now contact me https://offers.example.com https://shop.example.org\nprint(1)",
    ),
    Example(
      "contact solicitation",
      True,
      False,
      "Contact me https://t.me/spammer",
    ),
    Example(
      "limited offer",
      True,
      True,
      "# Limited offer https://offers.example.com",
    ),
    Example(
      "defanged promotion",
      True,
      False,
      "Buy now hxxps://offers[.]example[.]com",
    ),
    Example(
      "defanged protocol only",
      True,
      False,
      "Buy now hxxps://offers.example.com",
    ),
    Example(
      "hidden bare domain",
      True,
      False,
      "Buy now off\u{200b}ers.example.com",
    ),
    Example(
      "hidden phrase",
      True,
      False,
      "bu\u{200b}y now https://offers.example.com",
    ),
    Example(
      "keyword repetition with link",
      True,
      False,
      "casino casino casino betting betting betting https://offers.example.com",
    ),
    Example(
      "promotional text without destination",
      True,
      False,
      "Buy now limited offer guaranteed profit",
    ),
    Example(
      "contact without destination",
      True,
      True,
      "# contact me dm me earn money",
    ),
    Example(
      "repetition without destination",
      True,
      False,
      "casino casino casino betting betting betting",
    ),
  ]
}

pub fn matrix() -> #(Int, Int, Int, Int) {
  list.fold(examples(), #(0, 0, 0, 0), fn(counts, example) {
    let result =
      features.extract(example.text, example.runnable).evidence
      |> scoring.assess
    let flagged = result.decision != spam_classification.Allow
    case example.spam, flagged {
      True, True -> #(counts.0 + 1, counts.1, counts.2, counts.3)
      False, True -> #(counts.0, counts.1 + 1, counts.2, counts.3)
      False, False -> #(counts.0, counts.1, counts.2 + 1, counts.3)
      True, False -> #(counts.0, counts.1, counts.2, counts.3 + 1)
    }
  })
}

pub fn main() -> Nil {
  let #(tp, fp, tn, fn_count) = matrix()
  io.println("local-v1 regression corpus; review/block = flagged")
  io.println(
    "TP="
    <> int.to_string(tp)
    <> " FP="
    <> int.to_string(fp)
    <> " TN="
    <> int.to_string(tn)
    <> " FN="
    <> int.to_string(fn_count),
  )
}

pub fn labeled_corpus_regression_test() {
  assert list.length(examples()) == 27
  // Preserve observed limitations instead of adjusting intent labels to scores.
  assert matrix() == #(12, 2, 10, 3)
}

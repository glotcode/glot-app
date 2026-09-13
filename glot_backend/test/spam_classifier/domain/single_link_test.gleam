import gleam/option
import glot_backend/spam_classifier/domain/features
import glot_backend/spam_classifier/domain/scoring
import glot_core/language
import glot_core/snippet/snippet_model
import glot_core/snippet/spam_classification
import support/integration/fixture
import support/single_link_example

pub fn reported_single_link_is_likely_spam_test() {
  let fixture = fixture.integration_fixture([], [], option.None)
  let snippet =
    snippet_model.Snippet(
      ..fixture.snippet,
      title: "Hello World",
      stdin: "",
      run_instructions: option.None,
      files: [snippet_model.File("main.asm", single_link_example.text)],
    )
  let assess = fn(snippet, runnable) {
    features.snippet(snippet, runnable).evidence |> scoring.assess
  }
  let result = assess(snippet, False)
  assert result.score == 100
  assert result.decision == spam_classification.Block
  assert result.reason_code == spam_classification.LinkSpam
  assert assess(snippet, True).score == 100
  let with_code =
    snippet_model.Snippet(..snippet, files: [
      snippet_model.File("main.py", "print(1)"),
      ..snippet.files
    ])
  assert assess(with_code, False).score == 40
  let with_empty_file =
    snippet_model.Snippet(..snippet, files: [
      snippet_model.File("empty.txt", ""),
      ..snippet.files
    ])
  assert assess(with_empty_file, False).score == 40
  let with_two_url_files =
    snippet_model.Snippet(..snippet, files: [
      snippet_model.File("second.txt", single_link_example.text),
      ..snippet.files
    ])
  assert assess(with_two_url_files, False).score == 100
  assert assess(with_two_url_files, True).score == 100
  assert assess(with_two_url_files, False).reason_code
    == spam_classification.LinkSpam
  let with_different_url_file =
    snippet_model.Snippet(..with_two_url_files, files: [
      snippet_model.File(
        "third.txt",
        "  https://example.org/one\nhttps://example.net/two\n",
      ),
      ..with_two_url_files.files
    ])
  assert assess(with_different_url_file, True).score == 100
  let with_third_code_file =
    snippet_model.Snippet(..with_two_url_files, files: [
      snippet_model.File("third.py", "print(1)"),
      ..with_two_url_files.files
    ])
  assert assess(with_third_code_file, False).score == 40
  assert assess(snippet_model.Snippet(..snippet, files: []), False).score == 0
  assert assess(snippet_model.Snippet(..snippet, stdin: "input data"), False).score
    == 100
  assert assess(
      snippet_model.Snippet(
        ..snippet,
        run_instructions: option.Some(language.RunInstructions(
          [],
          "python main.py",
        )),
      ),
      False,
    ).score
    == 100
}

pub fn links_only_rule_is_host_independent_and_requires_content_test() {
  let assess = fn(text) {
    features.extract(text, False).evidence |> scoring.assess
  }
  assert assess("https://example.org/reference").score == 100
  assert assess(" \n https://example.org/reference \n ").score == 100
  assert assess("# https://example.org/reference\ndef broken(:").score == 40
  assert assess("url = 'https://example.org/reference'").score == 40
  assert assess("").score == 0
}

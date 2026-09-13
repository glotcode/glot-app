import gleam/int
import gleam/list
import gleam/option
import gleam/string
import glot_backend/spam_classifier/domain/features
import glot_backend/spam_classifier/domain/scoring
import glot_backend/spam_classifier/domain/similarity
import glot_core/language
import glot_core/snippet/snippet_model
import glot_core/snippet/spam_classification
import support/integration/fixture

pub fn url_forms_are_detected_without_overlapping_matches_test() {
  let result =
    features.extract(
      "https://www.example.com/path www.example.com/path example.com/path mailto:a@example.org tel:+123 tg://resolve?domain=hello",
      True,
    )
  assert list.length(result.urls) == 4
  assert result.evidence.obfuscated_url == False
}

pub fn hidden_characters_alone_do_not_imply_spam_test() {
  let result =
    features.extract(
      "let buy_now = 1 // invisible\u{200b} marker https://docs.python.org",
      True,
    )
  assert result.evidence.promotional_phrase == False
  assert result.evidence.obfuscated_url == False
  assert scoring.assess(result.evidence).score == 0
}

pub fn defanged_and_hidden_urls_are_detected_test() {
  let defanged = features.extract("BUY NOW hxxps://example[.]com", False)
  assert defanged.evidence.obfuscated_url
  assert scoring.assess(defanged.evidence).decision == spam_classification.Block
  let hidden = features.extract("buy now https://exa\u{200b}mple.com", True)
  assert hidden.evidence.obfuscated_url
  assert hidden.urls == ["example.com"]
}

pub fn phrase_signals_scan_beyond_similarity_limit_test() {
  let payload =
    list.repeat("ordinary ", 16_384)
    |> list.append(["buy now https://example.com"])
  let result = features.extract(string.join(payload, ""), True)
  assert list.length(result.tokens) == 16_384
  assert result.evidence.promotional_phrase
  assert result.evidence.url_count == 1
}

pub fn url_substitutions_have_identical_fingerprints_test() {
  let text =
    "this tutorial explains how to build a simple application with a function that prints a message and returns the result see "
  let left = features.extract(text <> "https://example.com/one", True)
  let right = features.extract(text <> "https://different.org/two", True)
  let left = similarity.fingerprint(left.tokens)
  let right = similarity.fingerprint(right.tokens)
  assert left == right
  assert list.length(left.signature) == 64
  assert list.length(left.bands) == 16
  assert similarity.is_neighbor(left, right)
  assert similarity.jaccard(left, right) == 1.0
}

pub fn short_snippets_never_qualify_test() {
  let short = similarity.fingerprint(["hello", "world", "example"])
  assert similarity.is_neighbor(short, short) == False
}

pub fn defanged_protocol_and_hidden_bare_domain_are_obfuscation_test() {
  assert features.extract("hxxps://example.com", True).evidence.obfuscated_url
  assert features.extract("exa\u{200b}mple.com", True).evidence.obfuscated_url
  assert !features.extract("ordinary\u{200b} text example.com", True).evidence.obfuscated_url
}

pub fn maximum_valid_payload_scans_all_fields_but_caps_similarity_test() {
  let test_fixture =
    fixture.integration_fixture(
      next_uuids: [],
      jobs: [],
      account_delete_job_id: option.None,
    )
  let repeated = string.repeat("a ", 50_000)
  let files =
    list.repeat(Nil, 10)
    |> list.index_map(fn(_, index) {
      snippet_model.File(
        int.to_string(index) <> string.repeat("x", 254),
        case index {
          9 ->
            string.slice(
              repeated,
              0,
              100_000 - string.length(" https://example.com/path "),
            )
            <> " https://example.com/path "
          _ -> repeated
        },
      )
    })
  let snippet =
    snippet_model.Snippet(
      ..test_fixture.snippet,
      title: "BUY NOW " <> string.repeat("x", 192),
      stdin: "CONTACT ME " <> string.repeat("x", 19_989),
      run_instructions: option.Some(language.RunInstructions(
        list.repeat(string.repeat("b", 2000), 5),
        string.repeat("r", 2000),
      )),
      files: files,
    )
  assert snippet_model.validate_fields(
      snippet.title,
      snippet.stdin,
      snippet.run_instructions,
      snippet.files,
    )
    == Ok(Nil)
  let extracted = features.snippet(snippet, True)
  assert extracted.evidence.promotional_phrase
  assert extracted.evidence.contact_solicitation
  assert extracted.evidence.url_count == 1
  assert list.length(extracted.tokens) == 16_384
  let fingerprint = similarity.fingerprint(extracted.tokens)
  assert list.length(fingerprint.signature) == 64
  assert list.length(fingerprint.bands) == 16
  assert scoring.assess(extracted.evidence).score == 60
}

pub fn near_duplicate_tutorials_are_neighbors_without_spam_signals_test() {
  let words = [
    "this", "tutorial", "explains", "how", "to", "build", "a", "simple",
    "application", "with", "functions", "that", "print", "messages", "and",
    "return", "results", "while", "teaching", "basic", "programming", "concepts",
    "using", "small", "examples", "for", "new", "students", "learning", "python",
    "today",
  ]
  let left = features.extract(string.join(words, " "), True)
  let right =
    features.extract(string.join(list.append(words, ["enjoy"]), " "), True)
  let left_fingerprint = similarity.fingerprint(left.tokens)
  let right_fingerprint = similarity.fingerprint(right.tokens)
  assert similarity.is_neighbor(left_fingerprint, right_fingerprint)
  assert list.any(left_fingerprint.bands, fn(band) {
    list.contains(right_fingerprint.bands, band)
  })
  assert scoring.assess(left.evidence).score == 0
  assert scoring.assess(right.evidence).score == 0
}

pub fn maximum_similarity_work_is_bounded_and_deterministic_test() {
  let tokens = list.repeat("tutorial", 20_000)
  let first = similarity.fingerprint(tokens)
  let second = similarity.fingerprint(list.take(tokens, 16_384))
  assert first == second
  assert first.token_count == 16_384
  assert list.length(first.trigram_hashes) == 1
  assert list.length(first.signature) == 64
  assert list.length(first.bands) == 16
}

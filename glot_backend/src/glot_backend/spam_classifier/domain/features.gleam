import gleam/dict
import gleam/list
import gleam/option
import gleam/regexp
import gleam/string
import glot_backend/spam_classifier/domain/normalization
import glot_backend/spam_classifier/domain/scoring
import glot_core/snippet/snippet_model.{type Snippet}

pub type Features {
  Features(evidence: scoring.Evidence, urls: List(String), tokens: List(String))
}

const url_pattern = "(?:https?://|www\\.)[^\\s<>\"'{}\\[\\]]+|(?:mailto:|tel:|tg://)[^\\s<>\"']+|(?<![\\w_])(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+(?:com|org|net|io|dev|app|edu|gov|co|uk|de|fr|no|me|gg|ly|xyz|online|site|shop|info|biz|ai|ru|cn|in|au|us|ca)(?![a-z0-9_])(?:/[^\\s<>\"'{}\\[\\]]*)?"

pub fn snippet(snippet: Snippet, is_runnable: Bool) -> Features {
  let instructions = case snippet.run_instructions {
    option.None -> []
    option.Some(value) -> [value.run_command, ..value.build_commands]
  }
  let fields =
    [snippet.title, snippet.stdin, ..instructions]
    |> list.append(
      list.flat_map(snippet.files, fn(file) { [file.name, file.content] }),
    )
  let extracted = extract(string.join(fields, "\n"), is_runnable)
  let files_links_only =
    !list.is_empty(snippet.files)
    && list.all(snippet.files, fn(file) { links_only(file.content) })
  Features(
    ..extracted,
    evidence: scoring.Evidence(..extracted.evidence, files_links_only:),
  )
}

pub fn extract(payload: String, is_runnable: Bool) -> Features {
  let normalized = normalization.text(payload)
  let refanged = normalization.refang(normalized)
  let assert Ok(pattern) = regexp.from_string(url_pattern)
  let matches = regexp.scan(pattern, refanged)
  let urls = destinations(matches)
  let tokens = normalization.words(normalized)
  let promotional =
    phrases(tokens, [
      "buy now", "click here", "limited offer", "earn money", "work from home",
      "guaranteed profit", "free spins", "best casino", "cheap loans",
      "buy backlinks", "seo services",
    ])
  let contact =
    phrases(tokens, [
      "contact me", "contact us", "dm me", "reach me", "message me",
      "join telegram", "join our telegram", "whatsapp me",
    ])
  let stuffing = keyword_stuffing(tokens)
  let original_matches = regexp.scan(pattern, string.lowercase(payload))
  let assert Ok(defanged_protocol) = regexp.from_string("hxxps?://[^\\s]+")
  let obfuscated =
    regexp.check(defanged_protocol, normalized)
    || urls != destinations(original_matches)
    || list.length(matches) > list.length(original_matches)
    || list.any(original_matches, fn(match) {
      normalization.text(match.content) != match.content
      || normalization.refang(match.content) != match.content
    })
  Features(
    evidence: scoring.Evidence(
      is_runnable:,
      url_count: list.length(urls),
      files_links_only: links_only(refanged),
      url_dominated: list.fold(matches, 0, fn(total, match) {
        total + string.length(match.content)
      })
        * 5
        >= string.length(refanged) * 4,
      promotional_phrase: promotional,
      gambling_promotion: !list.is_empty(urls)
        && phrases(tokens, [
        "casino",
        "betting tips",
        "betting apps",
        "place bets",
        "sports betting",
      ])
        && phrases(tokens, [
        "recommended",
        "visit",
        "sign up",
        "join now",
        "register now",
      ]),
      contact_solicitation: contact,
      obfuscated_url: obfuscated,
      keyword_stuffing: stuffing,
      independently_suspicious_neighbors: 0,
    ),
    urls:,
    tokens: regexp.replace(pattern, refanged, " urlplaceholder ")
      |> normalization.words
      |> list.take(16_384),
  )
}

fn phrases(tokens: List(String), phrases: List(String)) -> Bool {
  let sentence = " " <> string.join(tokens, " ") <> " "
  list.any(phrases, fn(phrase) {
    string.contains(sentence, " " <> phrase <> " ")
  })
}

fn keyword_stuffing(tokens: List(String)) -> Bool {
  let counts =
    list.fold(tokens, dict.new(), fn(counts, token) {
      let count = case dict.get(counts, token) {
        Ok(count) -> count
        Error(_) -> 0
      }
      dict.insert(counts, token, count + 1)
    })
  let repeated =
    ["casino", "betting", "backlinks", "forex", "viagra", "loans"]
    |> list.filter(fn(word) {
      case dict.get(counts, word) {
        Ok(count) -> count >= 3
        Error(_) -> False
      }
    })
  list.length(repeated) >= 2
}

fn destinations(matches: List(regexp.Match)) -> List(String) {
  matches
  |> list.map(fn(match) {
    match.content
    |> normalization.replace("[.,;:!?)]+$", "")
    |> normalization.replace("^https?://", "")
    |> normalization.replace("^www\\.", "")
    |> normalization.replace("/$", "")
  })
  |> list.fold(dict.new(), fn(acc, url) { dict.insert(acc, url, Nil) })
  |> dict.keys
  |> list.sort(string.compare)
}

// A URL-only file has no content except URLs and surrounding whitespace.
fn links_only(payload: String) -> Bool {
  let normalized = payload |> normalization.text |> normalization.refang
  let assert Ok(pattern) = regexp.from_string(url_pattern)
  string.trim(normalized) != ""
  && string.trim(regexp.replace(pattern, normalized, "")) == ""
}

import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_core/language
import glot_core/snippet/snippet_model.{type Snippet}

pub type Decision {
  Allow
  Review
  Block
}

pub type ReasonCode {
  None
  PromotionalContent
  ContactSolicitation
  LinkSpam
  SeoSpam
  ScamOrPhishing
  ObfuscatedSpam
  KeywordStuffing
  Ambiguous
}

pub type ClassificationResult {
  ClassificationResult(
    decision: Decision,
    confidence: Int,
    reason_code: ReasonCode,
    classified_at: Timestamp,
  )
}

pub type ClassificationFailure {
  ClassificationFailure(error_code: String, failed_at: Timestamp)
}

pub type ClassificationMetadata {
  ClassificationMetadata(
    decision: option.Option(Decision),
    confidence: option.Option(Int),
    reason_code: option.Option(ReasonCode),
    classified_at: option.Option(Timestamp),
    attempts: Int,
    last_error: option.Option(String),
    failed_at: option.Option(Timestamp),
  )
}

pub type StoreResult {
  Stored
  Stale
}

pub type Candidate {
  Candidate(snippet: Snippet, expected_updated_at: Timestamp, attempts: Int)
}

pub type ServiceResponse {
  ServiceResponse(decision: Decision, confidence: Int, reason_code: ReasonCode)
}

pub fn decision_to_string(value: Decision) -> String {
  case value {
    Allow -> "allow"
    Review -> "review"
    Block -> "block"
  }
}

pub fn decision_from_string(value: String) -> Result(Decision, String) {
  case value {
    "allow" -> Ok(Allow)
    "review" -> Ok(Review)
    "block" -> Ok(Block)
    _ -> Error("Invalid spam classification decision: " <> value)
  }
}

pub fn reason_code_to_string(value: ReasonCode) -> String {
  case value {
    None -> "none"
    PromotionalContent -> "promotional_content"
    ContactSolicitation -> "contact_solicitation"
    LinkSpam -> "link_spam"
    SeoSpam -> "seo_spam"
    ScamOrPhishing -> "scam_or_phishing"
    ObfuscatedSpam -> "obfuscated_spam"
    KeywordStuffing -> "keyword_stuffing"
    Ambiguous -> "ambiguous"
  }
}

pub fn reason_code_from_string(value: String) -> Result(ReasonCode, String) {
  case value {
    "none" -> Ok(None)
    "promotional_content" -> Ok(PromotionalContent)
    "contact_solicitation" -> Ok(ContactSolicitation)
    "link_spam" -> Ok(LinkSpam)
    "seo_spam" -> Ok(SeoSpam)
    "scam_or_phishing" -> Ok(ScamOrPhishing)
    "obfuscated_spam" -> Ok(ObfuscatedSpam)
    "keyword_stuffing" -> Ok(KeywordStuffing)
    "ambiguous" -> Ok(Ambiguous)
    _ -> Error("Invalid spam classification reason code: " <> value)
  }
}

pub fn confidence_from_int(value: Int) -> Result(Int, String) {
  case value >= 0 && value <= 100 {
    True -> Ok(value)
    False ->
      Error(
        "Confidence must be between 0 and 100, got " <> int.to_string(value),
      )
  }
}

pub fn attempts_from_int(value: Int) -> Result(Int, String) {
  case value >= 0 {
    True -> Ok(value)
    False ->
      Error(
        "Classification attempts cannot be negative, got "
        <> int.to_string(value),
      )
  }
}

pub fn service_response_decoder() -> decode.Decoder(ServiceResponse) {
  use decision <- decode.field("decision", decision_decoder())
  use confidence <- decode.field("confidence", confidence_decoder())
  use reason_code <- decode.field("reason_code", reason_code_decoder())
  decode.success(ServiceResponse(decision:, confidence:, reason_code:))
}

pub fn decision_decoder() -> decode.Decoder(Decision) {
  decode.then(decode.string, fn(value) {
    case decision_from_string(value) {
      Ok(decision) -> decode.success(decision)
      Error(message) -> decode.failure(Allow, message)
    }
  })
}

pub fn confidence_decoder() -> decode.Decoder(Int) {
  decode.then(decode.int, fn(value) {
    case confidence_from_int(value) {
      Ok(confidence) -> decode.success(confidence)
      Error(message) -> decode.failure(value, message)
    }
  })
}

pub fn reason_code_decoder() -> decode.Decoder(ReasonCode) {
  decode.then(decode.string, fn(value) {
    case reason_code_from_string(value) {
      Ok(reason) -> decode.success(reason)
      Error(message) -> decode.failure(None, message)
    }
  })
}

pub fn encode_request(snippet: Snippet) -> json.Json {
  json.object([
    #(
      "snippet",
      json.object([
        #("title", json.string(snippet.title)),
        #("language", json.string(language.to_string(snippet.language))),
        #("stdin", json.string(snippet.stdin)),
        #(
          "runInstructions",
          json.nullable(
            snippet.run_instructions,
            language.encode_run_instructions,
          ),
        ),
        #("files", json.array(snippet.files, snippet_model.encode_file)),
      ]),
    ),
  ])
}

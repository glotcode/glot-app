import gleam/int
import gleam/list
import glot_core/snippet/spam_classification

/// Versioned defaults, not a calibrated prediction of spam probability.
pub const version = "local-v1"

pub type Evidence {
  Evidence(
    is_runnable: Bool,
    url_count: Int,
    url_dominated: Bool,
    files_links_only: Bool,
    promotional_phrase: Bool,
    gambling_promotion: Bool,
    contact_solicitation: Bool,
    obfuscated_url: Bool,
    keyword_stuffing: Bool,
    independently_suspicious_neighbors: Int,
  )
}

pub type Signal {
  NonRunnableUrl
  PromotionalUrl
  GamblingPromotion
  ContactUrl
  MultipleUrls
  NonRunnableLinkContent
  UrlOnlySnippet
  ObfuscatedUrl
  KeywordStuffing
  SimilarCampaign
}

pub type Assessment {
  Assessment(
    score: Int,
    decision: spam_classification.Decision,
    confidence: Int,
    reason_code: spam_classification.ReasonCode,
    signals: List(Signal),
  )
}

pub fn assess(evidence: Evidence) -> Assessment {
  let has_url = evidence.url_count > 0
  let suspicious =
    evidence.promotional_phrase
    || evidence.gambling_promotion
    || evidence.contact_solicitation
    || evidence.obfuscated_url
    || evidence.keyword_stuffing
  let signals =
    [
      #(!evidence.is_runnable && has_url, NonRunnableUrl),
      #(evidence.promotional_phrase && has_url, PromotionalUrl),
      #(evidence.gambling_promotion && has_url, GamblingPromotion),
      #(evidence.contact_solicitation && has_url, ContactUrl),
      #(evidence.url_count > 1, MultipleUrls),
      #(
        !evidence.is_runnable
          && evidence.url_count >= 20
          && evidence.url_dominated,
        NonRunnableLinkContent,
      ),
      #(evidence.files_links_only, UrlOnlySnippet),
      #(evidence.obfuscated_url, ObfuscatedUrl),
      #(evidence.keyword_stuffing, KeywordStuffing),
      #(
        evidence.independently_suspicious_neighbors >= 2 && suspicious,
        SimilarCampaign,
      ),
    ]
    |> list.filter_map(fn(entry) {
      case entry.0 {
        True -> Ok(entry.1)
        False -> Error(Nil)
      }
    })
  let score =
    list.fold(signals, 0, fn(total, signal) { total + points(signal) })
    |> int.min(100)
  let decision = case score {
    score if score < 30 -> spam_classification.Allow
    score if score < 70 -> spam_classification.Review
    _ -> spam_classification.Block
  }
  let strongest = case signals {
    [] -> NonRunnableUrl
    [first, ..rest] ->
      list.fold(rest, first, fn(best, signal) {
        case points(signal) > points(best) {
          True -> signal
          False -> best
        }
      })
  }
  Assessment(
    score:,
    decision:,
    confidence: rule_confidence(score),
    reason_code: case decision {
      spam_classification.Allow -> spam_classification.None
      _ -> reason(strongest)
    },
    signals:,
  )
}

pub fn rule_confidence(score: Int) -> Int {
  50 + int.min(int.absolute_value(score - 30), int.absolute_value(score - 70))
  |> int.min(99)
}

pub fn points(signal: Signal) -> Int {
  case signal {
    NonRunnableUrl -> 40
    NonRunnableLinkContent | GamblingPromotion -> 50
    UrlOnlySnippet -> 100
    PromotionalUrl | ContactUrl | SimilarCampaign -> 30
    MultipleUrls -> 15
    ObfuscatedUrl | KeywordStuffing -> 20
  }
}

pub fn name(signal: Signal) -> String {
  case signal {
    NonRunnableUrl -> "non_runnable_url"
    PromotionalUrl -> "promotional_url"
    GamblingPromotion -> "gambling_promotion"
    ContactUrl -> "contact_url"
    MultipleUrls -> "multiple_urls"
    NonRunnableLinkContent -> "non_runnable_link_content"
    UrlOnlySnippet -> "url_only_snippet"
    ObfuscatedUrl -> "obfuscated_url"
    KeywordStuffing -> "keyword_stuffing"
    SimilarCampaign -> "similar_campaign"
  }
}

fn reason(signal: Signal) -> spam_classification.ReasonCode {
  case signal {
    NonRunnableUrl -> spam_classification.Ambiguous
    PromotionalUrl | GamblingPromotion | SimilarCampaign ->
      spam_classification.PromotionalContent
    ContactUrl -> spam_classification.ContactSolicitation
    MultipleUrls | NonRunnableLinkContent | UrlOnlySnippet ->
      spam_classification.LinkSpam
    ObfuscatedUrl -> spam_classification.ObfuscatedSpam
    KeywordStuffing -> spam_classification.KeywordStuffing
  }
}

import glot_backend/spam_classifier/model/classification.{type Classification}
import glot_backend/spam_classifier/model/config.{type Config}
import glot_backend/spam_classifier/model/fingerprint
import glot_backend/system/effect/error
import glot_core/snippet/spam_classification

pub type Effect(next) {
  IndexBatch(fn(Result(fingerprint.IndexReport, error.Error)) -> next)
  Classify(
    Config,
    spam_classification.ServiceRequest,
    fn(Result(Classification, error.Error)) -> next,
  )
}

pub fn map(effect: Effect(a), f: fn(a) -> b) -> Effect(b) {
  case effect {
    IndexBatch(next) -> IndexBatch(fn(value) { f(next(value)) })
    Classify(config, request, next) ->
      Classify(config, request, fn(value) { f(next(value)) })
  }
}

pub type EffectName {
  ClassifySnippetEffectName
  IndexBatchEffectName
}

pub fn effect_name_to_string(name: EffectName) -> String {
  case name {
    ClassifySnippetEffectName -> "classify_snippet"
    IndexBatchEffectName -> "index_snippet_fingerprints"
  }
}

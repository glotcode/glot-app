import glot_backend/spam_classifier/model/config.{type Config}
import glot_backend/system/effect/error
import glot_core/snippet/snippet_model.{type Snippet}
import glot_core/snippet/spam_classification

pub type Effect(next) {
  Classify(
    Config,
    Snippet,
    fn(Result(#(spam_classification.ServiceResponse, String), error.Error)) ->
      next,
  )
}

pub fn map(effect: Effect(a), f: fn(a) -> b) -> Effect(b) {
  case effect {
    Classify(config, snippet, next) ->
      Classify(config, snippet, fn(value) { f(next(value)) })
  }
}

pub type EffectName {
  ClassifySnippetEffectName
}

pub fn effect_name_to_string(_name: EffectName) -> String {
  "classify_snippet"
}

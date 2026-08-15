import glot_backend/spam_classifier/effect/algebra
import glot_backend/spam_classifier/model/config.{type Config}
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types
import glot_core/snippet/snippet_model.{type Snippet}
import glot_core/snippet/spam_classification

pub fn classify(
  config: Config,
  snippet: Snippet,
) -> program_types.Program(#(spam_classification.ServiceResponse, String)) {
  program.perform(
    program_types.SpamClassifierEffect(algebra.Classify(
      config,
      snippet,
      program.from_result,
    )),
  )
}

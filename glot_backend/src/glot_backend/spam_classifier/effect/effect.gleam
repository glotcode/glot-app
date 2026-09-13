import gleam/int
import gleam/option
import glot_backend/spam_classifier/domain/scoring
import glot_backend/spam_classifier/effect/algebra
import glot_backend/spam_classifier/model/classification.{type Classification}
import glot_backend/spam_classifier/model/config.{type Config}
import glot_backend/spam_classifier/model/fingerprint
import glot_backend/system/effect/basic/basic_effect
import glot_backend/system/effect/log
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types
import glot_core/helpers/timestamp_helpers
import glot_core/snippet/classifier_provider
import glot_core/snippet/spam_classification

pub fn classify(
  config: Config,
  request: spam_classification.ServiceRequest,
) -> program_types.Program(Classification) {
  use started <- program.and_then(basic_effect.system_time())
  use outcome <- program.and_then(
    program.perform(
      program_types.SpamClassifierEffect(algebra.Classify(
        config,
        request,
        program.succeed,
      )),
    ),
  )
  use finished <- program.and_then(basic_effect.system_time())
  use _ <- program.and_then(
    basic_effect.info(
      log.from_list([
        log.uuid("snippet_id", request.snippet.id),
        log.string(
          "spam_classifier_provider",
          classifier_provider.to_string(config.provider),
        ),
        log.optional_string("spam_classifier_version", case config.provider {
          classifier_provider.Local -> option.Some(scoring.version)
          classifier_provider.External -> option.None
        }),
        log.int(
          "spam_classifier_duration_ms",
          int.max(
            0,
            {
              timestamp_helpers.to_microseconds(finished)
              - timestamp_helpers.to_microseconds(started)
            }
              / 1000,
          ),
        ),
        log.bool("spam_classifier_succeeded", case outcome {
          Ok(_) -> True
          Error(_) -> False
        }),
      ]),
    ),
  )
  program.from_result(outcome)
}

pub fn index_batch() -> program_types.Program(fingerprint.IndexReport) {
  program.perform(
    program_types.SpamClassifierEffect(algebra.IndexBatch(program.from_result)),
  )
}

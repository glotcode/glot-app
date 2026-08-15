import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_backend/app_config/effect/effect as app_config_effect
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/snippet/effect/effect as snippet_effect
import glot_backend/spam_classifier/effect/effect as classifier_effect
import glot_backend/system/effect/basic/basic_effect
import glot_backend/system/effect/error
import glot_backend/system/effect/error/infra_error
import glot_backend/system/effect/error/resource_error
import glot_backend/system/effect/log
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/context.{type Context}
import glot_core/snippet/snippet_model.{type Snippet}
import glot_core/snippet/spam_classification

type ClassificationAttempt {
  Classified(#(spam_classification.ServiceResponse, String))
  SnippetRejected(error_code: String)
}

pub fn classify_next(_ctx: Context) -> Program(Bool) {
  use config <- program.and_then(app_config_effect.get_dynamic_config())
  case dynamic_config.spam_classifier_config(config) {
    option.None ->
      program.fail(error.resource(resource_error.SpamClassifierConfigNotFound))
    option.Some(config) -> {
      use candidate <- program.and_then(
        snippet_effect.get_newest_unclassified(),
      )
      case candidate {
        option.None -> program.succeed(False)
        option.Some(candidate) -> classify_candidate(config, candidate)
      }
    }
  }
}

fn classify_candidate(
  config,
  candidate: spam_classification.Candidate,
) -> Program(Bool) {
  let spam_classification.Candidate(snippet, expected_updated_at) = candidate
  use attempt <- program.and_then(
    classifier_effect.classify(config, snippet)
    |> program.map(Classified)
    |> program.attempt(fn(err) {
      case snippet_failure_code(err) {
        option.Some(error_code) -> program.succeed(SnippetRejected(error_code))
        option.None -> program.fail(err)
      }
    }),
  )
  case attempt {
    Classified(response) ->
      store_classification(snippet, expected_updated_at, response)
    SnippetRejected(error_code) ->
      quarantine_snippet(snippet, expected_updated_at, error_code)
  }
}

fn store_classification(
  snippet: Snippet,
  expected_updated_at: Timestamp,
  response: #(spam_classification.ServiceResponse, String),
) -> Program(Bool) {
  let #(service_response, request_id) = response
  use _ <- program.and_then(
    basic_effect.info(
      log.from_list([
        log.uuid("snippet_id", snippet.id),
        log.string("spam_classifier_request_id", request_id),
      ]),
    ),
  )
  use classified_at <- program.and_then(basic_effect.system_time())
  use _ <- program.and_then(snippet_effect.store_spam_classification(
    snippet.id,
    expected_updated_at,
    spam_classification.ClassificationResult(
      decision: service_response.decision,
      confidence: service_response.confidence,
      reason_code: service_response.reason_code,
      classified_at: classified_at,
    ),
  ))
  program.succeed(True)
}

fn quarantine_snippet(
  snippet: Snippet,
  expected_updated_at: Timestamp,
  error_code: String,
) -> Program(Bool) {
  use _ <- program.and_then(
    basic_effect.warn(
      log.from_list([
        log.uuid("snippet_id", snippet.id),
        log.string("spam_classification_error", error_code),
      ]),
    ),
  )
  use failed_at <- program.and_then(basic_effect.system_time())
  use _ <- program.and_then(snippet_effect.store_spam_classification_failure(
    snippet.id,
    expected_updated_at,
    spam_classification.ClassificationFailure(error_code, failed_at),
  ))
  program.succeed(True)
}

fn snippet_failure_code(err: error.Error) -> option.Option(String) {
  case err {
    error.InfraError(infra_error.SpamClassifierError(infra_error.SpamClassifierRequestFailed(
      _,
      _,
      infra_error.SnippetFailure,
    ))) -> option.Some("invalid_payload")
    _ -> option.None
  }
}

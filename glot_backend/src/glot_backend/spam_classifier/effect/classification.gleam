import gleam/float
import gleam/int
import gleam/list
import gleam/option
import gleam/order
import gleam/result
import gleam/string
import gleam/time/timestamp
import glot_backend/spam_classifier/domain/features
import glot_backend/spam_classifier/domain/scoring
import glot_backend/spam_classifier/domain/similarity
import glot_backend/spam_classifier/model/classification.{type Classification}
import glot_backend/spam_classifier/model/config.{type Config}
import glot_backend/spam_classifier/model/fingerprint
import glot_backend/spam_classifier/ports.{type Ports}
import glot_backend/system/effect/error.{type Error}
import glot_backend/system/request/context.{type Context}
import glot_core/snippet/classification_explanation
import glot_core/snippet/classifier_provider
import glot_core/snippet/spam_classification
import youid/uuid

pub fn run(
  config: Config,
  request: spam_classification.ServiceRequest,
  ports: Ports,
  ctx: Context,
) -> Result(Classification, Error) {
  let extracted = features.snippet(request.snippet, request.is_runnable)
  let signature = similarity.fingerprint(extracted.tokens)
  let evidence = extracted.evidence
  // A single guarded SQL statement locks the revision while storing its bands.
  // External calls and all feature extraction/scoring run outside that statement.
  use _ <- result.try(
    ports.storage.store(fingerprint.StoredFingerprint(
      snippet_id: request.snippet.id,
      revision: request.snippet.updated_at,
      version: scoring.version,
      fingerprint: signature,
      independently_suspicious: evidence.promotional_phrase
        || evidence.gambling_promotion
        || evidence.obfuscated_url
        || evidence.keyword_stuffing,
      urls: extracted.urls,
    )),
  )
  case config.provider {
    classifier_provider.External ->
      ports.external.classify(
        config,
        request,
        context.remaining_timeout_ms(ctx)
          |> option.map(fn(value) { int.min(value, 3_330_000) })
          |> option.unwrap(3_330_000),
      )
      |> result.map(fn(value) {
        classification.Classification(
          value.0,
          value.1,
          option.Some(
            classification_explanation.Explanation(
              provider: classifier_provider.External,
              version: option.None,
              score: option.None,
              signals: [],
              neighbors: [],
            ),
          ),
        )
      })
    classifier_provider.Local -> {
      use candidates <- result.try(ports.storage.candidates(
        scoring.version,
        signature.bands,
        request.snippet.id,
      ))
      let verified =
        candidates
        |> list.take(similarity.candidate_limit)
        |> list.filter(fn(candidate) {
          candidate.snippet_id != request.snippet.id
          && similarity.is_neighbor(signature, candidate.fingerprint)
        })
        |> list.map(fn(candidate) {
          #(candidate, similarity.jaccard(signature, candidate.fingerprint))
        })
        |> list.sort(fn(left, right) {
          case float.compare(right.1, left.1) {
            order.Eq ->
              case timestamp.compare(right.0.revision, left.0.revision) {
                order.Eq ->
                  string.compare(
                    uuid.to_string(right.0.snippet_id),
                    uuid.to_string(left.0.snippet_id),
                  )
                value -> value
              }
            value -> value
          }
        })
      let suspicious_neighbors =
        list.count(verified, fn(entry) { entry.0.independently_suspicious })
      let assessment =
        scoring.assess(
          scoring.Evidence(
            ..evidence,
            independently_suspicious_neighbors: suspicious_neighbors,
          ),
        )
      Ok(classification.Classification(
        response: spam_classification.ServiceResponse(
          assessment.decision,
          assessment.confidence,
          assessment.reason_code,
        ),
        request_id: "",
        explanation: option.Some(classification_explanation.Explanation(
          provider: classifier_provider.Local,
          version: option.Some(scoring.version),
          score: option.Some(assessment.score),
          signals: list.map(assessment.signals, scoring.name),
          neighbors: verified
            |> list.take(5)
            |> list.map(fn(entry) {
              classification_explanation.Neighbor(
                uuid.to_string(entry.0.snippet_id),
                entry.0.slug,
                entry.0.revision,
                entry.1,
              )
            }),
        )),
      ))
    }
  }
}

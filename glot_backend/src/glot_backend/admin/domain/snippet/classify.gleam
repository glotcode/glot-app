import gleam/dynamic.{type Dynamic}
import gleam/option
import glot_backend/app_config/effect/effect as app_config_effect
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/auth/domain/session/current as current_session
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/snippet/effect/effect as snippet_effect
import glot_backend/spam_classifier/effect/effect as classifier_effect
import glot_backend/system/effect/basic/basic_effect
import glot_backend/system/effect/error
import glot_backend/system/effect/error/resource_error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/effect/transaction/transaction_effect
import glot_backend/system/effect/transaction/transaction_program
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/admin/snippet_dto.{
  type GetSnippetRequest, type GetSnippetResponse,
}
import glot_core/admin_action
import glot_core/api_action
import glot_core/snippet/spam_classification

pub fn classify_snippet(
  request_ctx: RequestContext,
  request: GetSnippetRequest,
) -> Program(GetSnippetResponse) {
  use session <- program.and_then(current_session.require_session(request_ctx))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.admin(admin_action.ClassifyAdminSnippetAction),
    actor: api_action_policy.actor_from_user(option.Some(session.user)),
  ))
  use config <- program.and_then(app_config_effect.get_dynamic_config())
  use classifier_config <- program.and_then(
    dynamic_config.spam_classifier_config(config)
    |> program.from_option(error.resource(
      resource_error.SpamClassifierConfigNotFound,
    )),
  )
  use snippet <- program.and_then(
    snippet_effect.get_admin_by_slug(request.slug)
    |> program.require(error.resource(resource_error.SnippetNotFound)),
  )
  let identity = snippet.snippet.identity
  use is_runnable <- program.and_then(
    snippet.runnability.is_runnable
    |> program.from_option(error.resource(
      resource_error.SnippetRunnabilityUnchecked,
    )),
  )
  use response <- program.and_then(classifier_effect.classify(
    classifier_config,
    spam_classification.ServiceRequest(snippet: identity, is_runnable:),
  ))
  let #(service_response, _) = response
  use classified_at <- program.and_then(basic_effect.system_time())
  let classification =
    spam_classification.ClassificationResult(
      decision: service_response.decision,
      confidence: service_response.confidence,
      reason_code: service_response.reason_code,
      classified_at: classified_at,
    )

  use _ <- program.and_then(
    transaction_program.sequence([
      update_classification(identity.id, identity.updated_at, classification),
      user_action_effect.create_user_action_tx(user_action),
    ])
    |> transaction_effect.run(),
  )

  use updated <- program.and_then(
    snippet_effect.get_admin_by_slug(request.slug)
    |> program.require(error.resource(resource_error.SnippetNotFound)),
  )
  program.succeed(snippet_dto.from_admin_snippet(updated))
}

fn update_classification(id, expected_updated_at, classification) {
  use store_result <- transaction_program.and_then(
    snippet_effect.update_spam_classification_tx(
      id,
      expected_updated_at,
      classification,
    ),
  )
  case store_result {
    spam_classification.Stored -> transaction_program.succeed(Nil)
    spam_classification.Stale ->
      transaction_program.fail(error.resource(
        resource_error.SnippetClassificationStale,
      ))
  }
}

pub fn request_from_dynamic(data: Dynamic) -> Program(GetSnippetRequest) {
  program.decode_dynamic(data, snippet_dto.get_request_decoder())
}

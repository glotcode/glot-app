import gleam/option
import gleam/result
import glot_backend/auth/domain/session/current as current_session
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/snippet/effect/effect as snippet_effect
import glot_backend/system/effect/basic/basic_effect
import glot_backend/system/effect/error
import glot_backend/system/effect/error/resource_error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/effect/transaction/transaction_effect
import glot_backend/system/effect/transaction/transaction_program
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/admin/spam_review_dto.{
  type ListRequest, type ReviewSnippet, type SaveRequest,
}
import glot_core/admin_action
import glot_core/api_action
import glot_core/pagination_model.{type CursorPage}
import glot_core/snippet/manual_review.{type ManualReview}

pub fn list(
  request_ctx: RequestContext,
  request: ListRequest,
) -> Program(CursorPage(ReviewSnippet)) {
  use _ <- program.and_then(
    pagination_model.validate(request.pagination, 1)
    |> result.map_error(error.validation)
    |> program.from_result,
  )
  use session <- program.and_then(current_session.require_session(request_ctx))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx:,
    action: api_action.admin(admin_action.GetAdminSpamReviewAction),
    actor: api_action_policy.actor_from_user(option.Some(session.user)),
  ))
  use snippets <- program.and_then(snippet_effect.list_spam_review(
    spam_review_dto.ListRequest(
      ..request,
      pagination: pagination_model.increment_limit(request.pagination),
    ),
  ))
  use _ <- program.and_then(user_action_effect.create_user_action(user_action))
  program.succeed(case request.focus {
    option.None ->
      pagination_model.paginate(snippets, request.pagination, fn(value) {
        pagination_model.from_string(value.snippet.slug)
      })
    option.Some(slug) ->
      pagination_model.AfterCursorPage(
        snippets,
        pagination_model.from_string(slug),
        option.Some(pagination_model.from_string(slug)),
      )
  })
}

pub fn save(
  request_ctx: RequestContext,
  request: SaveRequest,
) -> Program(ManualReview) {
  use session <- program.and_then(current_session.require_session(request_ctx))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx:,
    action: api_action.admin(admin_action.SaveAdminManualReviewAction),
    actor: api_action_policy.actor_from_user(option.Some(session.user)),
  ))
  use now <- program.and_then(basic_effect.system_time())
  save_with_audit(request, session.user.identity.id, now, user_action)
  |> transaction_effect.run()
  |> program.require(error.resource(resource_error.SnippetReviewStale))
}

fn save_with_audit(request, reviewer, now, user_action) {
  // An unmatched guarded UPDATE performs no write and records no review action.
  // Keep its result typed until after the transaction boundary so a conflict
  // is returned as 409 rather than being wrapped as a database failure.
  use review <- transaction_program.and_then(
    snippet_effect.save_manual_review_tx(request, reviewer, now),
  )
  case review {
    option.None -> transaction_program.succeed(option.None)
    option.Some(_) ->
      user_action_effect.create_user_action_tx(user_action)
      |> transaction_program.map(fn(_) { review })
  }
}

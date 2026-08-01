import gleam/dynamic.{type Dynamic}
import glot_backend/auth/domain/session/current as current_session
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/snippet/domain/listing as snippet_listing
import glot_backend/snippet/effect/effect as snippet_effect
import glot_backend/system/effect/basic/basic_effect
import glot_backend/system/effect/log
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/api_action
import glot_core/public_action
import glot_core/snippet/snippet_dto.{
  type ListSessionSnippetsRequest, type ListSnippetsResponse,
}
import glot_core/snippet/snippet_model

pub fn list_session_snippets(
  request_ctx: RequestContext,
  request: ListSessionSnippetsRequest,
) -> Program(ListSnippetsResponse) {
  use pagination <- program.and_then(snippet_listing.require_valid_pagination(
    request.pagination,
  ))
  use session <- program.and_then(current_session.require_session(request_ctx))

  use _ <- program.and_then(
    basic_effect.info(
      log.from_list([
        log.uuid("session_id", session.identity.id),
        log.uuid("user_id", session.user.identity.id),
      ]),
    ),
  )

  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.public(public_action.ListSessionSnippetsAction),
    actor: api_action_policy.KnownUser(
      user_id: session.user.identity.id,
      account_state: session.user.account.identity.account_state,
      account_tier: session.user.account.identity.account_tier,
      role: session.user.identity.role,
    ),
  ))

  use snippets <- program.and_then(snippet_effect.list(
    filter: snippet_model.new_filter()
      |> snippet_model.only_user_ids([session.user.identity.id]),
    pagination: snippet_listing.fetch_pagination(pagination),
  ))

  let page = snippet_listing.paginate(snippets, pagination)

  use _ <- program.and_then(user_action_effect.create_user_action(user_action))

  program.succeed(snippet_dto.from_snippets(page))
}

pub fn request_from_dynamic(
  data: Dynamic,
) -> Program(ListSessionSnippetsRequest) {
  program.decode_dynamic(data, snippet_dto.list_session_decoder())
}

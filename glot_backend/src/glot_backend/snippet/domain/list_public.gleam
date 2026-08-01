import gleam/dynamic.{type Dynamic}
import gleam/option
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
  type ListPublicSnippetsRequest, type ListSnippetsResponse,
}
import glot_core/snippet/snippet_model

pub fn list_public_snippets(
  request_ctx: RequestContext,
  request: ListPublicSnippetsRequest,
) -> Program(ListSnippetsResponse) {
  use pagination <- program.and_then(snippet_listing.require_valid_pagination(
    request.pagination,
  ))
  use maybe_session <- program.and_then(current_session.get_session(request_ctx))
  let maybe_session_id =
    option.map(maybe_session, fn(session) { session.identity.id })
  let maybe_user_id =
    option.map(maybe_session, fn(session) { session.user.identity.id })

  use _ <- program.and_then(
    basic_effect.info(
      log.from_list([
        log.optional_uuid("session_id", maybe_session_id),
        log.optional_uuid("user_id", maybe_user_id),
      ]),
    ),
  )

  let actor =
    maybe_session
    |> option.map(fn(session) { session.user })
    |> api_action_policy.actor_from_user

  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.public(public_action.ListPublicSnippetsAction),
    actor: actor,
  ))

  use snippets <- program.and_then(snippet_effect.list(
    filter: snippet_model.new_filter()
      |> snippet_model.only_visibilities([snippet_model.Public])
      |> snippet_model.only_usernames(request.usernames),
    pagination: snippet_listing.fetch_pagination(pagination),
  ))

  let page = snippet_listing.paginate(snippets, pagination)

  use _ <- program.and_then(user_action_effect.create_user_action(user_action))

  program.succeed(snippet_dto.from_snippets(page))
}

pub fn request_from_dynamic(
  data: Dynamic,
) -> Program(ListPublicSnippetsRequest) {
  program.decode_dynamic(data, snippet_dto.list_public_decoder())
}

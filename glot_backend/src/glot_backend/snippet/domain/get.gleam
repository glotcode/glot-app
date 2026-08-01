import gleam/dynamic.{type Dynamic}
import gleam/option
import glot_backend/auth/domain/session/current as current_session
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/snippet/domain/access
import glot_backend/snippet/domain/lookup as snippet_lookup
import glot_backend/system/effect/basic/basic_effect
import glot_backend/system/effect/log
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/api_action
import glot_core/public_action
import glot_core/snippet/snippet_dto.{
  type GetSnippetRequest, type SnippetResponse,
}
import glot_core/snippet/snippet_model

pub fn get_snippet(
  request_ctx: RequestContext,
  request: GetSnippetRequest,
) -> Program(SnippetResponse) {
  use maybe_session <- program.and_then(current_session.get_session(request_ctx))
  let maybe_session_id = option.map(maybe_session, fn(s) { s.identity.id })
  let maybe_user_id = option.map(maybe_session, fn(s) { s.user.identity.id })

  use _ <- program.and_then(
    basic_effect.info(
      log.from_list([
        log.string("slug", request.slug),
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
    action: api_action.public(public_action.GetSnippetAction),
    actor: actor,
  ))

  use snippet <- program.and_then(snippet_lookup.require_by_slug(request.slug))

  let viewer =
    maybe_session
    |> option.map(fn(session) { session.user.identity })

  use _ <- program.and_then(access.require_view(snippet, viewer))

  let is_owner = maybe_user_id == option.Some(snippet.user.id)

  use _ <- program.and_then(
    basic_effect.info(
      log.from_list([
        log.string(
          "visibility",
          snippet_model.visibility_to_string(snippet.identity.visibility),
        ),
        log.bool("is_owner", is_owner),
      ]),
    ),
  )

  use _ <- program.and_then(user_action_effect.create_user_action(user_action))

  program.succeed(snippet_dto.from_snippet(snippet))
}

pub fn request_from_dynamic(data: Dynamic) -> Program(GetSnippetRequest) {
  program.decode_dynamic(data, snippet_dto.get_decoder())
}

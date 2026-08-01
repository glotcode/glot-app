import gleam/dynamic.{type Dynamic}
import glot_backend/auth/domain/session/current as current_session
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/snippet/domain/access as snippet_access
import glot_backend/snippet/domain/lookup as snippet_lookup
import glot_backend/snippet/effect/effect as snippet_effect
import glot_backend/system/effect/basic/basic_effect
import glot_backend/system/effect/log
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{
  type Program, type TransactionProgram,
}
import glot_backend/system/effect/transaction/transaction_effect
import glot_backend/system/effect/transaction/transaction_program
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/api_action
import glot_core/public_action
import glot_core/snippet/snippet_dto.{type DeleteSnippetRequest}
import glot_core/user_action.{type UserAction}
import youid/uuid.{type Uuid}

pub fn delete_snippet(
  request_ctx: RequestContext,
  request: DeleteSnippetRequest,
) -> Program(Nil) {
  use session <- program.and_then(current_session.require_session(request_ctx))

  use _ <- program.and_then(
    basic_effect.info(
      log.from_list([
        log.uuid("session_id", session.identity.id),
        log.uuid("user_id", session.user.identity.id),
        log.string("slug", request.slug),
      ]),
    ),
  )

  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.public(public_action.DeleteSnippetAction),
    actor: api_action_policy.KnownUser(
      user_id: session.user.identity.id,
      account_state: session.user.account.identity.account_state,
      account_tier: session.user.account.identity.account_tier,
      role: session.user.identity.role,
    ),
  ))

  use _ <- program.and_then(
    delete_snippet_tx(request.slug, session.user.identity.id, user_action)
    |> transaction_effect.run(),
  )

  program.succeed(Nil)
}

fn delete_snippet_tx(
  slug: String,
  actor_user_id: Uuid,
  user_action: UserAction,
) -> TransactionProgram(Nil) {
  use existing <- transaction_program.and_then(
    snippet_lookup.require_by_slug_for_update(slug),
  )
  use _ <- transaction_program.and_then(snippet_access.require_owner_tx(
    existing,
    actor_user_id,
  ))

  transaction_program.sequence([
    snippet_effect.delete_tx(existing.identity.id),
    user_action_effect.create_user_action_tx(user_action),
  ])
}

pub fn request_from_dynamic(data: Dynamic) -> Program(DeleteSnippetRequest) {
  program.decode_dynamic(data, snippet_dto.delete_decoder())
}

import gleam/dynamic.{type Dynamic}
import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_backend/auth/domain/session/current as current_session
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/snippet/domain/access as snippet_access
import glot_backend/snippet/domain/lookup as snippet_lookup
import glot_backend/snippet/domain/validation as snippet_validation
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
import glot_core/snippet/snippet_dto.{
  type SnippetData, type SnippetResponse, type UpdateSnippetRequest,
}
import glot_core/snippet/snippet_model.{type HydratedSnippet, type Snippet}
import glot_core/user_action.{type UserAction}
import youid/uuid.{type Uuid}

pub fn update_snippet(
  request_ctx: RequestContext,
  request: UpdateSnippetRequest,
) -> Program(SnippetResponse) {
  let ctx = request_ctx.context

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
    action: api_action.public(public_action.UpdateSnippetAction),
    actor: api_action_policy.KnownUser(
      user_id: session.user.identity.id,
      account_state: session.user.account.identity.account_state,
      account_tier: session.user.account.identity.account_tier,
      role: session.user.identity.role,
    ),
  ))

  use existing <- program.and_then(snippet_lookup.require_by_slug(request.slug))
  use _ <- program.and_then(snippet_validation.require_writable_snippet(
    existing,
  ))

  use _ <- program.and_then(snippet_validation.require_valid_fields(
    request.data,
  ))
  use _ <- program.and_then(snippet_validation.require_clean(request.data))

  use updated_snippet <- program.and_then(
    update_snippet_tx(
      slug: request.slug,
      actor_user_id: session.user.identity.id,
      data: request.data,
      now: ctx.timestamp,
      user_action: user_action,
    )
    |> transaction_effect.run(),
  )

  program.succeed(snippet_dto.from_snippet(updated_snippet))
}

fn prepare_updated_snippet(
  existing: HydratedSnippet,
  data: SnippetData,
  now: Timestamp,
) -> Snippet {
  snippet_model.Snippet(
    id: existing.identity.id,
    slug: existing.identity.slug,
    user_id: existing.user.id,
    title: data.title,
    language: data.language,
    visibility: data.visibility,
    stdin: data.stdin,
    run_instructions: data.run_instructions,
    files: data.files,
    created_at: existing.identity.created_at,
    updated_at: now,
  )
}

fn update_snippet_tx(
  slug slug: String,
  actor_user_id actor_user_id: Uuid,
  data data: SnippetData,
  now now: Timestamp,
  user_action user_action: UserAction,
) -> TransactionProgram(HydratedSnippet) {
  use existing <- transaction_program.and_then(
    snippet_lookup.require_by_slug_for_update(slug),
  )
  use _ <- transaction_program.and_then(
    snippet_validation.require_writable_snippet_tx(existing),
  )
  use _ <- transaction_program.and_then(snippet_access.require_owner_tx(
    existing,
    actor_user_id,
  ))
  let updated = prepare_updated_snippet(existing, data, now)
  use _ <- transaction_program.and_then(
    transaction_program.sequence([
      snippet_effect.update_tx(updated),
      user_action_effect.create_user_action_tx(user_action),
    ]),
  )

  transaction_program.succeed(snippet_model.HydratedSnippet(
    identity: updated,
    user: existing.user,
    is_runnable: option.None,
  ))
}

pub fn request_from_dynamic(data: Dynamic) -> Program(UpdateSnippetRequest) {
  program.decode_dynamic(data, snippet_dto.update_decoder())
}

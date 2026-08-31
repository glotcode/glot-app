import gleam/dynamic.{type Dynamic}
import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_backend/auth/domain/session/current as current_session
import glot_backend/request_policy/api_action as api_action_policy
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
  type CreateSnippetRequest, type SnippetData, type SnippetResponse,
}
import glot_core/snippet/snippet_model.{type Snippet}
import glot_core/user_action.{type UserAction}
import youid/uuid.{type Uuid}

pub fn create_snippet(
  request_ctx: RequestContext,
  request: CreateSnippetRequest,
) -> Program(SnippetResponse) {
  let ctx = request_ctx.context

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
    action: api_action.public(public_action.CreateSnippetAction),
    actor: api_action_policy.KnownUser(
      user_id: session.user.identity.id,
      account_state: session.user.account.identity.account_state,
      account_tier: session.user.account.identity.account_tier,
      role: session.user.identity.role,
    ),
  ))

  use _ <- program.and_then(snippet_validation.require_valid_fields(
    request.data,
  ))
  use _ <- program.and_then(snippet_validation.require_clean(request.data))

  use snippet_id <- program.and_then(basic_effect.uuid_v7())
  let new_snippet =
    prepare_new_snippet(
      snippet_id,
      session.user.identity.id,
      request.data,
      ctx.timestamp,
    )
  use _ <- program.and_then(
    create_snippet_tx(new_snippet, user_action)
    |> transaction_effect.run(),
  )
  use _ <- program.and_then(
    basic_effect.info(log.singleton(log.uuid("snippet_id", snippet_id))),
  )

  program.succeed(
    snippet_model.HydratedSnippet(
      identity: new_snippet,
      user: session.user.identity,
      is_runnable: option.None,
    )
    |> snippet_dto.from_snippet,
  )
}

fn prepare_new_snippet(
  id: Uuid,
  user_id: Uuid,
  data: SnippetData,
  now: Timestamp,
) -> Snippet {
  snippet_model.Snippet(
    id: id,
    slug: snippet_model.new_slug(now),
    user_id: user_id,
    title: data.title,
    language: data.language,
    visibility: data.visibility,
    stdin: data.stdin,
    run_instructions: data.run_instructions,
    files: data.files,
    created_at: now,
    updated_at: now,
  )
}

fn create_snippet_tx(
  snippet: Snippet,
  user_action: UserAction,
) -> TransactionProgram(Nil) {
  transaction_program.sequence([
    snippet_effect.create_tx(snippet),
    user_action_effect.create_user_action_tx(user_action),
  ])
}

pub fn request_from_dynamic(data: Dynamic) -> Program(CreateSnippetRequest) {
  program.decode_dynamic(data, snippet_dto.create_decoder())
}

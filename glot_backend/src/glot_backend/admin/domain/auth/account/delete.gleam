import gleam/dynamic.{type Dynamic}
import gleam/option
import glot_backend/auth/domain/session/current as current_session
import glot_backend/auth/effect/account as account_effect
import glot_backend/auth/effect/session as session_effect
import glot_backend/auth/effect/user as user_effect
import glot_backend/job/effect/job/effect as job_effect
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/snippet/effect/effect as snippet_effect
import glot_backend/system/effect/error
import glot_backend/system/effect/error/resource_error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/effect/transaction/transaction_effect
import glot_backend/system/effect/transaction/transaction_program
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/admin/account_dto.{type DeleteAccountRequest}
import glot_core/admin_action
import glot_core/api_action

pub fn delete_account(
  request_ctx: RequestContext,
  request: DeleteAccountRequest,
) -> Program(Nil) {
  use session <- program.and_then(current_session.require_session(request_ctx))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.admin(admin_action.DeleteAdminAccountAction),
    actor: api_action_policy.actor_from_user(option.Some(session.user)),
  ))
  use hydrated_user <- program.and_then(
    user_effect.get_user_by_id(request.user_id)
    |> program.require(error.resource(resource_error.UserNotFound)),
  )
  let delete_pending_job =
    hydrated_user.account.identity.delete_job_id
    |> option.map(job_effect.delete_job_tx)
    |> option.unwrap(transaction_program.succeed(Nil))

  transaction_effect.run(
    transaction_program.sequence([
      delete_pending_job,
      user_action_effect.create_user_action_tx(user_action),
      session_effect.delete_sessions_by_account_id_tx(
        hydrated_user.account.identity.id,
      ),
      snippet_effect.delete_by_account_id_tx(hydrated_user.account.identity.id),
      user_effect.delete_users_by_account_id_tx(
        hydrated_user.account.identity.id,
      ),
      account_effect.delete_account_tx(hydrated_user.account.identity.id),
    ]),
  )
}

pub fn request_from_dynamic(data: Dynamic) -> Program(DeleteAccountRequest) {
  program.decode_dynamic(data, account_dto.delete_request_decoder())
}

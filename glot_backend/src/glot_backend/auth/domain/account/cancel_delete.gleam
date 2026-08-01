import gleam/option.{type Option}
import glot_backend/auth/domain/session/current as current_session
import glot_backend/auth/effect/account as account_effect
import glot_backend/job/effect/job/effect as job_effect
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/system/effect/basic/basic_effect
import glot_backend/system/effect/error
import glot_backend/system/effect/error/resource_error
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
import glot_core/auth/account_model.{type Account}
import glot_core/job/job_model.{type Job}
import glot_core/public_action
import glot_core/user_action.{type UserAction}
import youid/uuid.{type Uuid}

pub fn cancel_delete_account(request_ctx: RequestContext) -> Program(Nil) {
  let ctx = request_ctx.context

  use session <- program.and_then(current_session.require_session(request_ctx))

  use _ <- program.and_then(
    basic_effect.info(
      log.from_list([
        log.uuid("session_id", session.identity.id),
        log.uuid("user_id", session.user.identity.id),
        log.uuid("account_id", session.user.account.identity.id),
      ]),
    ),
  )

  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.public(public_action.CancelDeleteAccountAction),
    actor: api_action_policy.KnownUser(
      user_id: session.user.identity.id,
      account_state: session.user.account.identity.account_state,
      account_tier: session.user.account.identity.account_tier,
      role: session.user.identity.role,
    ),
  ))

  use delete_job_id <- program.and_then(program.from_option(
    session.user.account.identity.delete_job_id,
    error.resource(resource_error.AccountDeleteNotScheduled),
  ))
  use maybe_job <- program.and_then(job_effect.get_job_by_id(delete_job_id))

  let updated_account =
    account_model.set_delete_job_id(
      session.user.account.identity,
      option.None,
      ctx.timestamp,
    )

  prepare_cancel_delete_mutations(
    maybe_job,
    delete_job_id,
    updated_account,
    user_action,
  )
  |> transaction_program.sequence
  |> transaction_effect.run()
}

fn prepare_cancel_delete_mutations(
  maybe_job: Option(Job),
  delete_job_id: Uuid,
  updated_account: Account,
  user_action: UserAction,
) -> List(TransactionProgram(Nil)) {
  let common_mutations = [
    account_effect.update_account_tx(updated_account),
    user_action_effect.create_user_action_tx(user_action),
  ]

  let should_delete_job =
    maybe_job
    |> option.map(is_pending_delete_job)
    |> option.unwrap(False)

  case should_delete_job {
    True -> [job_effect.delete_job_tx(delete_job_id), ..common_mutations]
    False -> common_mutations
  }
}

fn is_pending_delete_job(job: Job) -> Bool {
  job.job_type == job_model.DeleteAccountJob && job.status == job_model.Pending
}

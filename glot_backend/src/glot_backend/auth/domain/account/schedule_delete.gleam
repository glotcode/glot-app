import gleam/json
import gleam/option
import gleam/result
import glot_backend/auth/domain/session/current as current_session
import glot_backend/auth/effect/account as account_effect
import glot_backend/job/domain/type_policy as job_type_policy_domain
import glot_backend/job/effect/job/effect as job_effect
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/system/effect/basic/basic_effect
import glot_backend/system/effect/error
import glot_backend/system/effect/error/resource_error
import glot_backend/system/effect/log
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/effect/transaction/transaction_effect
import glot_backend/system/effect/transaction/transaction_program
import glot_backend/system/request/context.{type Context}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/api_action
import glot_core/auth/account_model.{type HydratedAccount}
import glot_core/helpers/timestamp_helpers
import glot_core/job/job_model.{type Job}
import glot_core/public_action
import youid/uuid.{type Uuid}

const delete_delay_seconds = 86_400

pub fn schedule_delete_account(request_ctx: RequestContext) -> Program(Nil) {
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
    action: api_action.public(public_action.ScheduleDeleteAccountAction),
    actor: api_action_policy.KnownUser(
      user_id: session.user.identity.id,
      account_state: session.user.account.identity.account_state,
      account_tier: session.user.account.identity.account_tier,
      role: session.user.identity.role,
    ),
  ))

  use _ <- program.and_then(require_no_pending_delete(ctx, session.user.account))
  use job_id <- program.and_then(basic_effect.uuid_v7())
  use delete_account_policy <- program.and_then(
    job_type_policy_domain.require_job_type_policy(job_model.DeleteAccountJob),
  )

  let delete_job =
    job_model.delete_account_job(
      job_id,
      option.Some(ctx.request_id),
      ctx.timestamp,
      timestamp_helpers.add_seconds(ctx.timestamp, delete_delay_seconds),
      session.user.account.identity.id,
      session.user.identity.email,
      delete_account_policy,
    )
  let updated_account =
    account_model.set_delete_job_id(
      session.user.account.identity,
      option.Some(job_id),
      ctx.timestamp,
    )

  transaction_program.sequence([
    job_effect.create_job_tx(delete_job),
    account_effect.update_account_tx(updated_account),
    user_action_effect.create_user_action_tx(user_action),
  ])
  |> transaction_effect.run()
}

fn require_no_pending_delete(
  ctx: Context,
  account: HydratedAccount,
) -> Program(Nil) {
  case account.identity.delete_job_id {
    option.None -> program.succeed(Nil)
    option.Some(job_id) -> {
      use maybe_job <- program.and_then(job_effect.get_job_by_id(job_id))
      use _ <- program.and_then(require_not_pending_delete(
        maybe_job,
        account.identity.id,
      ))
      repair_delete_job_id(ctx, account)
    }
  }
}

fn require_not_pending_delete(
  maybe_job: option.Option(Job),
  account_id: Uuid,
) -> Program(Nil) {
  let has_pending_delete =
    maybe_job
    |> option.map(is_pending_delete_job_for_account(_, account_id))
    |> option.unwrap(False)

  case has_pending_delete {
    True ->
      program.fail(error.resource(resource_error.AccountDeleteAlreadyScheduled))
    False -> program.succeed(Nil)
  }
}

fn repair_delete_job_id(
  ctx: Context,
  account: HydratedAccount,
) -> Program(Nil) {
  account.identity
  |> account_model.set_delete_job_id(option.None, ctx.timestamp)
  |> account_effect.update_account
}

fn is_pending_delete_job_for_account(job: Job, account_id: Uuid) -> Bool {
  let is_pending_delete_job =
    job.job_type == job_model.DeleteAccountJob
    && job.status == job_model.Pending
    && job.completed_at == option.None

  case is_pending_delete_job {
    True -> delete_job_belongs_to_account(job, account_id)
    False -> False
  }
}

fn delete_job_belongs_to_account(job: Job, account_id: Uuid) -> Bool {
  case job.payload {
    option.Some(payload_json) ->
      json.parse(payload_json, job_model.delete_account_job_payload_decoder())
      |> result.map(fn(payload) { payload.account_id == account_id })
      |> result.unwrap(False)
    option.None -> False
  }
}

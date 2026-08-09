import gleam/dict
import gleam/dynamic.{type Dynamic}
import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/auth/domain/session/current as current_session
import glot_backend/auth/domain/verification_token/policy as verification_token_policy
import glot_backend/auth/effect/email_change as email_change_effect
import glot_backend/auth/effect/user as user_effect
import glot_backend/auth/error as auth_error
import glot_backend/email/domain/preparation as email_preparation
import glot_backend/email/model/template as email_template
import glot_backend/job/domain/type_policy as job_type_policy_domain
import glot_backend/job/effect/job/effect as job_effect
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/system/crypto/token
import glot_backend/system/effect/basic/basic_effect
import glot_backend/system/effect/error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{
  type Program, type TransactionProgram,
}
import glot_backend/system/effect/transaction/transaction_effect
import glot_backend/system/effect/transaction/transaction_program
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/api_action
import glot_core/auth/email_change_dto.{type BeginEmailChangeRequest}
import glot_core/auth/email_change_token_model.{type EmailChangeToken}
import glot_core/auth/user_model.{type HydratedUser}
import glot_core/email/email_address_model.{type EmailAddress}
import glot_core/job/job_model
import glot_core/public_action

pub fn begin_email_change(
  request_ctx: RequestContext,
  request: BeginEmailChangeRequest,
) -> Program(Nil) {
  let ctx = request_ctx.context
  let auth_config = dynamic_config.auth_config(request_ctx.dynamic_config)
  use session <- program.and_then(current_session.require_session(request_ctx))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx:,
    action: api_action.public(public_action.BeginEmailChangeAction),
    actor: api_action_policy.actor_from_user(option.Some(session.user)),
  ))
  use _ <- program.and_then(require_change_allowed(session.user, request.email))
  use existing_user <- program.and_then(user_effect.get_user_by_email(
    request.email,
  ))
  use token_id <- program.and_then(basic_effect.uuid_v7())
  use job_id <- program.and_then(basic_effect.uuid_v7())
  use code <- program.and_then(basic_effect.new_token(
    verification_token_policy.token_length,
    token.Numeric,
  ))
  use sender <- program.and_then(email_preparation.require_sender(
    dynamic_config.email_config(request_ctx.dynamic_config),
    ctx.regexes.is_email,
  ))
  use verification_email <- program.and_then(email_preparation.render_template(
    email_template.EmailChangeVerificationTemplate,
    sender,
    request.email,
    dict.from_list([#("token", code)]),
  ))
  use address_in_use_email <- program.and_then(
    email_preparation.render_template(
      email_template.EmailChangeAddressInUseTemplate,
      sender,
      request.email,
      dict.new(),
    ),
  )
  use send_email_policy <- program.and_then(
    job_type_policy_domain.require_job_type_policy(job_model.SendEmailJob),
  )
  let email_change_token =
    email_change_token_model.EmailChangeToken(
      id: token_id,
      user_id: session.user.identity.id,
      old_email: session.user.identity.email,
      new_email: request.email,
      token: code,
      attempt_count: 0,
      created_at: ctx.timestamp,
      used_at: option.None,
    )
  let verification_email_job =
    job_model.send_email_job(
      job_id,
      option.Some(ctx.request_id),
      ctx.timestamp,
      verification_email,
      send_email_policy,
    )
  let address_in_use_email_job =
    job_model.send_email_job(
      job_id,
      option.Some(ctx.request_id),
      ctx.timestamp,
      address_in_use_email,
      send_email_policy,
    )
  let transaction = case existing_user {
    option.None ->
      transaction_program.sequence([
        create_email_change_token_tx(
          email_change_token,
          verification_token_policy.created_since(
            ctx.timestamp,
            auth_config.login_token_max_age,
          ),
        ),
        job_effect.create_job_tx(verification_email_job),
        user_action_effect.create_user_action_tx(user_action),
      ])
    option.Some(_) ->
      transaction_program.sequence([
        job_effect.create_job_tx(address_in_use_email_job),
        user_action_effect.create_user_action_tx(user_action),
      ])
  }
  use _ <- program.and_then(transaction_effect.run(transaction))
  program.succeed(Nil)
}

fn create_email_change_token_tx(
  email_change_token: EmailChangeToken,
  created_since: Timestamp,
) -> TransactionProgram(Nil) {
  use valid_tokens <- transaction_program.and_then(
    email_change_effect.list_by_user_id_tx(
      email_change_token.user_id,
      created_since,
      verification_token_policy.valid_token_count,
    ),
  )
  let attempt_count =
    verification_token_policy.shared_attempt_count(valid_tokens, fn(token) {
      token.attempt_count
    })
  email_change_effect.create_tx(
    email_change_token_model.EmailChangeToken(
      ..email_change_token,
      attempt_count:,
    ),
  )
}

fn require_change_allowed(
  user: HydratedUser,
  new_email: EmailAddress,
) -> Program(Nil) {
  case user.account.identity.delete_job_id, user.identity.email == new_email {
    option.Some(_), _ ->
      program.fail(error.auth(auth_error.EmailChangeBlockedByPendingDeletion))
    _, True -> program.fail(error.auth(auth_error.EmailUnchanged))
    _, False -> program.succeed(Nil)
  }
}

pub fn request_from_dynamic(
  request_ctx: RequestContext,
  data: Dynamic,
) -> Program(BeginEmailChangeRequest) {
  program.decode_dynamic(
    data,
    email_change_dto.begin_request_decoder(request_ctx.context.regexes.is_email),
  )
}

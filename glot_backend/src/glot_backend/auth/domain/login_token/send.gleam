import gleam/dict
import gleam/dynamic.{type Dynamic}
import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/auth/domain/verification_token/policy as verification_token_policy
import glot_backend/auth/effect/login_token as login_token_effect
import glot_backend/auth/effect/user as user_effect
import glot_backend/email/domain/preparation as email_preparation
import glot_backend/email/model/template as email_template
import glot_backend/job/domain/type_policy as job_type_policy_domain
import glot_backend/job/effect/job/effect as job_effect
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/system/crypto/token
import glot_backend/system/effect/basic/basic_effect
import glot_backend/system/effect/log
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{
  type Program, type TransactionProgram,
}
import glot_backend/system/effect/transaction/transaction_effect
import glot_backend/system/effect/transaction/transaction_program
import glot_backend/system/request/context.{type Context}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/api_action
import glot_core/auth/login_token_dto.{type LoginTokenRequest}
import glot_core/auth/login_token_model.{type LoginToken}
import glot_core/job/job_model
import glot_core/public_action

pub fn send_login_token(
  request_ctx: RequestContext,
  request: LoginTokenRequest,
) -> Program(Nil) {
  let ctx = request_ctx.context
  let config = request_ctx.dynamic_config

  use _ <- program.and_then(
    basic_effect.info(log.singleton(log.email("email", request.email))),
  )

  use maybe_user <- program.and_then(user_effect.get_user_by_email(
    request.email,
  ))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.public(public_action.SendLoginTokenAction),
    actor: api_action_policy.actor_from_user(maybe_user),
  ))
  let auth_config = dynamic_config.auth_config(config)

  use token <- program.and_then(basic_effect.new_token(
    verification_token_policy.token_length,
    token.Numeric,
  ))
  use login_token_id <- program.and_then(basic_effect.uuid_v7())
  use job_id <- program.and_then(basic_effect.uuid_v7())

  use _ <- program.and_then(
    basic_effect.info(
      log.from_list([
        log.uuid("login_token_id", login_token_id),
        log.uuid("job_id", job_id),
      ]),
    ),
  )

  use sender <- program.and_then(email_preparation.require_sender(
    dynamic_config.email_config(config),
    ctx.regexes.is_email,
  ))
  use login_email <- program.and_then(email_preparation.render_template(
    email_template.LoginTokenTemplate,
    sender,
    request.email,
    dict.from_list([#("token", token)]),
  ))
  use send_email_policy <- program.and_then(
    job_type_policy_domain.require_job_type_policy(job_model.SendEmailJob),
  )

  let send_email_job =
    job_model.send_email_job(
      job_id,
      option.Some(ctx.request_id),
      ctx.timestamp,
      login_email,
      send_email_policy,
    )

  let login_token =
    login_token_model.LoginToken(
      id: login_token_id,
      email: request.email,
      token: token,
      attempt_count: 0,
      created_at: ctx.timestamp,
      used_at: option.None,
    )

  transaction_program.sequence([
    create_login_token_tx(
      login_token,
      verification_token_policy.created_since(
        ctx.timestamp,
        auth_config.login_token_max_age,
      ),
    ),
    job_effect.create_job_tx(send_email_job),
    user_action_effect.create_user_action_tx(user_action),
  ])
  |> transaction_effect.run()
}

fn create_login_token_tx(
  login_token: LoginToken,
  created_since: Timestamp,
) -> TransactionProgram(Nil) {
  use valid_tokens <- transaction_program.and_then(
    login_token_effect.list_login_tokens_by_email_tx(
      login_token.email,
      created_since,
      verification_token_policy.valid_token_count,
    ),
  )
  let attempt_count =
    verification_token_policy.shared_attempt_count(valid_tokens, fn(token) {
      token.attempt_count
    })

  login_token_effect.create_login_token_tx(
    login_token_model.LoginToken(..login_token, attempt_count: attempt_count),
  )
}

pub fn request_from_dynamic(
  ctx: Context,
  data: Dynamic,
) -> Program(LoginTokenRequest) {
  program.decode_dynamic(data, login_token_dto.decoder(ctx.regexes.is_email))
}

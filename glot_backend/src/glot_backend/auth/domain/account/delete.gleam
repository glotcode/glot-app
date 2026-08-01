import gleam/dict
import gleam/option
import glot_backend/app_config/effect/effect as app_config_effect
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/auth/effect/account as account_effect
import glot_backend/auth/effect/session as session_effect
import glot_backend/auth/effect/user as user_effect
import glot_backend/email/domain/preparation as email_preparation
import glot_backend/email/model/template as email_template
import glot_backend/job/domain/type_policy as job_type_policy_domain
import glot_backend/job/effect/job/effect as job_effect
import glot_backend/snippet/effect/effect as snippet_effect
import glot_backend/system/effect/basic/basic_effect
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/effect/transaction/transaction_effect
import glot_backend/system/effect/transaction/transaction_program
import glot_backend/system/request/context.{type Context}
import glot_core/job/job_model.{type DeleteAccountJobPayload}

pub fn delete_account(
  ctx: Context,
  payload: DeleteAccountJobPayload,
) -> Program(Nil) {
  use email_job_id <- program.and_then(basic_effect.uuid_v7())
  use config <- program.and_then(app_config_effect.get_dynamic_config())
  use sender <- program.and_then(email_preparation.require_sender(
    dynamic_config.email_config(config),
    ctx.regexes.is_email,
  ))
  use account_deleted_email <- program.and_then(
    email_preparation.render_template(
      email_template.AccountDeletedTemplate,
      sender,
      payload.email,
      dict.new(),
    ),
  )
  use send_email_policy <- program.and_then(
    job_type_policy_domain.require_job_type_policy(job_model.SendEmailJob),
  )

  let send_email_job =
    job_model.send_email_job(
      email_job_id,
      option.Some(ctx.request_id),
      ctx.timestamp,
      account_deleted_email,
      send_email_policy,
    )

  transaction_program.sequence([
    session_effect.delete_sessions_by_account_id_tx(payload.account_id),
    snippet_effect.delete_by_account_id_tx(payload.account_id),
    user_effect.delete_users_by_account_id_tx(payload.account_id),
    account_effect.delete_account_tx(payload.account_id),
    job_effect.create_job_tx(send_email_job),
  ])
  |> transaction_effect.run()
}

pub fn payload_from_json(json_str: String) -> Program(DeleteAccountJobPayload) {
  use payload <- program.and_then(program.parse_json(
    json_str,
    job_model.delete_account_job_payload_decoder(),
  ))
  program.succeed(payload)
}

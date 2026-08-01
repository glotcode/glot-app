import gleam/dynamic.{type Dynamic}
import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}
import glot_backend/auth/domain/session/current as current_session
import glot_backend/contact/domain/message as contact_message
import glot_backend/contact/domain/validation as contact_validation
import glot_backend/job/domain/type_policy as job_type_policy_domain
import glot_backend/job/effect/job/effect as job_effect
import glot_backend/request_policy/api_action as api_action_policy
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
import glot_core/auth/session_model.{type HydratedSession}
import glot_core/contact_dto.{type ContactRequest}
import glot_core/email/email_model.{type Email}
import glot_core/job/job_model.{type Job, type JobTypePolicy}
import glot_core/public_action
import glot_core/user_action.{type UserAction}
import youid/uuid.{type Uuid}

pub fn submit_contact(
  request_ctx: RequestContext,
  request: ContactRequest,
) -> Program(Nil) {
  use maybe_session <- program.and_then(current_session.get_session(request_ctx))
  let actor =
    maybe_session
    |> option.map(fn(session) { session.user })
    |> api_action_policy.actor_from_user
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx:,
    action: api_action.public(public_action.SubmitContactAction),
    actor:,
  ))

  case contact_validation.is_honeypot_submission(request) {
    True -> user_action_effect.create_user_action(user_action)
    False ->
      submit_valid_contact(request_ctx, request, maybe_session, user_action)
  }
}

fn submit_valid_contact(
  request_ctx: RequestContext,
  request: ContactRequest,
  maybe_session: Option(HydratedSession),
  user_action: UserAction,
) -> Program(Nil) {
  let ctx = request_ctx.context
  use contact <- program.and_then(contact_validation.require_valid_contact(
    request,
    ctx.regexes.is_email,
  ))
  use email <- program.and_then(contact_message.prepare_contact_email(
    request_ctx,
    contact,
    maybe_session,
  ))
  use job_id <- program.and_then(basic_effect.uuid_v7())
  use send_email_policy <- program.and_then(
    job_type_policy_domain.require_job_type_policy(job_model.SendEmailJob),
  )
  let send_email_job =
    prepare_send_email_job(
      job_id,
      ctx.request_id,
      ctx.timestamp,
      email,
      send_email_policy,
    )

  use _ <- program.and_then(
    basic_effect.info(
      log.from_list([
        log.uuid("job_id", job_id),
        log.string("contact_topic", contact_dto.topic_to_string(contact.topic)),
      ]),
    ),
  )

  persist_contact_tx(send_email_job, user_action)
  |> transaction_effect.run()
}

fn prepare_send_email_job(
  id: Uuid,
  request_id: Uuid,
  created_at: Timestamp,
  email: Email,
  policy: JobTypePolicy,
) -> Job {
  job_model.send_email_job(
    id,
    option.Some(request_id),
    created_at,
    email,
    policy,
  )
}

fn persist_contact_tx(
  send_email_job: Job,
  user_action: UserAction,
) -> TransactionProgram(Nil) {
  transaction_program.sequence([
    job_effect.create_job_tx(send_email_job),
    user_action_effect.create_user_action_tx(user_action),
  ])
}

pub fn request_from_dynamic(data: Dynamic) -> Program(ContactRequest) {
  program.decode_dynamic(data, contact_dto.decoder())
}

import gleam/dict
import gleam/dynamic.{type Dynamic}
import gleam/list
import gleam/option.{type Option}
import gleam/order
import gleam/string
import gleam/time/timestamp.{type Timestamp}
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/auth/domain/session/current as current_session
import glot_backend/auth/domain/verification_token/policy as verification_token_policy
import glot_backend/auth/effect/email_change as email_change_effect
import glot_backend/auth/effect/login_token as login_token_effect
import glot_backend/auth/effect/user as user_effect
import glot_backend/auth/error as auth_error
import glot_backend/email/domain/preparation as email_preparation
import glot_backend/email/model/template as email_template
import glot_backend/job/domain/type_policy as job_type_policy_domain
import glot_backend/job/effect/job/effect as job_effect
import glot_backend/request_policy/api_action as api_action_policy
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
import glot_core/auth/account_dto.{type AccountResponse}
import glot_core/auth/email_change_dto.{type ConfirmEmailChangeRequest}
import glot_core/auth/email_change_token_model.{type EmailChangeToken}
import glot_core/auth/user_model.{type User}
import glot_core/email/email_address_model.{type EmailAddress}
import glot_core/job/job_model.{type Job}
import glot_core/public_action
import glot_core/user_action.{type UserAction}
import youid/uuid.{type Uuid}

type ConfirmationOutcome {
  Confirmed(User)
  InvalidToken
  EmailTaken
  ChangeNoLongerApplicable
}

type TokenPreparation {
  TokenPreparation(
    matching_token: Option(EmailChangeToken),
    attempt_transaction: TransactionProgram(Nil),
  )
}

pub fn confirm_email_change(
  request_ctx: RequestContext,
  request: ConfirmEmailChangeRequest,
) -> Program(AccountResponse) {
  let ctx = request_ctx.context
  let auth_config = dynamic_config.auth_config(request_ctx.dynamic_config)
  let created_since =
    verification_token_policy.created_since(
      ctx.timestamp,
      auth_config.login_token_max_age,
    )
  use session <- program.and_then(current_session.require_session(request_ctx))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx:,
    action: api_action.public(public_action.ConfirmEmailChangeAction),
    actor: api_action_policy.actor_from_user(option.Some(session.user)),
  ))
  use tokens <- program.and_then(email_change_effect.list_by_user_id(
    session.user.identity.id,
    created_since,
    verification_token_policy.valid_token_count,
  ))
  let matching_token = find_matching_token(tokens, request.token)
  use notification_job <- program.and_then(case matching_token {
    option.Some(token) ->
      prepare_notification_job(request_ctx, token) |> program.map(option.Some)
    option.None -> program.succeed(option.None)
  })
  use outcome <- program.and_then(
    confirm_tx(
      request.token,
      session.user.identity.id,
      created_since,
      ctx.timestamp,
      notification_job,
      user_action,
    )
    |> transaction_effect.run(),
  )
  case outcome {
    Confirmed(user) ->
      program.succeed(
        account_dto.from_hydrated_user(user_model.HydratedUser(
          identity: user,
          account: session.user.account,
        )),
      )
    InvalidToken | ChangeNoLongerApplicable ->
      program.fail(error.auth(auth_error.InvalidEmailChangeToken))
    EmailTaken -> program.fail(error.auth(auth_error.EmailAlreadyInUse))
  }
}

fn confirm_tx(
  provided_token: String,
  user_id: Uuid,
  created_since: Timestamp,
  now: Timestamp,
  notification_job: Option(Job),
  user_action: UserAction,
) -> TransactionProgram(ConfirmationOutcome) {
  use tokens <- transaction_program.and_then(
    email_change_effect.list_by_user_id_tx(
      user_id,
      created_since,
      verification_token_policy.valid_token_count,
    ),
  )
  let preparation = prepare_token_mutations(tokens, provided_token, now)
  use _ <- transaction_program.and_then(preparation.attempt_transaction)
  case preparation.matching_token, notification_job {
    option.Some(token), option.Some(job) ->
      apply_change(token, now, job, user_action)
    _, _ -> transaction_program.succeed(InvalidToken)
  }
}

fn prepare_token_mutations(
  tokens: List(EmailChangeToken),
  provided_token: String,
  now: Timestamp,
) -> TokenPreparation {
  let shared_attempt_count =
    verification_token_policy.shared_attempt_count(tokens, fn(token) {
      token.attempt_count
    })
  case
    tokens,
    verification_token_policy.attempts_exhausted(shared_attempt_count)
  {
    [], _ | _, True ->
      TokenPreparation(option.None, transaction_program.succeed(Nil))
    _, False -> {
      let matching_token = find_matching_token(tokens, provided_token)
      let transaction =
        tokens
        |> list.map(fn(token) {
          token
          |> email_change_token_model.increment_attempt(shared_attempt_count)
          |> mark_matching_token_as_used(matching_token, now)
          |> email_change_effect.update_tx
        })
        |> transaction_program.sequence
      TokenPreparation(matching_token:, attempt_transaction: transaction)
    }
  }
}

fn find_matching_token(
  tokens: List(EmailChangeToken),
  provided_token: String,
) -> Option(EmailChangeToken) {
  verification_token_policy.find_matching(tokens, provided_token, fn(token) {
    token.token
  })
}

fn mark_matching_token_as_used(
  token: EmailChangeToken,
  matching_token: Option(EmailChangeToken),
  now: Timestamp,
) -> EmailChangeToken {
  case matching_token {
    option.Some(matching) if matching.id == token.id ->
      email_change_token_model.mark_as_used(token, now)
    _ -> token
  }
}

fn apply_change(
  token: EmailChangeToken,
  now: Timestamp,
  notification_job: Job,
  user_action: UserAction,
) -> TransactionProgram(ConfirmationOutcome) {
  use _ <- transaction_program.and_then(lock_emails(
    token.old_email,
    token.new_email,
  ))
  use maybe_user <- transaction_program.and_then(
    user_effect.get_user_by_id_for_update_tx(token.user_id),
  )
  case maybe_user {
    option.None -> transaction_program.succeed(ChangeNoLongerApplicable)
    option.Some(hydrated_user) ->
      case
        hydrated_user.identity.email == token.old_email,
        hydrated_user.account.identity.delete_job_id
      {
        False, _ | _, option.Some(_) ->
          transaction_program.succeed(ChangeNoLongerApplicable)
        True, option.None -> {
          use target <- transaction_program.and_then(
            user_effect.get_user_by_email_tx(token.new_email),
          )
          case target {
            option.Some(_) -> transaction_program.succeed(EmailTaken)
            option.None -> {
              let user =
                user_model.change_email(
                  hydrated_user.identity,
                  token.new_email,
                  now,
                )
              use _ <- transaction_program.and_then(
                transaction_program.sequence([
                  user_effect.update_user_email_tx(user.id, user.email, now),
                  login_token_effect.invalidate_by_emails_tx(
                    token.old_email,
                    token.new_email,
                    now,
                  ),
                  job_effect.create_job_tx(notification_job),
                  user_action_effect.create_user_action_tx(user_action),
                ]),
              )
              transaction_program.succeed(Confirmed(user))
            }
          }
        }
      }
  }
}

fn lock_emails(
  old_email: EmailAddress,
  new_email: EmailAddress,
) -> TransactionProgram(Nil) {
  let old = email_address_model.to_string(old_email)
  let new = email_address_model.to_string(new_email)
  case string.compare(old, new) {
    order.Lt | order.Eq ->
      transaction_program.sequence([
        user_effect.lock_email_tx(old_email),
        user_effect.lock_email_tx(new_email),
      ])
    order.Gt ->
      transaction_program.sequence([
        user_effect.lock_email_tx(new_email),
        user_effect.lock_email_tx(old_email),
      ])
  }
}

fn prepare_notification_job(
  request_ctx: RequestContext,
  token: EmailChangeToken,
) -> Program(Job) {
  let ctx = request_ctx.context
  use job_id <- program.and_then(basic_effect.uuid_v7())
  use sender <- program.and_then(email_preparation.require_sender(
    dynamic_config.email_config(request_ctx.dynamic_config),
    ctx.regexes.is_email,
  ))
  use notification <- program.and_then(email_preparation.render_template(
    email_template.EmailChangedTemplate,
    sender,
    token.old_email,
    dict.from_list([
      #("new_email", email_address_model.to_string(token.new_email)),
    ]),
  ))
  use policy <- program.and_then(job_type_policy_domain.require_job_type_policy(
    job_model.SendEmailJob,
  ))
  program.succeed(job_model.send_email_job(
    job_id,
    option.Some(ctx.request_id),
    ctx.timestamp,
    notification,
    policy,
  ))
}

pub fn request_from_dynamic(
  data: Dynamic,
) -> Program(ConfirmEmailChangeRequest) {
  program.decode_dynamic(data, email_change_dto.confirm_request_decoder())
}

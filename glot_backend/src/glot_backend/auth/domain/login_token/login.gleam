import gleam/dynamic.{type Dynamic}
import gleam/int
import gleam/list
import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/auth/domain/session/issue.{
  type SessionIssue, type SessionIssueResult,
} as session_issue_domain
import glot_backend/auth/effect/account as account_effect
import glot_backend/auth/effect/login_token as login_token_effect
import glot_backend/auth/effect/session as session_effect
import glot_backend/auth/effect/user as user_effect
import glot_backend/auth/error as auth_error
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/system/effect/basic/basic_effect
import glot_backend/system/effect/error
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
import glot_core/auth/account_model.{type Account}
import glot_core/auth/login_dto.{type LoginRequest}
import glot_core/auth/login_token_model.{type LoginToken}
import glot_core/auth/user_model.{type HydratedUser, type User}
import glot_core/email/email_address_model.{type EmailAddress}
import glot_core/helpers/timestamp_helpers
import glot_core/public_action
import glot_core/user_action.{type UserAction}
import youid/uuid.{type Uuid}

pub type LoginResult =
  SessionIssueResult

const max_login_token_attempts = 10

const valid_login_token_count = 2

type LoginTokenVerification {
  ValidToken
  InvalidToken
}

pub fn login(
  request_ctx: RequestContext,
  request: LoginRequest,
) -> Program(LoginResult) {
  let ctx = request_ctx.context
  let config = request_ctx.dynamic_config

  use _ <- program.and_then(
    basic_effect.info(
      log.from_list([
        log.email("email", request.email),
        log.string("token", request.token),
      ]),
    ),
  )
  let auth_config = dynamic_config.auth_config(config)

  use maybe_user <- program.and_then(user_effect.get_user_by_email(
    request.email,
  ))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.public(public_action.LoginAction),
    actor: api_action_policy.actor_from_user(maybe_user),
  ))

  use user_outcome <- program.and_then(update_or_create_user(
    maybe_user,
    request.email,
    ctx.timestamp,
  ))

  let user_outcome = mark_user_last_login(user_outcome, ctx.timestamp)
  let user = user_from_outcome(user_outcome)
  use _ <- program.and_then(
    basic_effect.info(log.singleton(log.uuid("user_id", user.id))),
  )
  use session_issue <- program.and_then(
    session_issue_domain.issue_session_for_user(ctx, user.id),
  )
  let prepared_login =
    PreparedLogin(
      email: request.email,
      token: request.token,
      attempted_at: ctx.timestamp,
      valid_token_created_since: timestamp_helpers.subtract_seconds(
        ctx.timestamp,
        auth_config.login_token_max_age,
      ),
      user_outcome: user_outcome,
      session_issue: session_issue,
      user_action: user_action,
    )
  use verification <- program.and_then(
    transaction_effect.run(login_tx(prepared_login)),
  )
  use _ <- program.and_then(require_valid_token(verification))
  use _ <- program.and_then(
    basic_effect.info(
      log.from_list([
        log.uuid("session_id", session_issue.session.id),
        log.bool("is_first_login", is_new_user(user_outcome)),
      ]),
    ),
  )

  program.succeed(session_issue_domain.SessionIssueResult(
    session_token: session_issue.session_token,
    session_cookie_max_age: auth_config.session_cookie_max_age,
  ))
}

fn require_valid_token(verification: LoginTokenVerification) -> Program(Nil) {
  case verification {
    ValidToken -> program.succeed(Nil)
    InvalidToken -> program.fail(error.auth(auth_error.InvalidLoginToken))
  }
}

type PreparedLogin {
  PreparedLogin(
    email: EmailAddress,
    token: String,
    attempted_at: Timestamp,
    valid_token_created_since: Timestamp,
    user_outcome: UserOutcome,
    session_issue: SessionIssue,
    user_action: UserAction,
  )
}

fn login_tx(
  prepared_login: PreparedLogin,
) -> TransactionProgram(LoginTokenVerification) {
  // Keep this lookup in the transaction because the query locks the tokens with
  // FOR UPDATE, preventing concurrent login attempts from losing updates.
  use tokens <- transaction_program.and_then(
    login_token_effect.list_login_tokens_by_email_tx(
      prepared_login.email,
      prepared_login.valid_token_created_since,
      valid_login_token_count,
    ),
  )
  let token_preparation =
    prepare_login_token_mutations(
      tokens,
      prepared_login.token,
      prepared_login.attempted_at,
    )
  let transaction =
    prepare_login_mutations(
      token_preparation,
      prepared_login.user_outcome,
      prepared_login.session_issue,
      prepared_login.user_action,
    )
  use _ <- transaction_program.and_then(transaction)

  transaction_program.succeed(token_preparation.verification)
}

type LoginTokenPreparation {
  LoginTokenPreparation(
    verification: LoginTokenVerification,
    attempt_transaction: TransactionProgram(Nil),
  )
}

fn prepare_login_token_mutations(
  tokens: List(LoginToken),
  provided_token: String,
  now: Timestamp,
) -> LoginTokenPreparation {
  let shared_attempt_count =
    list.fold(tokens, 0, fn(count, token) {
      int.max(count, token.attempt_count)
    })

  case tokens, shared_attempt_count >= max_login_token_attempts {
    [], _ ->
      LoginTokenPreparation(InvalidToken, transaction_program.succeed(Nil))
    _, True ->
      LoginTokenPreparation(InvalidToken, transaction_program.succeed(Nil))
    _, False -> {
      let matching_token = find_matching_token(tokens, provided_token)
      LoginTokenPreparation(
        verification_from_matching_token(matching_token),
        prepare_token_attempt_mutations(
          tokens,
          matching_token,
          shared_attempt_count,
          now,
        ),
      )
    }
  }
}

fn find_matching_token(
  tokens: List(LoginToken),
  provided_token: String,
) -> Option(LoginToken) {
  tokens
  |> list.find(fn(token) { token.token == provided_token })
  |> option.from_result()
}

fn verification_from_matching_token(
  matching_token: Option(LoginToken),
) -> LoginTokenVerification {
  case matching_token {
    option.Some(_) -> ValidToken
    option.None -> InvalidToken
  }
}

fn prepare_token_attempt_mutations(
  tokens: List(LoginToken),
  matching_token: Option(LoginToken),
  shared_attempt_count: Int,
  now: Timestamp,
) -> TransactionProgram(Nil) {
  tokens
  |> list.map(fn(token) {
    token
    |> login_token_model.increment_attempt(shared_attempt_count)
    |> mark_matching_token_as_used(matching_token, now)
    |> login_token_effect.update_login_token_tx
  })
  |> transaction_program.sequence
}

fn mark_matching_token_as_used(
  token: LoginToken,
  matching_token: Option(LoginToken),
  now: Timestamp,
) -> LoginToken {
  case matching_token {
    option.Some(matching) if matching.id == token.id ->
      login_token_model.mark_as_used(token, now)
    _ -> token
  }
}

fn prepare_login_mutations(
  token_preparation: LoginTokenPreparation,
  user_outcome: UserOutcome,
  session_issue: SessionIssue,
  user_action: UserAction,
) -> TransactionProgram(Nil) {
  use _ <- transaction_program.and_then(token_preparation.attempt_transaction)

  case token_preparation.verification {
    InvalidToken -> transaction_program.succeed(Nil)
    ValidToken ->
      transaction_program.sequence([
        prepare_user_mutations(user_outcome),
        session_effect.create_session_tx(session_issue.session),
        user_action_effect.create_user_action_tx(user_action),
      ])
  }
}

pub fn request_from_dynamic(
  ctx: Context,
  data: Dynamic,
) -> Program(LoginRequest) {
  program.decode_dynamic(data, login_dto.decoder(ctx.regexes.is_email))
}

type UserOutcome {
  ExistingUser(user: User)
  NewUser(user: User, account: Account)
}

fn update_or_create_user(
  maybe_user: Option(HydratedUser),
  email: EmailAddress,
  now: Timestamp,
) -> Program(UserOutcome) {
  case maybe_user {
    option.Some(existing_user) -> {
      program.succeed(ExistingUser(existing_user.identity))
    }
    option.None -> {
      use user_id <- program.and_then(basic_effect.uuid_v7())
      use account_id <- program.and_then(basic_effect.uuid_v7())
      let new_account = new_account(account_id, now)
      let new_user = new_user(user_id, account_id, email, now)

      program.succeed(NewUser(new_user, new_account))
    }
  }
}

fn user_from_outcome(user_outcome: UserOutcome) -> User {
  case user_outcome {
    ExistingUser(user) -> user
    NewUser(user, _) -> user
  }
}

fn mark_user_last_login(
  user_outcome: UserOutcome,
  now: Timestamp,
) -> UserOutcome {
  case user_outcome {
    ExistingUser(user) -> ExistingUser(user_model.mark_last_login(user, now))
    NewUser(user, account) ->
      NewUser(user_model.mark_last_login(user, now), account)
  }
}

fn is_new_user(user_outcome: UserOutcome) -> Bool {
  case user_outcome {
    ExistingUser(_) -> False
    NewUser(_, _) -> True
  }
}

fn prepare_user_mutations(
  user_outcome: UserOutcome,
) -> TransactionProgram(Nil) {
  case user_outcome {
    NewUser(user, account) ->
      transaction_program.sequence([
        account_effect.create_account_tx(account),
        user_effect.create_user_tx(user),
      ])
    ExistingUser(user) -> user_effect.update_user_tx(user)
  }
}

fn new_user(
  id: Uuid,
  account_id: Uuid,
  email: EmailAddress,
  now: Timestamp,
) -> User {
  user_model.User(
    id: id,
    account_id: account_id,
    email: email,
    username: uuid.to_string(id),
    role: user_model.RegularUser,
    last_login_at: now,
    created_at: now,
    updated_at: now,
  )
}

fn new_account(id: Uuid, now: Timestamp) -> Account {
  account_model.Account(
    id: id,
    account_state: account_model.Active,
    account_state_reason: option.None,
    account_tier: account_model.FreeTier,
    delete_job_id: option.None,
    created_at: now,
    updated_at: now,
  )
}

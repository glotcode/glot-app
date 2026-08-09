import gleam/time/timestamp.{type Timestamp}
import glot_backend/auth/effect/algebra/login_token as login_token_algebra
import glot_backend/auth/effect/command_result
import glot_backend/auth/effect/effect as auth_effect
import glot_backend/system/effect/error/db_error
import glot_backend/system/effect/program_types
import glot_core/auth/login_token_model
import glot_core/email/email_address_model

pub fn list_login_tokens_by_email(
  email email: email_address_model.EmailAddress,
  created_since created_since: Timestamp,
  limit limit: Int,
) -> program_types.Program(List(login_token_model.LoginToken)) {
  program_types.Impure(
    program_types.DbEffect(list_login_tokens_by_email_effect(
      email,
      created_since,
      limit,
      program_types.Pure,
    )),
  )
}

pub fn create_login_token(
  login_token login_token: login_token_model.LoginToken,
) -> program_types.Program(Nil) {
  program_types.Impure(
    program_types.DbEffect(create_login_token_effect(
      login_token,
      command_result.to_program,
    )),
  )
}

pub fn update_login_token(
  login_token login_token: login_token_model.LoginToken,
) -> program_types.Program(Nil) {
  program_types.Impure(
    program_types.DbEffect(update_login_token_effect(
      login_token,
      command_result.to_program,
    )),
  )
}

pub fn delete_login_tokens_before(
  before before: Timestamp,
) -> program_types.Program(Nil) {
  program_types.Impure(
    program_types.DbEffect(delete_login_tokens_before_effect(
      before,
      command_result.to_program,
    )),
  )
}

pub fn list_login_tokens_by_email_tx(
  email email: email_address_model.EmailAddress,
  created_since created_since: Timestamp,
  limit limit: Int,
) -> program_types.TransactionProgram(List(login_token_model.LoginToken)) {
  program_types.TxImpure(list_login_tokens_by_email_effect(
    email,
    created_since,
    limit,
    program_types.TxPure,
  ))
}

pub fn create_login_token_tx(
  login_token login_token: login_token_model.LoginToken,
) -> program_types.TransactionProgram(Nil) {
  program_types.TxImpure(create_login_token_effect(
    login_token,
    command_result.to_transaction_program,
  ))
}

pub fn update_login_token_tx(
  login_token login_token: login_token_model.LoginToken,
) -> program_types.TransactionProgram(Nil) {
  program_types.TxImpure(update_login_token_effect(
    login_token,
    command_result.to_transaction_program,
  ))
}

pub fn delete_login_tokens_before_tx(
  before before: Timestamp,
) -> program_types.TransactionProgram(Nil) {
  program_types.TxImpure(delete_login_tokens_before_effect(
    before,
    command_result.to_transaction_program,
  ))
}

pub fn invalidate_by_emails_tx(
  old_email: email_address_model.EmailAddress,
  new_email: email_address_model.EmailAddress,
  timestamp: Timestamp,
) -> program_types.TransactionProgram(Nil) {
  program_types.TxImpure(
    auth_effect.login_token(login_token_algebra.InvalidateLoginTokensByEmails(
      old_email:,
      new_email:,
      timestamp:,
      next: command_result.to_transaction_program,
    )),
  )
}

fn list_login_tokens_by_email_effect(
  email: email_address_model.EmailAddress,
  created_since: Timestamp,
  limit: Int,
  next: fn(List(login_token_model.LoginToken)) -> next,
) -> program_types.DbEffect(next) {
  auth_effect.login_token(login_token_algebra.ListLoginTokensByEmail(
    email:,
    created_since:,
    limit:,
    next: next,
  ))
}

fn create_login_token_effect(
  login_token: login_token_model.LoginToken,
  next: fn(Result(Nil, db_error.DbCommandError)) -> next,
) -> program_types.DbEffect(next) {
  auth_effect.login_token(login_token_algebra.CreateLoginToken(
    login_token:,
    next: next,
  ))
}

fn update_login_token_effect(
  login_token: login_token_model.LoginToken,
  next: fn(Result(Nil, db_error.DbCommandError)) -> next,
) -> program_types.DbEffect(next) {
  auth_effect.login_token(login_token_algebra.UpdateLoginToken(
    login_token:,
    next: next,
  ))
}

fn delete_login_tokens_before_effect(
  before: Timestamp,
  next: fn(Result(Nil, db_error.DbCommandError)) -> next,
) -> program_types.DbEffect(next) {
  auth_effect.login_token(login_token_algebra.DeleteLoginTokensBefore(
    before: before,
    next: next,
  ))
}

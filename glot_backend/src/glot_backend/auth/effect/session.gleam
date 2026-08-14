import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_backend/auth/effect/algebra/session as session_algebra
import glot_backend/auth/effect/command_result
import glot_backend/auth/effect/effect as auth_effect
import glot_backend/system/effect/error/db_error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types
import glot_backend/system/effect/transaction/transaction_program
import glot_core/auth/session_model
import youid/uuid.{type Uuid}

pub fn list_sessions_by_user_id(
  user_id user_id: Uuid,
  created_since created_since: Timestamp,
  last_activity_since last_activity_since: Timestamp,
) -> program_types.Program(List(session_model.Session)) {
  program.perform_db(list_sessions_by_user_id_effect(
    user_id,
    created_since,
    last_activity_since,
    program.succeed,
  ))
}

pub fn get_session_by_token(
  token token: String,
) -> program_types.Program(option.Option(session_model.HydratedSession)) {
  program.perform_db(get_session_by_token_effect(token, program.succeed))
}

pub fn get_session_by_previous_token(
  token token: String,
) -> program_types.Program(option.Option(session_model.HydratedSession)) {
  program.perform_db(get_session_by_previous_token_effect(
    token,
    program.succeed,
  ))
}

pub fn get_session_by_token_for_update_tx(
  token token: String,
) -> program_types.TransactionProgram(option.Option(session_model.Session)) {
  transaction_program.perform(get_session_by_token_for_update_effect(
    token,
    transaction_program.succeed,
  ))
}

pub fn get_session_by_previous_token_for_update_tx(
  token token: String,
) -> program_types.TransactionProgram(option.Option(session_model.Session)) {
  transaction_program.perform(get_session_by_previous_token_for_update_effect(
    token,
    transaction_program.succeed,
  ))
}

pub fn delete_sessions_by_account_id(
  id id: Uuid,
) -> program_types.Program(Nil) {
  program.perform_db(delete_sessions_by_account_id_effect(
    id,
    command_result.to_program,
  ))
}

pub fn delete_expired_sessions(
  created_before created_before: Timestamp,
  last_activity_before last_activity_before: Timestamp,
) -> program_types.Program(Nil) {
  program.perform_db(delete_expired_sessions_effect(
    created_before,
    last_activity_before,
    command_result.to_program,
  ))
}

pub fn create_session(
  session session: session_model.Session,
) -> program_types.Program(Nil) {
  program.perform_db(create_session_effect(session, command_result.to_program))
}

pub fn delete_session(id id: Uuid) -> program_types.Program(Nil) {
  program.perform_db(delete_session_effect(id, command_result.to_program))
}

pub fn get_session_by_token_tx(
  token token: String,
) -> program_types.TransactionProgram(
  option.Option(session_model.HydratedSession),
) {
  transaction_program.perform(get_session_by_token_effect(
    token,
    transaction_program.succeed,
  ))
}

pub fn delete_sessions_by_account_id_tx(
  id id: Uuid,
) -> program_types.TransactionProgram(Nil) {
  transaction_program.perform(delete_sessions_by_account_id_effect(
    id,
    command_result.to_transaction_program,
  ))
}

pub fn delete_expired_sessions_tx(
  created_before created_before: Timestamp,
  last_activity_before last_activity_before: Timestamp,
) -> program_types.TransactionProgram(Nil) {
  transaction_program.perform(delete_expired_sessions_effect(
    created_before,
    last_activity_before,
    command_result.to_transaction_program,
  ))
}

pub fn create_session_tx(
  session session: session_model.Session,
) -> program_types.TransactionProgram(Nil) {
  transaction_program.perform(create_session_effect(
    session,
    command_result.to_transaction_program,
  ))
}

pub fn update_session_tx(
  session session: session_model.Session,
) -> program_types.TransactionProgram(Nil) {
  transaction_program.perform(update_session_effect(
    session,
    command_result.to_transaction_program,
  ))
}

pub fn delete_session_tx(id id: Uuid) -> program_types.TransactionProgram(Nil) {
  transaction_program.perform(delete_session_effect(
    id,
    command_result.to_transaction_program,
  ))
}

fn list_sessions_by_user_id_effect(
  user_id: Uuid,
  created_since: Timestamp,
  last_activity_since: Timestamp,
  next: fn(List(session_model.Session)) -> next,
) -> program_types.DbEffect(next) {
  auth_effect.session(session_algebra.ListSessionsByUserId(
    user_id: user_id,
    created_since: created_since,
    last_activity_since: last_activity_since,
    next: next,
  ))
}

fn get_session_by_token_effect(
  token: String,
  next: fn(option.Option(session_model.HydratedSession)) -> next,
) -> program_types.DbEffect(next) {
  auth_effect.session(session_algebra.GetSessionByToken(
    token: token,
    next: next,
  ))
}

fn get_session_by_token_for_update_effect(
  token: String,
  next: fn(option.Option(session_model.Session)) -> next,
) -> program_types.DbEffect(next) {
  auth_effect.session(session_algebra.GetSessionByTokenForUpdate(
    token: token,
    next: next,
  ))
}

fn get_session_by_previous_token_effect(
  token: String,
  next: fn(option.Option(session_model.HydratedSession)) -> next,
) -> program_types.DbEffect(next) {
  auth_effect.session(session_algebra.GetSessionByPreviousToken(
    token: token,
    next: next,
  ))
}

fn get_session_by_previous_token_for_update_effect(
  token: String,
  next: fn(option.Option(session_model.Session)) -> next,
) -> program_types.DbEffect(next) {
  auth_effect.session(session_algebra.GetSessionByPreviousTokenForUpdate(
    token: token,
    next: next,
  ))
}

fn delete_sessions_by_account_id_effect(
  id: Uuid,
  next: fn(Result(Nil, db_error.DbCommandError)) -> next,
) -> program_types.DbEffect(next) {
  auth_effect.session(session_algebra.DeleteSessionsByAccountId(
    account_id: id,
    next: next,
  ))
}

fn delete_expired_sessions_effect(
  created_before: Timestamp,
  last_activity_before: Timestamp,
  next: fn(Result(Nil, db_error.DbCommandError)) -> next,
) -> program_types.DbEffect(next) {
  auth_effect.session(session_algebra.DeleteExpiredSessions(
    created_before: created_before,
    last_activity_before: last_activity_before,
    next: next,
  ))
}

fn create_session_effect(
  session: session_model.Session,
  next: fn(Result(Nil, db_error.DbCommandError)) -> next,
) -> program_types.DbEffect(next) {
  auth_effect.session(session_algebra.CreateSession(session:, next: next))
}

fn update_session_effect(
  session: session_model.Session,
  next: fn(Result(Nil, db_error.DbCommandError)) -> next,
) -> program_types.DbEffect(next) {
  auth_effect.session(session_algebra.UpdateSession(session:, next: next))
}

fn delete_session_effect(
  id: Uuid,
  next: fn(Result(Nil, db_error.DbCommandError)) -> next,
) -> program_types.DbEffect(next) {
  auth_effect.session(session_algebra.DeleteSession(id:, next: next))
}

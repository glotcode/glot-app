import glot_backend/auth/effect/algebra/account as account_algebra
import glot_backend/auth/effect/command_result
import glot_backend/auth/effect/effect as auth_effect
import glot_backend/system/effect/error/db_error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types
import glot_backend/system/effect/transaction/transaction_program
import glot_core/auth/account_model
import youid/uuid.{type Uuid}

pub fn create_account(
  account account: account_model.Account,
) -> program_types.Program(Nil) {
  program.perform_db(create_account_effect(account, command_result.to_program))
}

pub fn update_account(
  account account: account_model.Account,
) -> program_types.Program(Nil) {
  program.perform_db(update_account_effect(account, command_result.to_program))
}

pub fn delete_account(id id: Uuid) -> program_types.Program(Nil) {
  program.perform_db(delete_account_effect(id, command_result.to_program))
}

pub fn create_account_tx(
  account account: account_model.Account,
) -> program_types.TransactionProgram(Nil) {
  transaction_program.perform(create_account_effect(
    account,
    command_result.to_transaction_program,
  ))
}

pub fn update_account_tx(
  account account: account_model.Account,
) -> program_types.TransactionProgram(Nil) {
  transaction_program.perform(update_account_effect(
    account,
    command_result.to_transaction_program,
  ))
}

pub fn delete_account_tx(id id: Uuid) -> program_types.TransactionProgram(Nil) {
  transaction_program.perform(delete_account_effect(
    id,
    command_result.to_transaction_program,
  ))
}

fn create_account_effect(
  account: account_model.Account,
  next: fn(Result(Nil, db_error.DbCommandError)) -> next,
) -> program_types.DbEffect(next) {
  auth_effect.account(account_algebra.CreateAccount(account:, next: next))
}

fn update_account_effect(
  account: account_model.Account,
  next: fn(Result(Nil, db_error.DbCommandError)) -> next,
) -> program_types.DbEffect(next) {
  auth_effect.account(account_algebra.UpdateAccount(account:, next: next))
}

fn delete_account_effect(
  id: Uuid,
  next: fn(Result(Nil, db_error.DbCommandError)) -> next,
) -> program_types.DbEffect(next) {
  auth_effect.account(account_algebra.DeleteAccount(account_id: id, next: next))
}

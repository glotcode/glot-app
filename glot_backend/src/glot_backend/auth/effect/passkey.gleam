import gleam/option
import glot_backend/auth/effect/algebra/passkey as passkey_algebra
import glot_backend/auth/effect/command_result
import glot_backend/auth/effect/effect as auth_effect
import glot_backend/system/effect/error/db_error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types
import glot_backend/system/effect/transaction/transaction_program
import glot_core/auth/passkey_challenge_model
import glot_core/auth/passkey_credential_model
import youid/uuid.{type Uuid}

pub fn get_passkey_credential_by_credential_id(
  credential_id credential_id: BitArray,
) -> program_types.Program(
  option.Option(passkey_credential_model.PasskeyCredential),
) {
  program.perform_db(get_passkey_credential_by_credential_id_effect(
    credential_id,
    program.succeed,
  ))
}

pub fn list_passkey_credentials_by_user_id(
  user_id user_id: Uuid,
) -> program_types.Program(List(passkey_credential_model.PasskeyCredential)) {
  program.perform_db(list_passkey_credentials_by_user_id_effect(
    user_id,
    program.succeed,
  ))
}

pub fn get_passkey_challenge_by_id(
  id id: Uuid,
) -> program_types.Program(
  option.Option(passkey_challenge_model.PasskeyChallenge),
) {
  program.perform_db(get_passkey_challenge_by_id_effect(id, program.succeed))
}

pub fn create_passkey_credential(
  passkey_credential passkey_credential: passkey_credential_model.PasskeyCredential,
) -> program_types.Program(Nil) {
  program.perform_db(create_passkey_credential_effect(
    passkey_credential,
    command_result.to_program,
  ))
}

pub fn create_passkey_challenge(
  passkey_challenge passkey_challenge: passkey_challenge_model.PasskeyChallenge,
) -> program_types.Program(Nil) {
  program.perform_db(create_passkey_challenge_effect(
    passkey_challenge,
    command_result.to_program,
  ))
}

pub fn delete_passkey_credential(id id: Uuid) -> program_types.Program(Nil) {
  program.perform_db(delete_passkey_credential_effect(
    id,
    command_result.to_program,
  ))
}

pub fn update_passkey_credential(
  passkey_credential passkey_credential: passkey_credential_model.PasskeyCredential,
) -> program_types.Program(Nil) {
  program.perform_db(update_passkey_credential_effect(
    passkey_credential,
    command_result.to_program,
  ))
}

pub fn delete_passkey_challenge(id id: Uuid) -> program_types.Program(Nil) {
  program.perform_db(delete_passkey_challenge_effect(
    id,
    command_result.to_program,
  ))
}

pub fn get_passkey_credential_by_credential_id_tx(
  credential_id credential_id: BitArray,
) -> program_types.TransactionProgram(
  option.Option(passkey_credential_model.PasskeyCredential),
) {
  transaction_program.perform(get_passkey_credential_by_credential_id_effect(
    credential_id,
    transaction_program.succeed,
  ))
}

pub fn list_passkey_credentials_by_user_id_tx(
  user_id user_id: Uuid,
) -> program_types.TransactionProgram(
  List(passkey_credential_model.PasskeyCredential),
) {
  transaction_program.perform(list_passkey_credentials_by_user_id_effect(
    user_id,
    transaction_program.succeed,
  ))
}

pub fn get_passkey_challenge_by_id_tx(
  id id: Uuid,
) -> program_types.TransactionProgram(
  option.Option(passkey_challenge_model.PasskeyChallenge),
) {
  transaction_program.perform(get_passkey_challenge_by_id_effect(
    id,
    transaction_program.succeed,
  ))
}

pub fn create_passkey_credential_tx(
  passkey_credential passkey_credential: passkey_credential_model.PasskeyCredential,
) -> program_types.TransactionProgram(Nil) {
  transaction_program.perform(create_passkey_credential_effect(
    passkey_credential,
    command_result.to_transaction_program,
  ))
}

pub fn create_passkey_challenge_tx(
  passkey_challenge passkey_challenge: passkey_challenge_model.PasskeyChallenge,
) -> program_types.TransactionProgram(Nil) {
  transaction_program.perform(create_passkey_challenge_effect(
    passkey_challenge,
    command_result.to_transaction_program,
  ))
}

pub fn delete_passkey_credential_tx(
  id id: Uuid,
) -> program_types.TransactionProgram(Nil) {
  transaction_program.perform(delete_passkey_credential_effect(
    id,
    command_result.to_transaction_program,
  ))
}

pub fn update_passkey_credential_tx(
  passkey_credential passkey_credential: passkey_credential_model.PasskeyCredential,
) -> program_types.TransactionProgram(Nil) {
  transaction_program.perform(update_passkey_credential_effect(
    passkey_credential,
    command_result.to_transaction_program,
  ))
}

pub fn delete_passkey_challenge_tx(
  id id: Uuid,
) -> program_types.TransactionProgram(Nil) {
  transaction_program.perform(delete_passkey_challenge_effect(
    id,
    command_result.to_transaction_program,
  ))
}

fn get_passkey_credential_by_credential_id_effect(
  credential_id: BitArray,
  next: fn(option.Option(passkey_credential_model.PasskeyCredential)) -> next,
) -> program_types.DbEffect(next) {
  auth_effect.passkey(passkey_algebra.GetPasskeyCredentialByCredentialId(
    credential_id: credential_id,
    next: next,
  ))
}

fn delete_passkey_credential_effect(
  id: Uuid,
  next: fn(Result(Nil, db_error.DbCommandError)) -> next,
) -> program_types.DbEffect(next) {
  auth_effect.passkey(passkey_algebra.DeletePasskeyCredential(
    id: id,
    next: next,
  ))
}

fn list_passkey_credentials_by_user_id_effect(
  user_id: Uuid,
  next: fn(List(passkey_credential_model.PasskeyCredential)) -> next,
) -> program_types.DbEffect(next) {
  auth_effect.passkey(passkey_algebra.ListPasskeyCredentialsByUserId(
    user_id: user_id,
    next: next,
  ))
}

fn get_passkey_challenge_by_id_effect(
  id: Uuid,
  next: fn(option.Option(passkey_challenge_model.PasskeyChallenge)) -> next,
) -> program_types.DbEffect(next) {
  auth_effect.passkey(passkey_algebra.GetPasskeyChallengeById(
    id: id,
    next: next,
  ))
}

fn create_passkey_credential_effect(
  passkey_credential: passkey_credential_model.PasskeyCredential,
  next: fn(Result(Nil, db_error.DbCommandError)) -> next,
) -> program_types.DbEffect(next) {
  auth_effect.passkey(passkey_algebra.CreatePasskeyCredential(
    passkey_credential: passkey_credential,
    next: next,
  ))
}

fn create_passkey_challenge_effect(
  passkey_challenge: passkey_challenge_model.PasskeyChallenge,
  next: fn(Result(Nil, db_error.DbCommandError)) -> next,
) -> program_types.DbEffect(next) {
  auth_effect.passkey(passkey_algebra.CreatePasskeyChallenge(
    passkey_challenge: passkey_challenge,
    next: next,
  ))
}

fn update_passkey_credential_effect(
  passkey_credential: passkey_credential_model.PasskeyCredential,
  next: fn(Result(Nil, db_error.DbCommandError)) -> next,
) -> program_types.DbEffect(next) {
  auth_effect.passkey(passkey_algebra.UpdatePasskeyCredential(
    passkey_credential: passkey_credential,
    next: next,
  ))
}

fn delete_passkey_challenge_effect(
  id: Uuid,
  next: fn(Result(Nil, db_error.DbCommandError)) -> next,
) -> program_types.DbEffect(next) {
  auth_effect.passkey(passkey_algebra.DeletePasskeyChallenge(id: id, next: next))
}

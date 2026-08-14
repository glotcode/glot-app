import gleam/time/timestamp.{type Timestamp}
import glot_backend/auth/effect/algebra/email_change as email_change_algebra
import glot_backend/auth/effect/command_result
import glot_backend/auth/effect/effect as auth_effect
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types
import glot_backend/system/effect/transaction/transaction_program
import glot_core/auth/email_change_token_model.{type EmailChangeToken}
import youid/uuid.{type Uuid}

pub fn list_by_user_id(
  user_id: Uuid,
  created_since: Timestamp,
  limit: Int,
) -> program_types.Program(List(EmailChangeToken)) {
  program.perform_db(
    auth_effect.email_change(email_change_algebra.ListEmailChangeTokensByUserId(
      user_id:,
      created_since:,
      limit:,
      next: program.succeed,
    )),
  )
}

pub fn list_by_user_id_tx(
  user_id: Uuid,
  created_since: Timestamp,
  limit: Int,
) -> program_types.TransactionProgram(List(EmailChangeToken)) {
  transaction_program.perform(
    auth_effect.email_change(
      email_change_algebra.ListEmailChangeTokensByUserIdForUpdate(
        user_id:,
        created_since:,
        limit:,
        next: transaction_program.succeed,
      ),
    ),
  )
}

pub fn create_tx(
  token: EmailChangeToken,
) -> program_types.TransactionProgram(Nil) {
  transaction_program.perform(
    auth_effect.email_change(email_change_algebra.CreateEmailChangeToken(
      token:,
      next: command_result.to_transaction_program,
    )),
  )
}

pub fn update_tx(
  token: EmailChangeToken,
) -> program_types.TransactionProgram(Nil) {
  transaction_program.perform(
    auth_effect.email_change(email_change_algebra.UpdateEmailChangeToken(
      token:,
      next: command_result.to_transaction_program,
    )),
  )
}

pub fn delete_before(before: Timestamp) -> program_types.Program(Nil) {
  program.perform_db(
    auth_effect.email_change(email_change_algebra.DeleteEmailChangeTokensBefore(
      before:,
      next: command_result.to_program,
    )),
  )
}

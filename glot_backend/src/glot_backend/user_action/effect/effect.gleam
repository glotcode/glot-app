import gleam/time/timestamp.{type Timestamp}
import glot_backend/system/effect/error
import glot_backend/system/effect/error/db_error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types
import glot_backend/system/effect/transaction/transaction_program
import glot_backend/user_action/effect/algebra as user_action_algebra
import glot_core/rate_limit
import glot_core/user_action.{type UserAction, type UserActionFilter}

pub fn count_user_actions(
  filter filter: UserActionFilter,
) -> program_types.Program(List(rate_limit.WindowCount)) {
  program.perform_db(count_user_actions_effect(filter, program.succeed))
}

pub fn create_user_action(
  user_action user_action: UserAction,
) -> program_types.Program(Nil) {
  program.perform_db(
    create_user_action_effect(user_action, program.from_mapped_result(
      _,
      map_error: error.database_command_error,
    )),
  )
}

pub fn delete_before(before: Timestamp) -> program_types.Program(Nil) {
  program.perform_db(
    delete_before_effect(before, program.from_mapped_result(
      _,
      map_error: error.database_command_error,
    )),
  )
}

pub fn count_user_actions_tx(
  filter filter: UserActionFilter,
) -> program_types.TransactionProgram(List(rate_limit.WindowCount)) {
  transaction_program.perform(count_user_actions_effect(
    filter,
    transaction_program.succeed,
  ))
}

pub fn create_user_action_tx(
  user_action user_action: UserAction,
) -> program_types.TransactionProgram(Nil) {
  transaction_program.perform(
    create_user_action_effect(
      user_action,
      transaction_program.from_mapped_result(
        _,
        map_error: error.database_command_error,
      ),
    ),
  )
}

pub fn delete_before_tx(
  before: Timestamp,
) -> program_types.TransactionProgram(Nil) {
  transaction_program.perform(
    delete_before_effect(before, transaction_program.from_mapped_result(
      _,
      map_error: error.database_command_error,
    )),
  )
}

fn count_user_actions_effect(
  filter: UserActionFilter,
  next: fn(List(rate_limit.WindowCount)) -> next,
) -> program_types.DbEffect(next) {
  program_types.UserActionEffect(user_action_algebra.CountUserActions(
    filter: filter,
    next: next,
  ))
}

fn create_user_action_effect(
  user_action: UserAction,
  next: fn(Result(Nil, db_error.DbCommandError)) -> next,
) -> program_types.DbEffect(next) {
  program_types.UserActionEffect(user_action_algebra.CreateUserAction(
    user_action: user_action,
    next: next,
  ))
}

fn delete_before_effect(
  before: Timestamp,
  next: fn(Result(Nil, db_error.DbCommandError)) -> next,
) -> program_types.DbEffect(next) {
  program_types.UserActionEffect(user_action_algebra.DeleteBefore(
    before: before,
    next: next,
  ))
}

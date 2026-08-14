import glot_backend/system/effect/error
import glot_backend/system/effect/error/db_error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types
import glot_backend/system/effect/transaction/transaction_program

pub fn to_program(
  result: Result(Nil, db_error.DbCommandError),
) -> program_types.Program(Nil) {
  program.from_mapped_result(result, map_error: error.database_command_error)
}

pub fn to_transaction_program(
  result: Result(Nil, db_error.DbCommandError),
) -> program_types.TransactionProgram(Nil) {
  transaction_program.from_mapped_result(
    result,
    map_error: error.database_command_error,
  )
}

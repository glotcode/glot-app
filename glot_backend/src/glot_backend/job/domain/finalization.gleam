import glot_backend/system/effect/basic/basic_effect
import glot_backend/system/effect/log
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{
  type Program, type TransactionProgram,
}
import glot_backend/system/effect/transaction/transaction_effect
import glot_backend/system/effect/transaction/transaction_program

pub type Finalization {
  Applied
  Skipped(warning: log.Fields)
}

pub fn commit(
  finalize: TransactionProgram(Finalization),
  mutations: List(TransactionProgram(Nil)),
) -> Program(Nil) {
  use result <- program.and_then(
    transaction_effect.run({
      use result <- transaction_program.and_then(finalize)
      use _ <- transaction_program.and_then(transaction_program.sequence(
        mutations,
      ))
      transaction_program.succeed(result)
    }),
  )

  case result {
    Applied -> program.succeed(Nil)
    Skipped(warning) -> basic_effect.warn(warning)
  }
}

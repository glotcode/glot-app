import glot_backend/system/effect/program
import glot_backend/system/effect/program_types
import glot_backend/system/effect/transaction/transaction_program

pub fn run(p: program_types.TransactionProgram(a)) -> program_types.Program(a) {
  program_types.Impure(
    program_types.TransactionEffect(
      program_types.Run(transaction_program.map(p, program.succeed)),
    ),
  )
}

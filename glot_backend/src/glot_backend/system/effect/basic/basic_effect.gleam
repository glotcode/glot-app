import gleam/time/timestamp.{type Timestamp}
import glot_backend/system/crypto/token
import glot_backend/system/effect/basic/basic_algebra
import glot_backend/system/effect/log
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types
import youid/uuid.{type Uuid}

pub fn new_token(
  length: Int,
  alphabet: token.Alphabet,
) -> program_types.Program(String) {
  program.perform(
    program_types.BasicEffect(basic_algebra.NewToken(
      length,
      alphabet,
      program.succeed,
    )),
  )
}

pub fn system_time() -> program_types.Program(Timestamp) {
  program.perform(
    program_types.BasicEffect(basic_algebra.SystemTime(program.succeed)),
  )
}

pub fn uuid_v7() -> program_types.Program(Uuid) {
  program.perform(
    program_types.BasicEffect(basic_algebra.UuidV7(program.succeed)),
  )
}

pub fn info(fields: log.Fields) -> program_types.Program(Nil) {
  program.perform(
    program_types.BasicEffect(basic_algebra.Log(
      log.Info,
      fields,
      program.succeed(Nil),
    )),
  )
}

pub fn warn(fields: log.Fields) -> program_types.Program(Nil) {
  program.perform(
    program_types.BasicEffect(basic_algebra.Log(
      log.Warn,
      fields,
      program.succeed(Nil),
    )),
  )
}

pub fn debug(fields: log.Fields) -> program_types.Program(Nil) {
  program.perform(
    program_types.BasicEffect(basic_algebra.Log(
      log.Debug,
      fields,
      program.succeed(Nil),
    )),
  )
}

import glot_backend/spam_classifier/domain/scoring
import glot_backend/spam_classifier/effect/effect
import glot_backend/system/effect/basic/basic_effect
import glot_backend/system/effect/log
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}

pub fn run() -> Program(Bool) {
  use report <- program.and_then(effect.index_batch())
  use _ <- program.and_then(
    basic_effect.info(
      log.from_list([
        log.string("spam_classifier_version", scoring.version),
        log.int("spam_index_scanned", report.scanned),
        log.int("spam_index_stored", report.stored),
        log.int("spam_index_stale", report.stale),
      ]),
    ),
  )
  program.succeed(report.scanned == 100)
}

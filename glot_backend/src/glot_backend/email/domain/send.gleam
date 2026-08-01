import glot_backend/email/effect/delivery/effect as email_effect
import glot_backend/system/effect/basic/basic_effect
import glot_backend/system/effect/log
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/context.{type Context}
import glot_core/email/email_model.{type Email}

pub fn send_email(email: Email) -> Program(Nil) {
  use result <- program.and_then(email_effect.send_email(email))
  use _ <- program.and_then(
    basic_effect.info(
      log.from_list([
        log.object("send_email_result", [
          log.string_list("delivered", result.delivered),
          log.string_list("permanent_bounces", result.permanent_bounces),
          log.string_list("queued", result.queued),
        ]),
      ]),
    ),
  )

  program.succeed(Nil)
}

pub fn email_from_json(ctx: Context, json_str: String) -> Program(Email) {
  program.parse_json(json_str, email_model.decoder(ctx.regexes.is_email))
}

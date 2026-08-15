import glot_backend/auth/passkey/ports/ceremony.{type Ceremony}
import glot_backend/email/ports/sender.{type Sender}
import glot_backend/run_code/ports/runner.{type Runner}
import glot_backend/spam_classifier/ports/client.{type Client}
import glot_backend/system/effect/basic/basic_handlers

pub type SystemPorts {
  SystemPorts(
    basic: basic_handlers.BasicHandlers,
    email: Sender,
    passkey: Ceremony,
    run_code: Runner,
    spam_classifier: Client,
  )
}

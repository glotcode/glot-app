import glot_backend/auth/passkey/ports/ceremony as passkey_port
import glot_backend/email/ports/sender as email_sender
import glot_backend/run_code/ports/runner
import glot_backend/system/effect/basic/basic_handlers
import glot_backend/system/effect/error
import glot_backend/system/effect/error/infra_error
import glot_backend/system/effect/error/run_request_error
import glot_backend/system/effect/system_ports
import glot_core/email/email_model.{type SendEmailResult}
import glot_core/run.{type RunResult}
import support/integration/adapter/passkey_ceremony
import support/integration/adapter/state

pub fn defaults(test_state: state.State) -> system_ports.SystemPorts {
  system_ports.SystemPorts(
    basic: basic_handlers.BasicHandlers(
      new_token: fn(_, _) { "random" },
      system_time: fn() { state.get(test_state).system_time },
      uuid_v7: fn(_) { state.pop_uuid(test_state) },
    ),
    email: email_sender.Sender(send: fn(_, _, _) {
      Error(
        error.infra(
          infra_error.EmailError(infra_error.EmailDeliveryFailed(
            "unexpected test port call: email.send",
            infra_error.Retryable,
          )),
        ),
      )
    }),
    passkey: passkey_port.Ceremony(
      new_registration_challenge: fn(_, _, _) {
        Error("unexpected test port call: passkey.new_registration_challenge")
      },
      register: fn(_, _, _) {
        Error("unexpected test port call: passkey.register")
      },
      new_authentication_challenge: fn(_, _, _, _) {
        Error("unexpected test port call: passkey.new_authentication_challenge")
      },
      authenticate: fn(_, _, _, _, _, _) {
        Error("unexpected test port call: passkey.authenticate")
      },
    ),
    run_code: runner.Runner(run: fn(_, _, _) {
      Error(run_request_error.ClientRunRequestError(
        "unexpected test port call: run_code.run",
      ))
    }),
  )
}

pub fn with_email(ports: system_ports.SystemPorts) -> system_ports.SystemPorts {
  system_ports.SystemPorts(
    ..ports,
    email: email_sender.Sender(send: fn(_, _, _) {
      Error(
        error.infra(
          infra_error.EmailError(infra_error.EmailDeliveryFailed(
            "test_delivery_failure",
            infra_error.Retryable,
          )),
        ),
      )
    }),
  )
}

pub fn with_email_result(
  ports: system_ports.SystemPorts,
  result: SendEmailResult,
) -> system_ports.SystemPorts {
  system_ports.SystemPorts(
    ..ports,
    email: email_sender.Sender(send: fn(_, _, _) { Ok(result) }),
  )
}

pub fn with_passkey(
  ports: system_ports.SystemPorts,
) -> system_ports.SystemPorts {
  system_ports.SystemPorts(..ports, passkey: passkey_ceremony.new())
}

pub fn with_run_code(
  ports: system_ports.SystemPorts,
) -> system_ports.SystemPorts {
  system_ports.SystemPorts(
    ..ports,
    run_code: runner.Runner(run: fn(_, _, _) {
      Error(run_request_error.ServerRunRequestError)
    }),
  )
}

pub fn with_run_code_result(
  ports: system_ports.SystemPorts,
  result: RunResult,
) -> system_ports.SystemPorts {
  system_ports.SystemPorts(
    ..ports,
    run_code: runner.Runner(run: fn(_, _, _) { Ok(result) }),
  )
}

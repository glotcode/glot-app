import exception
import gleam/option
import gleam/result
import glot_backend/auth/passkey/ports/ceremony
import glot_backend/auth/ports as auth_ports
import glot_backend/email/model/config as email_config
import glot_backend/email/ports/sender
import glot_backend/job/ports as job_ports
import glot_backend/run_code/model/config as run_code_config
import glot_backend/run_code/ports/runner as run_code_runner
import glot_backend/system/effect/database_ports
import glot_backend/system/effect/error
import glot_backend/system/effect/error/run_request_error
import glot_backend/system/effect/service_ports.{type ServicePorts}
import glot_backend/system/effect/system_ports
import glot_core/email/email_model
import glot_core/language
import glot_core/run
import support/integration/adapter/state
import support/integration/fixture
import support/integration/profile/admin
import support/integration/profile/auth
import support/integration/profile/contact
import support/integration/profile/email
import support/integration/profile/job
import support/integration/profile/logging
import support/integration/profile/run_code
import support/integration/profile/snippet
import support/integration/profile/user_action

type ExpectedPorts {
  ExpectedPorts(
    app_config: Bool,
    auth: Bool,
    snippet: Bool,
    email_template: Bool,
    job: Bool,
    run_log: Bool,
    user_action: Bool,
    email: Bool,
    passkey: Bool,
    run_code: Bool,
  )
}

pub fn admin_profile_declares_only_admin_dependencies_test() {
  assert_profile(
    admin.service_ports,
    ExpectedPorts(..expected(), app_config: True, auth: True, user_action: True),
  )
}

pub fn auth_profile_declares_only_auth_dependencies_test() {
  assert_profile(
    auth.service_ports,
    ExpectedPorts(
      ..expected(),
      app_config: True,
      auth: True,
      snippet: True,
      email_template: True,
      job: True,
      user_action: True,
      email: True,
      passkey: True,
    ),
  )
}

pub fn contact_profile_declares_only_contact_dependencies_test() {
  assert_profile(
    contact.service_ports,
    ExpectedPorts(
      ..expected(),
      app_config: True,
      auth: True,
      email_template: True,
      job: True,
      user_action: True,
      email: True,
    ),
  )
}

pub fn email_profile_declares_only_email_dependencies_test() {
  assert_profile(
    email.service_ports,
    ExpectedPorts(..expected(), app_config: True, email: True),
  )
}

pub fn job_profile_declares_only_job_dependencies_test() {
  assert_profile(
    job.service_ports,
    ExpectedPorts(..expected(), app_config: True, job: True),
  )
}

pub fn logging_profile_declares_only_logging_dependencies_test() {
  assert_profile(
    logging.service_ports,
    ExpectedPorts(..expected(), app_config: True, run_log: True),
  )
}

pub fn run_code_profile_declares_only_run_code_dependencies_test() {
  assert_profile(
    run_code.service_ports,
    ExpectedPorts(..expected(), app_config: True, run_code: True),
  )
}

pub fn snippet_profile_declares_only_snippet_dependencies_test() {
  assert_profile(
    snippet.service_ports,
    ExpectedPorts(
      ..expected(),
      app_config: True,
      auth: True,
      snippet: True,
      user_action: True,
    ),
  )
}

pub fn user_action_profile_declares_only_user_action_dependencies_test() {
  assert_profile(
    user_action.service_ports,
    ExpectedPorts(..expected(), app_config: True, user_action: True),
  )
}

fn expected() -> ExpectedPorts {
  ExpectedPorts(
    app_config: False,
    auth: False,
    snippet: False,
    email_template: False,
    job: False,
    run_log: False,
    user_action: False,
    email: False,
    passkey: False,
    run_code: False,
  )
}

fn assert_profile(
  build: fn(state.State) -> ServicePorts,
  expected: ExpectedPorts,
) -> Nil {
  let fixture =
    fixture.integration_fixture(
      next_uuids: [],
      jobs: [],
      account_delete_job_id: option.None,
    )
  let test_state = state.new(fixture.state)
  use <- exception.defer(fn() { state.stop(test_state) })
  let services = build(test_state)
  let database = services.database

  assert result.is_ok(database_ports.app_config(database).list_entries())
    == expected.app_config

  let auth_ports.Ports(accounts:, ..) = database_ports.auth(database)
  assert result.is_ok(accounts.update(fixture.account)) == expected.auth

  assert result.is_ok(database_ports.snippet(database).update_snippet(
      fixture.snippet,
    ))
    == expected.snippet

  assert result.is_ok(database_ports.email_template(database).list())
    == expected.email_template

  let job_ports.Ports(type_policies:, ..) = database_ports.job(database)
  assert result.is_ok(type_policies.list_job_type_policies()) == expected.job

  assert result.is_ok(
      database_ports.logging(database).run_log.delete_before(
        fixture.test_timestamp(),
      ),
    )
    == expected.run_log

  assert result.is_ok(
      database_ports.user_action(database).delete_before(
        fixture.test_timestamp(),
      ),
    )
    == expected.user_action

  assert email_enabled(services.system) == expected.email
  assert passkey_enabled(services.system) == expected.passkey
  assert run_code_enabled(services.system) == expected.run_code
}

fn email_enabled(ports: system_ports.SystemPorts) -> Bool {
  let system_ports.SystemPorts(email:, ..) = ports
  let sender.Sender(send:) = email
  let result =
    send(
      email_config.CloudflareConfig("account", "token"),
      email_model.Email(
        from: email_model.default_from_sender(),
        to: email_model.default_from_address(),
        subject: "subject",
        text_body: "body",
        html_body: option.None,
      ),
      1000,
    )

  case result {
    Error(err) ->
      error.to_string(err) == "send_email_delivery_failed:test_delivery_failure"
    Ok(_) -> True
  }
}

fn passkey_enabled(ports: system_ports.SystemPorts) -> Bool {
  let system_ports.SystemPorts(passkey:, ..) = ports
  let ceremony.Ceremony(authenticate:, ..) = passkey
  result.is_ok(
    authenticate(<<>>, <<>>, <<>>, "test-passkey-login-success", <<>>, []),
  )
}

fn run_code_enabled(ports: system_ports.SystemPorts) -> Bool {
  let system_ports.SystemPorts(run_code:, ..) = ports
  let run_code_runner.Runner(run: run_code) = run_code
  let result =
    run_code(
      run_code_config.DockerRunConfig("http://localhost", "token", 1000),
      run.RunRequest(
        image: "python:latest",
        payload: run.RunRequestPayload(
          run_instructions: language.RunInstructions([], "python main.py"),
          files: [],
          stdin: option.None,
        ),
      ),
      1000,
    )

  result == Error(run_request_error.ServerRunRequestError)
}

import gleam/dict
import gleam/option
import gleam/result
import gleam/string
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/contact/domain/submit as submit_contact_domain
import glot_backend/email/model/config as email_config
import glot_backend/system/effect/error
import glot_backend/system/effect/error/infra_error
import glot_backend/system/request/hydrated_context as request_context
import glot_core/contact_dto
import glot_core/validation_error
import support/integration/fixture
import support/integration/model
import support/integration/profile/contact as runner
import support/integration/store/common
import youid/uuid

pub fn anonymous_contact_queues_email_and_audit_action_test() {
  let user_action_id = fixture.must_uuid("00000000-0000-0000-0000-000000000541")
  let job_id = fixture.must_uuid("00000000-0000-0000-0000-000000000542")
  let ctx = fixture.anonymous_test_context()
  let db =
    model.TestState(..fixture.empty_test_state(), next_uuids: [
      user_action_id,
      job_id,
    ])
  let request =
    contact_dto.ContactRequest(
      email: "visitor@example.com",
      topic: "privacy",
      message: "Please tell me what data you hold about me.",
      website: "",
    )

  let #(run_result, updated_db) =
    runner.run_test_program(
      submit_contact_domain.submit_contact(
        request_context.new(ctx, db.dynamic_config),
        request,
      ),
      ctx,
      db,
    )

  assert run_result == Ok(Nil)
  assert dict.has_key(updated_db.jobs, common.uuid_key(job_id))
  assert updated_db.user_action_count == 1
}

pub fn contact_honeypot_is_acknowledged_without_email_test() {
  let user_action_id = fixture.must_uuid("00000000-0000-0000-0000-000000000543")
  let ctx = fixture.anonymous_test_context()
  let db =
    model.TestState(..fixture.empty_test_state(), next_uuids: [user_action_id])
  let request =
    contact_dto.ContactRequest(
      email: "bot@example.com",
      topic: "general",
      message: "Automated message",
      website: "https://spam.example",
    )

  let #(run_result, updated_db) =
    runner.run_test_program(
      submit_contact_domain.submit_contact(
        request_context.new(ctx, db.dynamic_config),
        request,
      ),
      ctx,
      db,
    )

  assert run_result == Ok(Nil)
  assert dict.is_empty(updated_db.jobs)
  assert updated_db.user_action_count == 1
}

pub fn authenticated_contact_includes_the_user_id_test() {
  let user_action_id = fixture.must_uuid("00000000-0000-0000-0000-000000000544")
  let job_id = fixture.must_uuid("00000000-0000-0000-0000-000000000545")
  let fixture =
    fixture.integration_fixture(
      next_uuids: [user_action_id, job_id],
      jobs: [],
      account_delete_job_id: option.None,
    )
  let request = valid_request()

  let #(run_result, db) =
    runner.run_test_program(
      submit_contact_domain.submit_contact(
        request_context.new(fixture.ctx, fixture.state.dynamic_config),
        request,
      ),
      fixture.ctx,
      fixture.state,
    )

  assert run_result == Ok(Nil)
  let assert Ok(job) = dict.get(db.jobs, common.uuid_key(job_id))
  let assert option.Some(payload) = job.payload
  assert string.contains(payload, uuid.to_string(fixture.user.id))
  assert db.user_action_count == 1
}

pub fn invalid_contact_does_not_queue_email_test() {
  let user_action_id = fixture.must_uuid("00000000-0000-0000-0000-000000000546")
  let ctx = fixture.anonymous_test_context()
  let db =
    model.TestState(..fixture.empty_test_state(), next_uuids: [user_action_id])
  let request = contact_dto.ContactRequest(..valid_request(), message: "  ")

  let #(run_result, updated_db) =
    runner.run_test_program(
      submit_contact_domain.submit_contact(
        request_context.new(ctx, db.dynamic_config),
        request,
      ),
      ctx,
      db,
    )

  assert run_result
    == Error(error.validation(validation_error.EmptyField("message")))
  assert dict.is_empty(updated_db.jobs)
  assert updated_db.user_action_count == 0
}

pub fn missing_contact_address_does_not_queue_email_test() {
  let user_action_id = fixture.must_uuid("00000000-0000-0000-0000-000000000547")
  let ctx = fixture.anonymous_test_context()
  let base_state = fixture.empty_test_state()
  let configured_email =
    email_config.EmailConfig(
      ..dynamic_config.email_config(base_state.dynamic_config),
      contact_address: option.None,
    )
  let config =
    dynamic_config.DynamicConfig(
      ..base_state.dynamic_config,
      email: option.Some(configured_email),
    )
  let db =
    model.TestState(..base_state, dynamic_config: config, next_uuids: [
      user_action_id,
    ])

  let #(run_result, updated_db) =
    runner.run_test_program(
      submit_contact_domain.submit_contact(
        request_context.new(ctx, config),
        valid_request(),
      ),
      ctx,
      db,
    )

  assert run_result
    == Error(
      error.infra(
        infra_error.EmailError(infra_error.EmailDeliveryFailed(
          "contact_address_not_configured",
          infra_error.NonRetryable,
        )),
      ),
    )
  assert dict.is_empty(updated_db.jobs)
  assert updated_db.user_action_count == 0
}

pub fn audit_failure_rolls_back_the_email_job_test() {
  let user_action_id = fixture.must_uuid("00000000-0000-0000-0000-000000000548")
  let job_id = fixture.must_uuid("00000000-0000-0000-0000-000000000549")
  let ctx = fixture.anonymous_test_context()
  let db =
    model.TestState(..fixture.empty_test_state(), next_uuids: [
      user_action_id,
      job_id,
    ])

  let #(run_result, updated_db) =
    runner.run_with_user_action_failure(
      submit_contact_domain.submit_contact(
        request_context.new(ctx, db.dynamic_config),
        valid_request(),
      ),
      ctx,
      db,
    )

  assert result.is_error(run_result)
  assert dict.is_empty(updated_db.jobs)
  assert updated_db.user_action_count == 0
}

fn valid_request() -> contact_dto.ContactRequest {
  contact_dto.ContactRequest(
    email: "visitor@example.com",
    topic: "privacy",
    message: "Please tell me what data you hold about me.",
    website: "",
  )
}

import gleam/option
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/email/domain/send as send_email_domain
import glot_backend/system/effect/error
import glot_backend/system/effect/error/infra_error
import glot_backend/system/effect/error/resource_error
import glot_core/email/email_model
import support/integration/fixture
import support/integration/model
import support/integration/profile/email as runner

pub fn successful_delivery_is_acknowledged_test() {
  let ctx = fixture.test_context()
  let state = fixture.empty_test_state()
  let delivery =
    email_model.SendEmailResult(
      delivered: ["recipient@example.com"],
      permanent_bounces: [],
      queued: [],
    )

  let #(result, _) =
    runner.run_with_delivery_result(
      send_email_domain.send_email(test_email()),
      ctx,
      state,
      delivery,
    )

  assert result == Ok(Nil)
}

pub fn delivery_failure_is_returned_test() {
  let ctx = fixture.test_context()
  let state = fixture.empty_test_state()

  let #(result, _) =
    runner.run_test_program(
      send_email_domain.send_email(test_email()),
      ctx,
      state,
    )

  assert result
    == Error(
      error.infra(
        infra_error.EmailError(infra_error.EmailDeliveryFailed(
          "test_delivery_failure",
          infra_error.Retryable,
        )),
      ),
    )
}

pub fn missing_cloudflare_config_prevents_delivery_test() {
  let ctx = fixture.test_context()
  let base_state = fixture.empty_test_state()
  let config =
    dynamic_config.DynamicConfig(
      ..base_state.dynamic_config,
      cloudflare: option.None,
    )
  let state = model.TestState(..base_state, dynamic_config: config)
  let delivery = email_model.SendEmailResult([], [], [])

  let #(result, _) =
    runner.run_with_delivery_result(
      send_email_domain.send_email(test_email()),
      ctx,
      state,
      delivery,
    )

  assert result
    == Error(error.resource(resource_error.CloudflareConfigNotFound))
}

fn test_email() -> email_model.Email {
  email_model.Email(
    from: email_model.default_from_sender(),
    to: fixture.test_email_address(),
    subject: "Subject",
    text_body: "Body",
    html_body: option.None,
  )
}

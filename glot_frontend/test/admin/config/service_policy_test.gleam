import gleam/option
import gleeunit
import glot_core/admin/cloudflare_config_dto
import glot_core/admin/docker_run_config_dto
import glot_core/admin/email_config_dto
import glot_core/admin/passkey_config_dto
import glot_frontend/admin/config/cloudflare_policy
import glot_frontend/admin/config/docker_run_policy
import glot_frontend/admin/config/email_policy
import glot_frontend/admin/config/passkey_policy

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn cloudflare_policy_owns_empty_edit_and_validation_rules_test() {
  assert cloudflare_policy.is_empty(cloudflare_policy.empty())
  let fields =
    cloudflare_policy.empty()
    |> cloudflare_policy.set(cloudflare_policy.AccountId, "account")
    |> cloudflare_policy.set(cloudflare_policy.ApiToken, "token")

  assert !cloudflare_policy.is_empty(fields)
  assert cloudflare_policy.request(fields)
    == Ok(cloudflare_config_dto.UpsertCloudflareConfigRequest(
      "account",
      "token",
    ))
  assert cloudflare_policy.request(cloudflare_policy.Fields("", "token"))
    == Error("Account ID must not be empty.")
  assert cloudflare_policy.request(cloudflare_policy.Fields("account", ""))
    == Error("API token must not be empty.")
  assert cloudflare_policy.from_response(
      cloudflare_config_dto.CloudflareConfigResponse("account", "token"),
    )
    == fields
}

pub fn docker_run_policy_maps_required_values_and_timeout_test() {
  assert docker_run_policy.is_empty(docker_run_policy.empty())
  let fields =
    docker_run_policy.from_response(
      docker_run_config_dto.DockerRunConfigResponse(
        "https://runner",
        "token",
        30,
      ),
    )
  assert docker_run_policy.request(fields)
    == Ok(docker_run_config_dto.UpsertDockerRunConfigRequest(
      "https://runner",
      "token",
      30,
    ))
  assert docker_run_policy.request(docker_run_policy.set(
      fields,
      docker_run_policy.BaseUrl,
      "",
    ))
    == Error("Base URL must not be empty.")
  assert docker_run_policy.request(docker_run_policy.set(
      fields,
      docker_run_policy.AccessToken,
      "",
    ))
    == Error("Access token must not be empty.")
  assert docker_run_policy.request(docker_run_policy.set(
      fields,
      docker_run_policy.DefaultTimeout,
      "0",
    ))
    == Error("Default timeout must be a positive integer.")
}

pub fn email_policy_preserves_optional_values_and_validates_required_values_test() {
  assert email_policy.is_empty(email_policy.empty())
  let empty_optional =
    email_policy.from_response(email_config_dto.EmailConfigResponse(
      "sender@example.com",
      option.None,
      option.None,
      30,
    ))
  assert email_policy.request(empty_optional)
    == Ok(email_config_dto.UpsertEmailConfigRequest(
      "sender@example.com",
      option.None,
      option.None,
      30,
    ))

  let populated =
    empty_optional
    |> email_policy.set(email_policy.FromName, "Sender")
    |> email_policy.set(email_policy.ContactAddress, "contact@example.com")
  assert email_policy.request(populated)
    == Ok(email_config_dto.UpsertEmailConfigRequest(
      "sender@example.com",
      option.Some("Sender"),
      option.Some("contact@example.com"),
      30,
    ))
  assert email_policy.request(email_policy.set(
      populated,
      email_policy.FromAddress,
      "",
    ))
    == Error("From address must not be empty.")
  assert email_policy.request(email_policy.set(
      populated,
      email_policy.DefaultTimeout,
      "0",
    ))
    == Error("Default timeout must be a positive integer.")
}

pub fn passkey_policy_owns_all_edits_and_validation_test() {
  let fields =
    passkey_policy.initial()
    |> passkey_policy.set_origin("https://glot.io")
    |> passkey_policy.set_rp_id("glot.io")
    |> passkey_policy.set_challenge_timeout("60")
  assert passkey_policy.request(fields)
    == Ok(passkey_config_dto.UpsertPasskeyConfigRequest(
      "https://glot.io",
      "glot.io",
      60,
    ))
  assert passkey_policy.request(passkey_policy.set_origin(fields, ""))
    == Error("Origin must not be empty.")
  assert passkey_policy.request(passkey_policy.set_rp_id(fields, ""))
    == Error("RP ID must not be empty.")
  assert passkey_policy.request(passkey_policy.set_challenge_timeout(
      fields,
      "0",
    ))
    == Error("Challenge timeout must be a positive integer.")
  assert passkey_policy.from_response(passkey_config_dto.PasskeyConfigResponse(
      "https://glot.io",
      "glot.io",
      60,
    ))
    == fields
}

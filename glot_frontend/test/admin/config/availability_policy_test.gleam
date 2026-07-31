import gleam/option
import gleeunit
import glot_core/admin/availability_config_dto
import glot_core/availability_mode
import glot_frontend/admin/config/availability_policy

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn availability_policy_owns_edits_and_optional_retry_after_test() {
  let initial = availability_policy.initial()
  let fields =
    initial
    |> availability_policy.select_mode(availability_mode.MaintenanceMode)
    |> availability_policy.set_message("Maintenance")
    |> availability_policy.set_retry_after("60")

  assert availability_policy.request(fields)
    == Ok(availability_config_dto.UpsertAvailabilityConfigRequest(
      availability_mode.MaintenanceMode,
      "Maintenance",
      option.Some(60),
    ))

  let without_retry = availability_policy.set_retry_after(fields, "")
  assert availability_policy.request(without_retry)
    == Ok(availability_config_dto.UpsertAvailabilityConfigRequest(
      availability_mode.MaintenanceMode,
      "Maintenance",
      option.None,
    ))
}

pub fn availability_policy_validates_message_and_retry_after_test() {
  let initial = availability_policy.initial()
  assert availability_policy.request(availability_policy.set_message(
      initial,
      "",
    ))
    == Error("Availability message must not be empty.")
  assert availability_policy.request(availability_policy.set_retry_after(
      initial,
      "0",
    ))
    == Error("Retry-After seconds must be a positive integer.")
}

pub fn availability_policy_maps_response_fields_test() {
  let fields =
    availability_policy.from_response(
      availability_config_dto.AvailabilityConfigResponse(
        availability_mode.ReadOnlyMode,
        "Read only",
        option.Some(120),
      ),
    )
  assert fields.mode == availability_mode.ReadOnlyMode
  assert fields.message == "Read only"
  assert fields.retry_after_seconds == "120"
}

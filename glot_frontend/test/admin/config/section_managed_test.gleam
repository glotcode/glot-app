import gleam/int
import gleeunit
import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/config/section
import glot_frontend/admin/config/section_managed
import glot_frontend/api/response as api_response
import glot_frontend/ui/mutation
import rsvp
import youid/uuid

pub fn main() -> Nil {
  gleeunit.main()
}

fn required_policy() -> section_managed.CompletionPolicy(String, Int) {
  section_managed.required(
    to_fields: int.to_string,
    load_http_failure: "load failed",
    save_http_failure: "save failed",
  )
}

fn optional_policy() -> section_managed.CompletionPolicy(String, Int) {
  section_managed.optional(
    to_fields: int.to_string,
    missing: section_managed.MissingConfig(
      code: "config_not_found",
      fields: "empty",
    ),
    load_http_failure: "load failed",
    save_http_failure: "save failed",
  )
}

pub fn ensure_loaded_starts_only_not_loaded_models_test() {
  let initial = section.init("initial")
  let #(loading, command) =
    section_managed.ensure_loaded(initial, fn(_) {
      admin_effect.CloseDialog("load")
    })

  assert loading.load_state == section.Loading
  let assert admin_effect.CloseDialog("load") = command

  let #(unchanged, repeated_command) =
    section_managed.ensure_loaded(loading, fn(_) {
      admin_effect.CloseDialog("repeated")
    })

  assert unchanged == loading
  let assert admin_effect.None = repeated_command
}

pub fn validated_save_starts_only_after_successful_validation_test() {
  let initial = section.init("initial")
  let #(invalid, invalid_command) =
    section_managed.begin_validated_save(
      initial,
      Error("invalid"),
      fn(request, _) { admin_effect.CloseDialog(request) },
    )

  assert invalid.mutation_state == mutation.SaveError("invalid")
  let assert admin_effect.None = invalid_command

  let #(saving, save_command) =
    section_managed.begin_validated_save(invalid, Ok("request"), fn(request, _) {
      admin_effect.CloseDialog(request)
    })

  assert saving.mutation_state == mutation.Saving
  let assert admin_effect.CloseDialog("request") = save_command
}

pub fn completions_map_success_and_reject_stale_generations_test() {
  let initial = section.init("initial")
  let #(first_loading, stale_generation) = section.begin_load(initial)
  let #(loading, generation) = section.begin_load(first_loading)

  let #(unchanged, stale_command) =
    section_managed.update(
      loading,
      section_managed.LoadCompleted(stale_generation, api_response.Success(1)),
      required_policy(),
    )
  assert unchanged == loading
  let assert admin_effect.None = stale_command

  let #(loaded, load_command) =
    section_managed.update(
      loading,
      section_managed.LoadCompleted(generation, api_response.Success(2)),
      required_policy(),
    )
  assert loaded.load_state == section.Ready
  assert loaded.saved == "2"
  let assert admin_effect.None = load_command

  let #(saving, save_generation) = section.begin_save(loaded)
  let #(saved, save_command) =
    section_managed.update(
      saving,
      section_managed.SaveCompleted(save_generation, api_response.Success(3)),
      required_policy(),
    )
  assert saved.saved == "3"
  assert saved.mutation_state == mutation.Saved
  let assert admin_effect.None = save_command
}

pub fn optional_load_treats_only_the_configured_code_as_empty_test() {
  let initial = section.init("initial")
  let #(loading, generation) = section.begin_load(initial)
  let request_id = uuid.v7()
  let missing: api_response.Response(Int) =
    api_response.ApiFailure(api_response.Error(
      code: "config_not_found",
      message: "missing",
      request_id:,
    ))

  let #(loaded, command) =
    section_managed.update(
      loading,
      section_managed.LoadCompleted(generation, missing),
      optional_policy(),
    )

  assert loaded.load_state == section.Ready
  assert loaded.saved == "empty"
  let assert admin_effect.None = command

  let #(loading_again, next_generation) = section.begin_load(loaded)
  let other_failure: api_response.Response(Int) =
    api_response.ApiFailure(api_response.Error(
      code: "other_failure",
      message: "failed",
      request_id:,
    ))
  let #(failed, _) =
    section_managed.update(
      loading_again,
      section_managed.LoadCompleted(next_generation, other_failure),
      optional_policy(),
    )

  assert failed.load_state
    == section.LoadError(
      api_response.error_message(api_response.Error(
        code: "other_failure",
        message: "failed",
        request_id:,
      )),
    )
}

pub fn api_failures_keep_the_standard_request_context_test() {
  let initial = section.init("initial")
  let #(loading, generation) = section.begin_load(initial)
  let request_id = uuid.v7()
  let failure: api_response.Response(Int) =
    api_response.ApiFailure(api_response.Error(
      code: "failure",
      message: "failed",
      request_id:,
    ))

  let #(failed, command) =
    section_managed.update(
      loading,
      section_managed.LoadCompleted(generation, failure),
      required_policy(),
    )

  assert failed.load_state
    == section.LoadError(
      api_response.error_message(api_response.Error(
        code: "failure",
        message: "failed",
        request_id:,
      )),
    )
  let assert admin_effect.None = command
}

pub fn http_failures_use_the_feature_messages_test() {
  let initial = section.init("initial")
  let #(loading, load_generation) = section.begin_load(initial)
  let #(load_failed, load_command) =
    section_managed.update(
      loading,
      section_managed.LoadCompleted(
        load_generation,
        api_response.HttpFailure(rsvp.NetworkError),
      ),
      required_policy(),
    )

  assert load_failed.load_state == section.LoadError("load failed")
  let assert admin_effect.None = load_command

  let #(saving, save_generation) = section.begin_save(load_failed)
  let #(save_failed, save_command) =
    section_managed.update(
      saving,
      section_managed.SaveCompleted(
        save_generation,
        api_response.HttpFailure(rsvp.NetworkError),
      ),
      required_policy(),
    )

  assert save_failed.load_state == section.LoadError("load failed")
  assert save_failed.mutation_state == mutation.SaveError("save failed")
  let assert admin_effect.None = save_command
}

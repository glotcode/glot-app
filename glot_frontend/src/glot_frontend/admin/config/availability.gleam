import glot_core/admin/availability_config_dto
import glot_core/availability_mode
import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/config/availability_policy
import glot_frontend/admin/config/section
import glot_frontend/admin/config/section_managed

pub type Model =
  section.FormModel(availability_policy.Fields)

pub type Msg {
  SectionEvent(
    section_managed.Event(availability_config_dto.AvailabilityConfigResponse),
  )
  ModeSelected(availability_mode.AvailabilityMode)
  MessageChanged(String)
  RetryAfterSecondsChanged(String)
  ResetClicked
  SaveClicked
}

pub fn init() -> Model {
  section.init(availability_policy.initial())
}

fn completion_policy() -> section_managed.CompletionPolicy(
  availability_policy.Fields,
  availability_config_dto.AvailabilityConfigResponse,
) {
  section_managed.required(
    to_fields: availability_policy.from_response,
    load_http_failure: "Could not load availability config.",
    save_http_failure: "Could not save availability config.",
  )
}

pub fn ensure_loaded(model: Model) -> #(Model, admin_effect.Command(Msg)) {
  section_managed.ensure_loaded(model, fn(generation) {
    admin_effect.get_admin_availability_config(fn(response) {
      SectionEvent(section_managed.LoadCompleted(generation, response))
    })
  })
}

pub fn update(model: Model, msg: Msg) -> #(Model, admin_effect.Command(Msg)) {
  case msg {
    SectionEvent(event) ->
      section_managed.update(model, event, completion_policy())
    ModeSelected(mode) -> #(
      section.edit(model, fn(fields) {
        availability_policy.select_mode(fields, mode)
      }),
      admin_effect.none(),
    )
    MessageChanged(message) -> #(
      section.edit(model, fn(fields) {
        availability_policy.set_message(fields, message)
      }),
      admin_effect.none(),
    )
    RetryAfterSecondsChanged(retry_after_seconds) -> #(
      section.edit(model, fn(fields) {
        availability_policy.set_retry_after(fields, retry_after_seconds)
      }),
      admin_effect.none(),
    )
    ResetClicked -> #(section.reset(model), admin_effect.none())
    SaveClicked ->
      section_managed.begin_validated_save(
        model,
        availability_policy.request(model.draft),
        fn(request, generation) {
          admin_effect.upsert_admin_availability_config(request, fn(response) {
            SectionEvent(section_managed.SaveCompleted(generation, response))
          })
        },
      )
  }
}

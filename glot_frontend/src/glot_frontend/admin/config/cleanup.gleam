import glot_core/admin/cleanup_config_dto
import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/config/cleanup_policy
import glot_frontend/admin/config/section
import glot_frontend/admin/config/section_managed

pub type Model =
  section.FormModel(cleanup_policy.Fields)

pub type Msg {
  SectionEvent(section_managed.Event(cleanup_config_dto.CleanupConfigResponse))
  FieldChanged(cleanup_policy.Field, String)
  ResetClicked
  SaveClicked
}

pub fn init() -> Model {
  section.init(cleanup_policy.initial())
}

fn completion_policy() -> section_managed.CompletionPolicy(
  cleanup_policy.Fields,
  cleanup_config_dto.CleanupConfigResponse,
) {
  section_managed.required(
    to_fields: cleanup_policy.from_response,
    load_http_failure: "Could not load cleanup config.",
    save_http_failure: "Could not save cleanup config.",
  )
}

pub fn ensure_loaded(model: Model) -> #(Model, admin_effect.Command(Msg)) {
  section_managed.ensure_loaded(model, fn(generation) {
    admin_effect.get_admin_cleanup_config(fn(response) {
      SectionEvent(section_managed.LoadCompleted(generation, response))
    })
  })
}

pub fn update(model: Model, msg: Msg) -> #(Model, admin_effect.Command(Msg)) {
  case msg {
    SectionEvent(event) ->
      section_managed.update(model, event, completion_policy())
    FieldChanged(field, value) -> #(
      section.edit(model, fn(fields) {
        cleanup_policy.set(fields, field, value)
      }),
      admin_effect.none(),
    )
    ResetClicked -> #(section.reset(model), admin_effect.none())
    SaveClicked ->
      section_managed.begin_validated_save(
        model,
        cleanup_policy.request(model.draft),
        fn(request, generation) {
          admin_effect.upsert_admin_cleanup_config(request, fn(response) {
            SectionEvent(section_managed.SaveCompleted(generation, response))
          })
        },
      )
  }
}

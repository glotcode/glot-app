import glot_core/admin/debug_config_dto
import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/config/section
import glot_frontend/admin/config/section_managed

pub type Fields {
  Fields(enabled: Bool)
}

pub type Model =
  section.FormModel(Fields)

pub type Msg {
  SectionEvent(section_managed.Event(debug_config_dto.DebugConfigResponse))
  ToggleClicked
  ResetClicked
  SaveClicked
}

pub fn init() -> Model {
  section.init(Fields(enabled: False))
}

fn completion_policy() -> section_managed.CompletionPolicy(
  Fields,
  debug_config_dto.DebugConfigResponse,
) {
  section_managed.required(
    to_fields: fields_from_response,
    load_http_failure: "Could not load debug config.",
    save_http_failure: "Could not save debug config.",
  )
}

pub fn ensure_loaded(model: Model) -> #(Model, admin_effect.Command(Msg)) {
  section_managed.ensure_loaded(model, fn(generation) {
    admin_effect.get_admin_debug_config(fn(response) {
      SectionEvent(section_managed.LoadCompleted(generation, response))
    })
  })
}

pub fn update(model: Model, msg: Msg) -> #(Model, admin_effect.Command(Msg)) {
  case msg {
    SectionEvent(event) ->
      section_managed.update(model, event, completion_policy())
    ToggleClicked -> #(
      section.edit(model, fn(fields) { Fields(enabled: !fields.enabled) }),
      admin_effect.none(),
    )
    ResetClicked -> #(section.reset(model), admin_effect.none())
    SaveClicked ->
      section_managed.begin_save(
        model,
        debug_config_dto.UpsertDebugConfigRequest(enabled: model.draft.enabled),
        fn(request, generation) {
          admin_effect.upsert_admin_debug_config(request, fn(response) {
            SectionEvent(section_managed.SaveCompleted(generation, response))
          })
        },
      )
  }
}

fn fields_from_response(
  response: debug_config_dto.DebugConfigResponse,
) -> Fields {
  Fields(enabled: response.enabled)
}

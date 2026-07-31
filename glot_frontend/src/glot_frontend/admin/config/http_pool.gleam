import glot_core/admin/http_pool_config_dto
import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/config/http_pool_policy
import glot_frontend/admin/config/section
import glot_frontend/admin/config/section_managed

pub type Model =
  section.FormModel(http_pool_policy.Fields)

pub type Msg {
  SectionEvent(
    section_managed.Event(http_pool_config_dto.HttpPoolConfigResponse),
  )
  FieldChanged(http_pool_policy.Field, String)
  ResetClicked
  SaveClicked
}

pub fn init() -> Model {
  section.init(http_pool_policy.initial())
}

fn completion_policy() -> section_managed.CompletionPolicy(
  http_pool_policy.Fields,
  http_pool_config_dto.HttpPoolConfigResponse,
) {
  section_managed.required(
    to_fields: http_pool_policy.from_response,
    load_http_failure: "Could not load HTTP pool config.",
    save_http_failure: "Could not save HTTP pool config.",
  )
}

pub fn ensure_loaded(model: Model) -> #(Model, admin_effect.Command(Msg)) {
  section_managed.ensure_loaded(model, fn(generation) {
    admin_effect.get_admin_http_pool_config(fn(response) {
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
        http_pool_policy.set(fields, field, value)
      }),
      admin_effect.none(),
    )
    ResetClicked -> #(section.reset(model), admin_effect.none())
    SaveClicked ->
      section_managed.begin_validated_save(
        model,
        http_pool_policy.request(model.draft),
        fn(request, generation) {
          admin_effect.upsert_admin_http_pool_config(request, fn(response) {
            SectionEvent(section_managed.SaveCompleted(generation, response))
          })
        },
      )
  }
}

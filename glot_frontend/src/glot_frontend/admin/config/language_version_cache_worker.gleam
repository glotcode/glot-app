import glot_core/admin/language_version_cache_worker_config_dto
import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/config/language_version_cache_worker_policy as config_policy
import glot_frontend/admin/config/section
import glot_frontend/admin/config/section_managed

pub type Model =
  section.FormModel(config_policy.Fields)

pub type Msg {
  SectionEvent(
    section_managed.Event(
      language_version_cache_worker_config_dto.LanguageVersionCacheWorkerConfigResponse,
    ),
  )
  FieldChanged(config_policy.Field, String)
  ResetClicked
  SaveClicked
}

pub fn init() -> Model {
  section.init(config_policy.initial())
}

fn completion_policy() -> section_managed.CompletionPolicy(
  config_policy.Fields,
  language_version_cache_worker_config_dto.LanguageVersionCacheWorkerConfigResponse,
) {
  section_managed.required(
    to_fields: config_policy.from_response,
    load_http_failure: "Could not load language version cache worker config.",
    save_http_failure: "Could not save language version cache worker config.",
  )
}

pub fn ensure_loaded(model: Model) -> #(Model, admin_effect.Command(Msg)) {
  section_managed.ensure_loaded(model, fn(generation) {
    admin_effect.get_admin_language_version_cache_worker_config(fn(response) {
      SectionEvent(section_managed.LoadCompleted(generation, response))
    })
  })
}

pub fn update(model: Model, msg: Msg) -> #(Model, admin_effect.Command(Msg)) {
  case msg {
    SectionEvent(event) ->
      section_managed.update(model, event, completion_policy())
    FieldChanged(field, value) -> #(
      section.edit(model, fn(fields) { config_policy.set(fields, field, value) }),
      admin_effect.none(),
    )
    ResetClicked -> #(section.reset(model), admin_effect.none())
    SaveClicked ->
      section_managed.begin_validated_save(
        model,
        config_policy.request(model.draft),
        fn(request, generation) {
          admin_effect.upsert_admin_language_version_cache_worker_config(
            request,
            fn(response) {
              SectionEvent(section_managed.SaveCompleted(generation, response))
            },
          )
        },
      )
  }
}

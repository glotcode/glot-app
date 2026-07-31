import glot_core/admin/email_config_dto
import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/config/email_policy
import glot_frontend/admin/config/section
import glot_frontend/admin/config/section_managed

pub type Model =
  section.FormModel(email_policy.Fields)

pub type Msg {
  SectionEvent(section_managed.Event(email_config_dto.EmailConfigResponse))
  FieldChanged(email_policy.Field, String)
  ResetClicked
  SaveClicked
}

pub fn init() -> Model {
  section.init(email_policy.empty())
}

fn completion_policy() -> section_managed.CompletionPolicy(
  email_policy.Fields,
  email_config_dto.EmailConfigResponse,
) {
  section_managed.optional(
    to_fields: email_policy.from_response,
    missing: section_managed.MissingConfig(
      code: "email_config_not_found",
      fields: email_policy.empty(),
    ),
    load_http_failure: "Could not load email config.",
    save_http_failure: "Could not save email config.",
  )
}

pub fn ensure_loaded(model: Model) -> #(Model, admin_effect.Command(Msg)) {
  section_managed.ensure_loaded(model, fn(generation) {
    admin_effect.get_admin_email_config(fn(response) {
      SectionEvent(section_managed.LoadCompleted(generation, response))
    })
  })
}

pub fn update(model: Model, msg: Msg) -> #(Model, admin_effect.Command(Msg)) {
  case msg {
    SectionEvent(event) ->
      section_managed.update(model, event, completion_policy())
    FieldChanged(field, value) -> #(
      section.edit(model, fn(fields) { email_policy.set(fields, field, value) }),
      admin_effect.none(),
    )
    ResetClicked -> #(section.reset(model), admin_effect.none())
    SaveClicked ->
      section_managed.begin_validated_save(
        model,
        email_policy.request(model.draft),
        fn(request, generation) {
          admin_effect.upsert_admin_email_config(request, fn(response) {
            SectionEvent(section_managed.SaveCompleted(generation, response))
          })
        },
      )
  }
}

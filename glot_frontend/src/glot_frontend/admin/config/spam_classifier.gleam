import glot_core/admin/spam_classifier_config_dto
import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/config/section
import glot_frontend/admin/config/section_managed
import glot_frontend/admin/config/spam_classifier_policy

pub type Model =
  section.FormModel(spam_classifier_policy.Fields)

pub type Msg {
  SectionEvent(
    section_managed.Event(
      spam_classifier_config_dto.SpamClassifierConfigResponse,
    ),
  )
  FieldChanged(spam_classifier_policy.Field, String)
  ResetClicked
  SaveClicked
}

pub fn init() -> Model {
  section.init(spam_classifier_policy.empty())
}

fn completion_policy() -> section_managed.CompletionPolicy(
  spam_classifier_policy.Fields,
  spam_classifier_config_dto.SpamClassifierConfigResponse,
) {
  section_managed.optional(
    to_fields: spam_classifier_policy.from_response,
    missing: section_managed.MissingConfig(
      code: "spam_classifier_config_not_found",
      fields: spam_classifier_policy.empty(),
    ),
    load_http_failure: "Could not load spam classifier config.",
    save_http_failure: "Could not save spam classifier config.",
  )
}

pub fn ensure_loaded(model: Model) -> #(Model, admin_effect.Command(Msg)) {
  section_managed.ensure_loaded(model, fn(generation) {
    admin_effect.get_admin_spam_classifier_config(fn(response) {
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
        spam_classifier_policy.set(fields, field, value)
      }),
      admin_effect.none(),
    )
    ResetClicked -> #(section.reset(model), admin_effect.none())
    SaveClicked ->
      section_managed.begin_validated_save(
        model,
        spam_classifier_policy.request(model.draft),
        fn(request, generation) {
          admin_effect.upsert_admin_spam_classifier_config(
            request,
            fn(response) {
              SectionEvent(section_managed.SaveCompleted(generation, response))
            },
          )
        },
      )
  }
}

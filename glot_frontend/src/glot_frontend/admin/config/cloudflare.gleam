import glot_core/admin/cloudflare_config_dto
import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/config/cloudflare_policy
import glot_frontend/admin/config/section
import glot_frontend/admin/config/section_managed

pub type Model =
  section.FormModel(cloudflare_policy.Fields)

pub type Msg {
  SectionEvent(
    section_managed.Event(cloudflare_config_dto.CloudflareConfigResponse),
  )
  FieldChanged(cloudflare_policy.Field, String)
  ResetClicked
  SaveClicked
}

pub fn init() -> Model {
  section.init(cloudflare_policy.empty())
}

fn completion_policy() -> section_managed.CompletionPolicy(
  cloudflare_policy.Fields,
  cloudflare_config_dto.CloudflareConfigResponse,
) {
  section_managed.optional(
    to_fields: cloudflare_policy.from_response,
    missing: section_managed.MissingConfig(
      code: "cloudflare_config_not_found",
      fields: cloudflare_policy.empty(),
    ),
    load_http_failure: "Could not load Cloudflare config.",
    save_http_failure: "Could not save Cloudflare config.",
  )
}

pub fn ensure_loaded(model: Model) -> #(Model, admin_effect.Command(Msg)) {
  section_managed.ensure_loaded(model, fn(generation) {
    admin_effect.get_admin_cloudflare_config(fn(response) {
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
        cloudflare_policy.set(fields, field, value)
      }),
      admin_effect.none(),
    )
    ResetClicked -> #(section.reset(model), admin_effect.none())
    SaveClicked ->
      section_managed.begin_validated_save(
        model,
        cloudflare_policy.request(model.draft),
        fn(request, generation) {
          admin_effect.upsert_admin_cloudflare_config(request, fn(response) {
            SectionEvent(section_managed.SaveCompleted(generation, response))
          })
        },
      )
  }
}

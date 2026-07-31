import glot_core/admin/passkey_config_dto
import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/config/passkey_policy
import glot_frontend/admin/config/section
import glot_frontend/admin/config/section_managed

pub type Model =
  section.FormModel(passkey_policy.Fields)

pub type Msg {
  SectionEvent(section_managed.Event(passkey_config_dto.PasskeyConfigResponse))
  OriginChanged(String)
  RpIdChanged(String)
  ChallengeTimeoutSecondsChanged(String)
  ResetClicked
  SaveClicked
}

pub fn init() -> Model {
  section.init(passkey_policy.initial())
}

fn completion_policy() -> section_managed.CompletionPolicy(
  passkey_policy.Fields,
  passkey_config_dto.PasskeyConfigResponse,
) {
  section_managed.required(
    to_fields: passkey_policy.from_response,
    load_http_failure: "Could not load passkey config.",
    save_http_failure: "Could not save passkey config.",
  )
}

pub fn ensure_loaded(model: Model) -> #(Model, admin_effect.Command(Msg)) {
  section_managed.ensure_loaded(model, fn(generation) {
    admin_effect.get_admin_passkey_config(fn(response) {
      SectionEvent(section_managed.LoadCompleted(generation, response))
    })
  })
}

pub fn update(model: Model, msg: Msg) -> #(Model, admin_effect.Command(Msg)) {
  case msg {
    SectionEvent(event) ->
      section_managed.update(model, event, completion_policy())
    OriginChanged(origin) -> #(
      section.edit(model, fn(fields) {
        passkey_policy.set_origin(fields, origin)
      }),
      admin_effect.none(),
    )
    RpIdChanged(rp_id) -> #(
      section.edit(model, fn(fields) { passkey_policy.set_rp_id(fields, rp_id) }),
      admin_effect.none(),
    )
    ChallengeTimeoutSecondsChanged(challenge_timeout_seconds) -> #(
      section.edit(model, fn(fields) {
        passkey_policy.set_challenge_timeout(fields, challenge_timeout_seconds)
      }),
      admin_effect.none(),
    )
    ResetClicked -> #(section.reset(model), admin_effect.none())
    SaveClicked ->
      section_managed.begin_validated_save(
        model,
        passkey_policy.request(model.draft),
        fn(request, generation) {
          admin_effect.upsert_admin_passkey_config(request, fn(response) {
            SectionEvent(section_managed.SaveCompleted(generation, response))
          })
        },
      )
  }
}

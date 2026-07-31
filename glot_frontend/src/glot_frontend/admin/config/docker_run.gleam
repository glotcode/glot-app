import glot_core/admin/docker_run_config_dto
import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/config/docker_run_policy
import glot_frontend/admin/config/section
import glot_frontend/admin/config/section_managed

pub type Model =
  section.FormModel(docker_run_policy.Fields)

pub type Msg {
  SectionEvent(
    section_managed.Event(docker_run_config_dto.DockerRunConfigResponse),
  )
  FieldChanged(docker_run_policy.Field, String)
  ResetClicked
  SaveClicked
}

pub fn init() -> Model {
  section.init(docker_run_policy.empty())
}

fn completion_policy() -> section_managed.CompletionPolicy(
  docker_run_policy.Fields,
  docker_run_config_dto.DockerRunConfigResponse,
) {
  section_managed.optional(
    to_fields: docker_run_policy.from_response,
    missing: section_managed.MissingConfig(
      code: "docker_run_config_not_found",
      fields: docker_run_policy.empty(),
    ),
    load_http_failure: "Could not load docker run config.",
    save_http_failure: "Could not save docker run config.",
  )
}

pub fn ensure_loaded(model: Model) -> #(Model, admin_effect.Command(Msg)) {
  section_managed.ensure_loaded(model, fn(generation) {
    admin_effect.get_admin_docker_run_config(fn(response) {
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
        docker_run_policy.set(fields, field, value)
      }),
      admin_effect.none(),
    )
    ResetClicked -> #(section.reset(model), admin_effect.none())
    SaveClicked ->
      section_managed.begin_validated_save(
        model,
        docker_run_policy.request(model.draft),
        fn(request, generation) {
          admin_effect.upsert_admin_docker_run_config(request, fn(response) {
            SectionEvent(section_managed.SaveCompleted(generation, response))
          })
        },
      )
  }
}

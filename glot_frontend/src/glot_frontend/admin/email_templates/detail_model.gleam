import glot_core/admin/email_template_dto
import glot_core/loadable
import glot_frontend/request_generation.{type Generation}
import glot_frontend/ui/mutation

pub type Model {
  Model(
    name: String,
    template: loadable.Loadable(email_template_dto.EmailTemplateDetailResponse),
    draft: Draft,
    save_state: mutation.MutationState,
    save_generation: Generation(request_generation.Shared),
  )
}

pub type Draft {
  Draft(
    subject_template: String,
    text_body_template: String,
    html_body_template: String,
  )
}

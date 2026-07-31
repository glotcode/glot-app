import gleam/option
import gleam/string
import glot_core/admin/email_template_dto
import glot_core/loadable
import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/email_templates/detail_message.{
  HtmlBodyChanged, ResetClicked, SaveClicked, SaveFinished, SubjectChanged,
  TemplateLoaded, TextBodyChanged,
}
import glot_frontend/admin/email_templates/detail_model.{
  type Draft, Draft, Model,
}
import glot_frontend/admin/ui/loadable as loadable_effect
import glot_frontend/api/response as api_response
import glot_frontend/request_generation
import glot_frontend/ui/mutation

pub type Model =
  detail_model.Model

pub type Msg =
  detail_message.Msg

pub fn init(name: String) -> #(Model, admin_effect.Command(Msg)) {
  #(
    Model(
      name: name,
      template: loadable.NotLoaded,
      draft: empty_draft(),
      save_state: mutation.Idle,
      save_generation: request_generation.initial(),
    ),
    admin_effect.none(),
  )
}

pub fn ensure_loaded(model: Model) -> #(Model, admin_effect.Command(Msg)) {
  case
    loadable_effect.ensure_loaded(
      model.template,
      admin_effect.get_admin_email_template(
        email_template_dto.GetEmailTemplateRequest(name: model.name),
        TemplateLoaded,
      ),
    )
  {
    #(template, next_effect) -> #(
      Model(..model, template: template),
      next_effect,
    )
  }
}

pub fn update(model: Model, msg: Msg) -> #(Model, admin_effect.Command(Msg)) {
  case msg {
    TemplateLoaded(result) ->
      case result {
        api_response.Success(response) -> {
          let template = response.template
          #(
            Model(
              ..model,
              template: loadable.Loaded(template),
              draft: draft_from_template(template),
              save_state: mutation.Idle,
            ),
            admin_effect.none(),
          )
        }
        api_response.ApiFailure(error) -> #(
          Model(
            ..model,
            template: loadable.LoadError(api_response.error_message(error)),
          ),
          admin_effect.none(),
        )
        api_response.HttpFailure(_) -> #(
          Model(
            ..model,
            template: loadable.LoadError("Could not load email template."),
          ),
          admin_effect.none(),
        )
      }

    SubjectChanged(value) -> #(
      Model(
        ..model,
        draft: Draft(..model.draft, subject_template: value),
        save_state: mutation.clear_feedback(model.save_state),
        save_generation: request_generation.next(model.save_generation),
      ),
      admin_effect.none(),
    )

    TextBodyChanged(value) -> #(
      Model(
        ..model,
        draft: Draft(..model.draft, text_body_template: value),
        save_state: mutation.clear_feedback(model.save_state),
        save_generation: request_generation.next(model.save_generation),
      ),
      admin_effect.none(),
    )

    HtmlBodyChanged(value) -> #(
      Model(
        ..model,
        draft: Draft(..model.draft, html_body_template: value),
        save_state: mutation.clear_feedback(model.save_state),
        save_generation: request_generation.next(model.save_generation),
      ),
      admin_effect.none(),
    )

    ResetClicked ->
      case model.template {
        loadable.Loaded(template) -> #(
          Model(
            ..model,
            draft: draft_from_template(template),
            save_state: mutation.Idle,
            save_generation: request_generation.next(model.save_generation),
          ),
          admin_effect.none(),
        )
        _ -> #(model, admin_effect.none())
      }

    SaveClicked ->
      case request_from_draft(model) {
        Error(message) -> #(
          Model(..model, save_state: mutation.SaveError(message)),
          admin_effect.none(),
        )
        Ok(request) -> #(
          Model(
            ..model,
            save_state: mutation.Saving,
            save_generation: request_generation.next(model.save_generation),
          ),
          admin_effect.update_admin_email_template(request, fn(result) {
            SaveFinished(request_generation.next(model.save_generation), result)
          }),
        )
      }

    SaveFinished(generation, _) if generation != model.save_generation -> #(
      model,
      admin_effect.none(),
    )
    SaveFinished(_, result) ->
      case result {
        api_response.Success(response) -> {
          let template = response.template
          #(
            Model(
              ..model,
              template: loadable.Loaded(template),
              draft: draft_from_template(template),
              save_state: mutation.Saved,
            ),
            admin_effect.none(),
          )
        }
        api_response.ApiFailure(error) -> #(
          Model(
            ..model,
            save_state: mutation.SaveError(api_response.error_message(error)),
          ),
          admin_effect.none(),
        )
        api_response.HttpFailure(_) -> #(
          Model(
            ..model,
            save_state: mutation.SaveError("Could not save email template."),
          ),
          admin_effect.none(),
        )
      }
  }
}

fn draft_from_template(
  template: email_template_dto.EmailTemplateDetailResponse,
) -> Draft {
  Draft(
    subject_template: template.subject_template,
    text_body_template: template.text_body_template,
    html_body_template: option.unwrap(template.html_body_template, ""),
  )
}

fn request_from_draft(
  model: Model,
) -> Result(email_template_dto.UpdateEmailTemplateRequest, String) {
  case string.trim(model.draft.subject_template) == "" {
    True -> Error("Subject template cannot be empty.")
    False ->
      case string.trim(model.draft.text_body_template) == "" {
        True -> Error("Text body template cannot be empty.")
        False ->
          Ok(email_template_dto.UpdateEmailTemplateRequest(
            name: model.name,
            subject_template: model.draft.subject_template,
            text_body_template: model.draft.text_body_template,
            html_body_template: normalize_html(model.draft.html_body_template),
          ))
      }
  }
}

fn normalize_html(value: String) -> option.Option(String) {
  case string.trim(value) == "" {
    True -> option.None
    False -> option.Some(value)
  }
}

fn empty_draft() -> Draft {
  Draft(subject_template: "", text_body_template: "", html_body_template: "")
}

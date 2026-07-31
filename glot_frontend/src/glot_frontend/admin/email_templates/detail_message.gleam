import glot_core/admin/email_template_dto
import glot_frontend/api/response as api_response
import glot_frontend/request_generation.{type Generation}

pub type Msg {
  TemplateLoaded(
    api_response.Response(email_template_dto.GetEmailTemplateResponse),
  )
  SubjectChanged(String)
  TextBodyChanged(String)
  HtmlBodyChanged(String)
  ResetClicked
  SaveClicked
  SaveFinished(
    Generation(request_generation.Shared),
    api_response.Response(email_template_dto.UpdateEmailTemplateResponse),
  )
}

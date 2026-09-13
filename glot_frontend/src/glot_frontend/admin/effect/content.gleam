import glot_core/admin/email_template_dto
import glot_core/admin/snippet_dto as admin_snippet_dto
import glot_core/admin/spam_review_dto
import glot_core/pagination_model
import glot_core/snippet/manual_review
import glot_core/snippet/snippet_dto
import glot_frontend/api/response

pub type Command(msg) {
  GetSpamReview(
    spam_review_dto.ListRequest,
    fn(
      response.Response(
        pagination_model.CursorPage(spam_review_dto.ReviewSnippet),
      ),
    ) -> msg,
  )
  SaveManualReview(
    spam_review_dto.SaveRequest,
    fn(response.Response(manual_review.ManualReview)) -> msg,
  )

  GetEmailTemplates(
    fn(response.Response(email_template_dto.ListEmailTemplatesResponse)) -> msg,
  )
  GetEmailTemplate(
    email_template_dto.GetEmailTemplateRequest,
    fn(response.Response(email_template_dto.GetEmailTemplateResponse)) -> msg,
  )
  UpdateEmailTemplate(
    email_template_dto.UpdateEmailTemplateRequest,
    fn(response.Response(email_template_dto.UpdateEmailTemplateResponse)) -> msg,
  )
  GetSnippets(
    admin_snippet_dto.ListSnippetsRequest,
    fn(response.Response(admin_snippet_dto.ListSnippetsResponse)) -> msg,
  )
  GetSnippet(
    admin_snippet_dto.GetSnippetRequest,
    fn(response.Response(admin_snippet_dto.GetSnippetResponse)) -> msg,
  )
  ClassifySnippet(
    admin_snippet_dto.GetSnippetRequest,
    fn(response.Response(admin_snippet_dto.GetSnippetResponse)) -> msg,
  )
  DeleteSnippet(
    snippet_dto.DeleteSnippetRequest,
    fn(response.Response(Nil)) -> msg,
  )
}

pub fn map(command: Command(a), transform: fn(a) -> b) -> Command(b) {
  case command {
    GetSpamReview(request, complete) ->
      GetSpamReview(request, fn(result) { transform(complete(result)) })
    SaveManualReview(request, complete) ->
      SaveManualReview(request, fn(result) { transform(complete(result)) })

    GetEmailTemplates(complete) ->
      GetEmailTemplates(fn(result) { transform(complete(result)) })
    GetEmailTemplate(request, complete) ->
      GetEmailTemplate(request, fn(result) { transform(complete(result)) })
    UpdateEmailTemplate(request, complete) ->
      UpdateEmailTemplate(request, fn(result) { transform(complete(result)) })
    GetSnippets(request, complete) ->
      GetSnippets(request, fn(result) { transform(complete(result)) })
    GetSnippet(request, complete) ->
      GetSnippet(request, fn(result) { transform(complete(result)) })
    ClassifySnippet(request, complete) ->
      ClassifySnippet(request, fn(result) { transform(complete(result)) })
    DeleteSnippet(request, complete) ->
      DeleteSnippet(request, fn(result) { transform(complete(result)) })
  }
}

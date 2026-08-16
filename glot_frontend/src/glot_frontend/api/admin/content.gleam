import gleam/json
import glot_core/admin/email_template_dto
import glot_core/admin/snippet_dto as admin_snippet_dto
import glot_core/admin_action
import glot_core/snippet/snippet_dto
import glot_frontend/api/client
import glot_frontend/api/request
import glot_frontend/api/response
import lustre/effect

pub fn get_admin_email_templates(
  to_msg: fn(response.Response(email_template_dto.ListEmailTemplatesResponse)) ->
    msg,
) -> effect.Effect(msg) {
  let req = request.AdminRequest(admin_action.GetAdminEmailTemplatesAction, Nil)

  request.send_admin(
    req,
    fn(_) { json.null() },
    email_template_dto.list_response_decoder(),
    to_msg,
  )
}

pub fn get_admin_email_template(
  request: email_template_dto.GetEmailTemplateRequest,
  to_msg: fn(response.Response(email_template_dto.GetEmailTemplateResponse)) ->
    msg,
) -> effect.Effect(msg) {
  let req =
    request.AdminRequest(admin_action.GetAdminEmailTemplateAction, request)

  request.send_admin(
    req,
    email_template_dto.encode_get_request,
    email_template_dto.get_response_decoder(),
    to_msg,
  )
}

pub fn update_admin_email_template(
  request: email_template_dto.UpdateEmailTemplateRequest,
  to_msg: fn(response.Response(email_template_dto.UpdateEmailTemplateResponse)) ->
    msg,
) -> effect.Effect(msg) {
  let req =
    request.AdminRequest(admin_action.UpdateAdminEmailTemplateAction, request)

  request.send_admin(
    req,
    email_template_dto.encode_update_request,
    email_template_dto.update_response_decoder(),
    to_msg,
  )
}

pub fn get_admin_snippets(
  request: admin_snippet_dto.ListSnippetsRequest,
  to_msg: fn(response.Response(admin_snippet_dto.ListSnippetsResponse)) -> msg,
) -> effect.Effect(msg) {
  let req = request.AdminRequest(admin_action.GetAdminSnippetsAction, request)

  request.send_admin(
    req,
    admin_snippet_dto.encode_list_request,
    admin_snippet_dto.list_response_decoder(),
    to_msg,
  )
}

pub fn get_admin_snippet(
  request: admin_snippet_dto.GetSnippetRequest,
  to_msg: fn(response.Response(admin_snippet_dto.GetSnippetResponse)) -> msg,
) -> effect.Effect(msg) {
  let req = request.AdminRequest(admin_action.GetAdminSnippetAction, request)

  request.send_admin(
    req,
    admin_snippet_dto.encode_get_request,
    admin_snippet_dto.get_response_decoder(),
    to_msg,
  )
}

pub fn classify_admin_snippet(
  request: admin_snippet_dto.GetSnippetRequest,
  to_msg: fn(response.Response(admin_snippet_dto.GetSnippetResponse)) -> msg,
) -> effect.Effect(msg) {
  let req =
    request.AdminRequest(admin_action.ClassifyAdminSnippetAction, request)

  request.send_admin(
    req,
    admin_snippet_dto.encode_get_request,
    admin_snippet_dto.get_response_decoder(),
    to_msg,
  )
}

pub fn delete_admin_snippet(
  request: snippet_dto.DeleteSnippetRequest,
  to_msg: fn(response.Response(Nil)) -> msg,
) -> effect.Effect(msg) {
  let req = request.AdminRequest(admin_action.DeleteAdminSnippetAction, request)

  request.send_admin(
    req,
    fn(delete_request) {
      json.object([
        #("slug", json.string(delete_request.slug)),
      ])
    },
    client.nil_decoder(),
    to_msg,
  )
}

import gleam/dynamic.{type Dynamic}
import gleam/option
import gleam/result
import glot_backend/auth/domain/session/current as current_session
import glot_backend/email/effect/template/effect as email_template_effect
import glot_backend/email/model/template.{type EmailTemplate} as email_template
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/system/effect/error
import glot_backend/system/effect/error/resource_error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/admin/email_template_dto.{
  type EmailTemplateDetailResponse, type GetEmailTemplateRequest,
  type GetEmailTemplateResponse,
}
import glot_core/admin_action
import glot_core/api_action

pub fn get_email_template(
  request_ctx: RequestContext,
  request: GetEmailTemplateRequest,
) -> Program(GetEmailTemplateResponse) {
  use session <- program.and_then(current_session.require_session(request_ctx))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.admin(admin_action.GetAdminEmailTemplateAction),
    actor: api_action_policy.actor_from_user(option.Some(session.user)),
  ))
  use name <- program.and_then(
    email_template.from_db_name(request.name)
    |> result.map_error(error.validation)
    |> program.from_result,
  )
  use template <- program.and_then(
    email_template_effect.get_email_template_by_name(name)
    |> program.require(error.resource(resource_error.EmailTemplateNotFound)),
  )
  use _ <- program.and_then(user_action_effect.create_user_action(user_action))

  program.succeed(
    email_template_dto.GetEmailTemplateResponse(template: to_detail_response(
      template,
    )),
  )
}

pub fn request_from_dynamic(data: Dynamic) -> Program(GetEmailTemplateRequest) {
  program.decode_dynamic(data, email_template_dto.get_request_decoder())
}

fn to_detail_response(template: EmailTemplate) -> EmailTemplateDetailResponse {
  email_template_dto.EmailTemplateDetailResponse(
    name: email_template.to_db_name(template.name),
    subject_template: template.subject_template,
    text_body_template: template.text_body_template,
    html_body_template: template.html_body_template,
    supported_tokens: email_template.supported_tokens(template.name),
    updated_at: template.updated_at,
  )
}

import gleam/list
import gleam/option
import glot_backend/auth/domain/session/current as current_session
import glot_backend/email/effect/template/effect as email_template_effect
import glot_backend/email/model/template.{type EmailTemplate} as email_template
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/admin/email_template_dto.{
  type EmailTemplateSummaryResponse, type ListEmailTemplatesResponse,
}
import glot_core/admin_action
import glot_core/api_action

pub fn get_email_templates(
  request_ctx: RequestContext,
) -> Program(ListEmailTemplatesResponse) {
  use session <- program.and_then(current_session.require_session(request_ctx))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.admin(admin_action.GetAdminEmailTemplatesAction),
    actor: api_action_policy.actor_from_user(option.Some(session.user)),
  ))
  use templates <- program.and_then(
    email_template_effect.list_email_templates(),
  )
  use _ <- program.and_then(user_action_effect.create_user_action(user_action))

  program.succeed(email_template_dto.ListEmailTemplatesResponse(
    templates: templates |> list.map(to_summary_response),
  ))
}

fn to_summary_response(
  template: EmailTemplate,
) -> EmailTemplateSummaryResponse {
  email_template_dto.EmailTemplateSummaryResponse(
    name: email_template.to_db_name(template.name),
    subject_template: template.subject_template,
    supported_tokens: email_template.supported_tokens(template.name),
    has_html_body: option.is_some(template.html_body_template),
    updated_at: template.updated_at,
  )
}

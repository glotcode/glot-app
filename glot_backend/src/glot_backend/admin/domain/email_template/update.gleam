import gleam/dynamic.{type Dynamic}
import gleam/option.{type Option}
import gleam/result
import gleam/string
import glot_backend/auth/domain/session/current as current_session
import glot_backend/email/effect/template/effect as email_template_effect
import glot_backend/email/model/template as email_template
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/system/effect/error
import glot_backend/system/effect/error/resource_error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/admin/email_template_dto.{
  type UpdateEmailTemplateRequest, type UpdateEmailTemplateResponse,
}
import glot_core/admin_action
import glot_core/api_action

pub fn update_email_template(
  request_ctx: RequestContext,
  request: UpdateEmailTemplateRequest,
) -> Program(UpdateEmailTemplateResponse) {
  let ctx = request_ctx.context

  use session <- program.and_then(current_session.require_session(request_ctx))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.admin(admin_action.UpdateAdminEmailTemplateAction),
    actor: api_action_policy.actor_from_user(option.Some(session.user)),
  ))
  use name <- program.and_then(
    email_template.from_db_name(request.name)
    |> result.map_error(error.validation)
    |> program.from_result,
  )
  use existing <- program.and_then(
    email_template_effect.get_email_template_by_name(name)
    |> program.require(error.resource(resource_error.EmailTemplateNotFound)),
  )

  let updated_template =
    email_template.EmailTemplate(
      ..existing,
      subject_template: request.subject_template,
      text_body_template: request.text_body_template,
      html_body_template: normalize_html_body_template(
        request.html_body_template,
      ),
      updated_at: ctx.timestamp,
    )

  use _ <- program.and_then(
    email_template.validate_template(updated_template)
    |> result.map_error(error.validation)
    |> program.from_result,
  )
  use _ <- program.and_then(email_template_effect.update_email_template(
    updated_template,
  ))
  use _ <- program.and_then(user_action_effect.create_user_action(user_action))

  program.succeed(
    email_template_dto.UpdateEmailTemplateResponse(
      template: email_template_dto.EmailTemplateDetailResponse(
        name: email_template.to_db_name(updated_template.name),
        subject_template: updated_template.subject_template,
        text_body_template: updated_template.text_body_template,
        html_body_template: updated_template.html_body_template,
        supported_tokens: email_template.supported_tokens(updated_template.name),
        updated_at: updated_template.updated_at,
      ),
    ),
  )
}

pub fn request_from_dynamic(
  data: Dynamic,
) -> Program(UpdateEmailTemplateRequest) {
  program.decode_dynamic(data, email_template_dto.update_request_decoder())
}

fn normalize_html_body_template(value: Option(String)) -> Option(String) {
  case value {
    option.Some(html) ->
      case string.trim(html) == "" {
        True -> option.None
        False -> option.Some(html)
      }
    option.None -> option.None
  }
}

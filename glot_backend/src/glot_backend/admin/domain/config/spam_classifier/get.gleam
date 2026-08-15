import gleam/option
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/auth/domain/session/current as current_session
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/system/effect/error
import glot_backend/system/effect/error/resource_error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/admin/spam_classifier_config_dto
import glot_core/admin_action
import glot_core/api_action

pub fn get_spam_classifier_config(
  request_ctx: RequestContext,
) -> Program(spam_classifier_config_dto.SpamClassifierConfigResponse) {
  use session <- program.and_then(current_session.require_session(request_ctx))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.admin(admin_action.GetAdminSpamClassifierConfigAction),
    actor: api_action_policy.actor_from_user(option.Some(session.user)),
  ))
  use config <- program.and_then(program.from_option(
    dynamic_config.spam_classifier_config(request_ctx.dynamic_config),
    error.resource(resource_error.SpamClassifierConfigNotFound),
  ))
  use _ <- program.and_then(user_action_effect.create_user_action(user_action))
  program.succeed(spam_classifier_config_dto.SpamClassifierConfigResponse(
    base_url: config.base_url,
    auth_token: config.auth_token,
  ))
}

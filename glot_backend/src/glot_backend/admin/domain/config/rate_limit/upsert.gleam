import gleam/dynamic.{type Dynamic}
import gleam/list
import gleam/option
import glot_backend/app_config/effect/effect as app_config_effect
import glot_backend/auth/domain/session/current as current_session
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/request_policy/model/config.{
  type RateLimitMatch, type RateLimitPolicy,
} as request_policy_config
import glot_backend/system/effect/error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/admin/rate_limit_config_dto.{
  type RateLimitPolicyResponse, type RateLimitRule, type RuleMatch,
  type UpsertRateLimitPolicyRequest,
}
import glot_core/admin_action
import glot_core/api_action
import glot_core/validation_error

pub fn upsert_rate_limit_policy(
  request_ctx: RequestContext,
  request: UpsertRateLimitPolicyRequest,
) -> Program(RateLimitPolicyResponse) {
  let ctx = request_ctx.context

  use session <- program.and_then(current_session.require_session(request_ctx))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.admin(admin_action.UpsertAdminRateLimitPolicyAction),
    actor: api_action_policy.actor_from_user(option.Some(session.user)),
  ))
  use _ <- program.and_then(validate_request(request))
  use _ <- program.and_then(app_config_effect.upsert_rate_limit_policy(
    request.action,
    policy_from_request(request),
    ctx.timestamp,
  ))
  use _ <- program.and_then(user_action_effect.create_user_action(user_action))

  program.succeed(rate_limit_config_dto.RateLimitPolicyResponse(
    action: request.action,
    rules: request.rules,
  ))
}

pub fn request_from_dynamic(
  data: Dynamic,
) -> Program(UpsertRateLimitPolicyRequest) {
  program.decode_dynamic(data, rate_limit_config_dto.decoder())
}

fn validate_request(request: UpsertRateLimitPolicyRequest) -> Program(Nil) {
  case list.is_empty(request.rules) {
    True -> program.fail(error.validation(validation_error.RulesMissing))
    False -> program.succeed(Nil)
  }
}

fn policy_from_request(
  request: UpsertRateLimitPolicyRequest,
) -> RateLimitPolicy {
  request_policy_config.RateLimitPolicy(rules: list.map(
    request.rules,
    policy_rule_from_dto_rule,
  ))
}

fn policy_rule_from_dto_rule(
  rule: RateLimitRule,
) -> request_policy_config.RateLimitRule {
  request_policy_config.RateLimitRule(
    match: policy_match_from_dto_match(rule.match),
    limits: rule.limits,
  )
}

fn policy_match_from_dto_match(rule_match: RuleMatch) -> RateLimitMatch {
  case rule_match {
    rate_limit_config_dto.AnonymousMatch -> request_policy_config.AnonymousMatch
    rate_limit_config_dto.AuthenticatedMatch(account_tiers: account_tiers) ->
      case list.is_empty(account_tiers) {
        True ->
          request_policy_config.AuthenticatedMatch(account_tiers: option.None)
        False ->
          request_policy_config.AuthenticatedMatch(account_tiers: option.Some(
            account_tiers,
          ))
      }
  }
}

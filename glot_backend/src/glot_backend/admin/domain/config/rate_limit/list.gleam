import gleam/list
import gleam/option
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/auth/domain/session/current as current_session
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/request_policy/model/config.{
  type RateLimitMatch, type RateLimitPolicy,
} as request_policy_config
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/admin/rate_limit_config_dto.{
  type RateLimitPoliciesResponse, type RateLimitPolicyResponse,
  type RateLimitRule, type RuleMatch,
}
import glot_core/admin_action
import glot_core/api_action
import glot_core/public_action.{type PublicAction}

pub fn get_rate_limit_policies(
  request_ctx: RequestContext,
) -> Program(RateLimitPoliciesResponse) {
  let config = request_ctx.dynamic_config

  use session <- program.and_then(current_session.require_session(request_ctx))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.admin(admin_action.GetAdminRateLimitPoliciesAction),
    actor: api_action_policy.actor_from_user(option.Some(session.user)),
  ))
  use _ <- program.and_then(user_action_effect.create_user_action(user_action))

  let policies =
    dynamic_config.list_rate_limit_policies(config)
    |> list.map(fn(pair) {
      let #(action, policy) = pair
      rate_limit_policy_response(action, policy)
    })

  program.succeed(rate_limit_config_dto.RateLimitPoliciesResponse(
    policies: policies,
  ))
}

fn rate_limit_policy_response(
  action: PublicAction,
  policy: RateLimitPolicy,
) -> RateLimitPolicyResponse {
  rate_limit_config_dto.RateLimitPolicyResponse(
    action: action,
    rules: list.map(policy.rules, dto_rule_from_policy_rule),
  )
}

fn dto_rule_from_policy_rule(
  rule: request_policy_config.RateLimitRule,
) -> RateLimitRule {
  rate_limit_config_dto.RateLimitRule(
    match: dto_match_from_policy_match(rule.match),
    limits: rule.limits,
  )
}

fn dto_match_from_policy_match(rule_match: RateLimitMatch) -> RuleMatch {
  case rule_match {
    request_policy_config.AnonymousMatch -> rate_limit_config_dto.AnonymousMatch
    request_policy_config.AuthenticatedMatch(account_tiers: account_tiers) ->
      rate_limit_config_dto.AuthenticatedMatch(
        account_tiers: option.unwrap(account_tiers, []),
      )
  }
}

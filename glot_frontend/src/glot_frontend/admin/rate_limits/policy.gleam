import gleam/int
import gleam/list
import gleam/option
import gleam/result
import glot_core/admin/rate_limit_config_dto
import glot_core/auth/account_model
import glot_core/loadable
import glot_core/public_action
import glot_core/rate_limit
import glot_frontend/admin/rate_limits/model.{
  type EditorTab, type LimitFields, type Model, type PolicyEditor,
  type PolicyTabs, AnonymousTab, FreePlusTab, FreeTab, LimitFields, Model,
  PolicyEditor, PolicyTabs,
}
import glot_frontend/request_generation
import glot_frontend/ui/mutation

pub fn loaded(model: Model) -> List(PolicyEditor) {
  case model.policies {
    loadable.Loaded(policies) -> policies
    loadable.NotLoaded | loadable.Loading | loadable.LoadError(_) -> []
  }
}

pub fn from_responses(
  policies: List(rate_limit_config_dto.RateLimitPolicyResponse),
) -> List(PolicyEditor) {
  build_policies(public_action.list(), policies)
}

fn build_policies(
  actions: List(public_action.PublicAction),
  responses: List(rate_limit_config_dto.RateLimitPolicyResponse),
) -> List(PolicyEditor) {
  case actions {
    [] -> []
    [action, ..rest] -> [
      policy_editor_from_response(
        action,
        find_policy_response(responses, action),
      ),
      ..build_policies(rest, responses)
    ]
  }
}

fn policy_editor_from_response(
  action: public_action.PublicAction,
  response: option.Option(rate_limit_config_dto.RateLimitPolicyResponse),
) -> PolicyEditor {
  case response {
    option.Some(response) -> {
      let tabs = tabs_from_rules(response.rules)
      PolicyEditor(
        action: action,
        saved_tabs: tabs,
        draft_tabs: tabs,
        state: mutation.Idle,
        save_generation: request_generation.initial(),
      )
    }
    option.None -> {
      let tabs = empty_policy_tabs()
      PolicyEditor(
        action: action,
        saved_tabs: tabs,
        draft_tabs: tabs,
        state: mutation.Idle,
        save_generation: request_generation.initial(),
      )
    }
  }
}

pub fn tabs_from_rules(
  rules: List(rate_limit_config_dto.RateLimitRule),
) -> PolicyTabs {
  list.fold(rules, empty_policy_tabs(), fn(tabs, rule) {
    let fields = limit_fields_from_limits(rule.limits)

    case rule.match {
      rate_limit_config_dto.AnonymousMatch ->
        PolicyTabs(..tabs, anonymous: fields)
      rate_limit_config_dto.AuthenticatedMatch(account_tiers) ->
        case account_tiers {
          [account_model.FreeTier] -> PolicyTabs(..tabs, free: fields)
          [account_model.FreePlusTier] -> PolicyTabs(..tabs, free_plus: fields)
          _ -> tabs
        }
    }
  })
}

fn empty_policy_tabs() -> PolicyTabs {
  PolicyTabs(
    anonymous: empty_limit_fields(),
    free: empty_limit_fields(),
    free_plus: empty_limit_fields(),
  )
}

fn empty_limit_fields() -> LimitFields {
  LimitFields(second: "", minute: "", hour: "", day: "")
}

fn limit_fields_from_limits(limits: List(rate_limit.RateLimit)) -> LimitFields {
  list.fold(limits, empty_limit_fields(), fn(fields, limit) {
    let value = int.to_string(limit.max_requests)
    case limit.unit {
      rate_limit.Second -> LimitFields(..fields, second: value)
      rate_limit.Minute -> LimitFields(..fields, minute: value)
      rate_limit.Hour -> LimitFields(..fields, hour: value)
      rate_limit.Day -> LimitFields(..fields, day: value)
    }
  })
}

pub fn to_request(
  policy: PolicyEditor,
) -> Result(rate_limit_config_dto.UpsertRateLimitPolicyRequest, String) {
  use anonymous <- result.try(rule_from_tab(
    AnonymousTab,
    policy.draft_tabs.anonymous,
  ))
  use free <- result.try(rule_from_tab(FreeTab, policy.draft_tabs.free))
  use free_plus <- result.try(rule_from_tab(
    FreePlusTab,
    policy.draft_tabs.free_plus,
  ))
  let rules =
    []
    |> append_optional_rule(anonymous)
    |> append_optional_rule(free)
    |> append_optional_rule(free_plus)

  case rules {
    [] ->
      Error(
        "Add at least one limit in Anonymous, Free, or FreePlus before saving.",
      )
    _ ->
      Ok(rate_limit_config_dto.UpsertRateLimitPolicyRequest(
        action: policy.action,
        rules: rules,
      ))
  }
}

fn rule_from_tab(
  tab: EditorTab,
  fields: LimitFields,
) -> Result(option.Option(rate_limit_config_dto.RateLimitRule), String) {
  use limits <- result.try(limits_from_fields(fields))
  case limits {
    [] -> Ok(option.None)
    limits -> Ok(option.Some(rate_limit_rule(tab, limits)))
  }
}

fn append_optional_rule(
  rules: List(rate_limit_config_dto.RateLimitRule),
  rule: option.Option(rate_limit_config_dto.RateLimitRule),
) -> List(rate_limit_config_dto.RateLimitRule) {
  case rule {
    option.Some(rule) -> list.append(rules, [rule])
    option.None -> rules
  }
}

fn rate_limit_rule(
  tab: EditorTab,
  limits: List(rate_limit.RateLimit),
) -> rate_limit_config_dto.RateLimitRule {
  let rule_match = case tab {
    AnonymousTab -> rate_limit_config_dto.AnonymousMatch
    FreeTab ->
      rate_limit_config_dto.AuthenticatedMatch(account_tiers: [
        account_model.FreeTier,
      ])
    FreePlusTab ->
      rate_limit_config_dto.AuthenticatedMatch(account_tiers: [
        account_model.FreePlusTier,
      ])
  }

  rate_limit_config_dto.RateLimitRule(match: rule_match, limits: limits)
}

fn limits_from_fields(
  fields: LimitFields,
) -> Result(List(rate_limit.RateLimit), String) {
  use second <- result.try(optional_limit(
    fields.second,
    rate_limit.Second,
    "Per second",
  ))
  use minute <- result.try(optional_limit(
    fields.minute,
    rate_limit.Minute,
    "Per minute",
  ))
  use hour <- result.try(optional_limit(
    fields.hour,
    rate_limit.Hour,
    "Per hour",
  ))
  use day <- result.try(optional_limit(fields.day, rate_limit.Day, "Per day"))

  Ok(
    []
    |> append_optional_limit(second)
    |> append_optional_limit(minute)
    |> append_optional_limit(hour)
    |> append_optional_limit(day),
  )
}

fn optional_limit(
  value: String,
  unit: rate_limit.TimeUnit,
  label: String,
) -> Result(option.Option(rate_limit.RateLimit), String) {
  case value {
    "" -> Ok(option.None)
    _ ->
      case int.parse(value) {
        Ok(max_requests) if max_requests > 0 ->
          Ok(
            option.Some(rate_limit.RateLimit(unit:, max_requests: max_requests)),
          )
        Ok(_) -> Error(label <> " must be greater than 0.")
        Error(_) -> Error(label <> " must be a whole number.")
      }
  }
}

fn append_optional_limit(
  limits: List(rate_limit.RateLimit),
  maybe_limit: option.Option(rate_limit.RateLimit),
) -> List(rate_limit.RateLimit) {
  case maybe_limit {
    option.Some(limit) -> list.append(limits, [limit])
    option.None -> limits
  }
}

pub fn update_tab(
  tabs: PolicyTabs,
  tab: EditorTab,
  update: fn(LimitFields) -> LimitFields,
) -> PolicyTabs {
  case tab {
    AnonymousTab -> PolicyTabs(..tabs, anonymous: update(tabs.anonymous))
    FreeTab -> PolicyTabs(..tabs, free: update(tabs.free))
    FreePlusTab -> PolicyTabs(..tabs, free_plus: update(tabs.free_plus))
  }
}

pub fn update_limit(
  fields: LimitFields,
  unit: rate_limit.TimeUnit,
  value: String,
) -> LimitFields {
  case unit {
    rate_limit.Second -> LimitFields(..fields, second: value)
    rate_limit.Minute -> LimitFields(..fields, minute: value)
    rate_limit.Hour -> LimitFields(..fields, hour: value)
    rate_limit.Day -> LimitFields(..fields, day: value)
  }
}

pub fn find(
  policies: List(PolicyEditor),
  action: public_action.PublicAction,
) -> option.Option(PolicyEditor) {
  list.find(policies, fn(policy) { policy.action == action })
  |> option.from_result()
}

fn find_policy_response(
  responses: List(rate_limit_config_dto.RateLimitPolicyResponse),
  action: public_action.PublicAction,
) -> option.Option(rate_limit_config_dto.RateLimitPolicyResponse) {
  list.find(responses, fn(response) { response.action == action })
  |> option.from_result()
}

pub fn update(
  policies: List(PolicyEditor),
  action: public_action.PublicAction,
  update: fn(PolicyEditor) -> PolicyEditor,
) -> List(PolicyEditor) {
  list.map(policies, fn(policy) {
    case policy.action == action {
      True -> update(policy)
      False -> policy
    }
  })
}

pub fn invalidate_active_save(model: Model) -> Model {
  case model.active_editor {
    option.None -> model
    option.Some(active) ->
      Model(
        ..model,
        active_editor: option.None,
        policies: loadable.Loaded(
          update(loaded(model), active.action, fn(policy) {
            PolicyEditor(
              ..policy,
              state: mutation.Idle,
              save_generation: request_generation.next(policy.save_generation),
            )
          }),
        ),
      )
  }
}

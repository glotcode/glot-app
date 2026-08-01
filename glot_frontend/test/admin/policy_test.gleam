import gleam/option
import gleam/time/timestamp
import glot_core/admin/rate_limit_config_dto
import glot_core/auth/account_model
import glot_core/auth/user_model
import glot_core/email/email_address_model
import glot_core/loadable
import glot_core/public_action
import glot_core/rate_limit
import glot_frontend/admin/jobs/create_job_policy
import glot_frontend/admin/jobs/model as job_model
import glot_frontend/admin/list_query
import glot_frontend/admin/periodic_jobs/editor_policy as periodic_job_policy
import glot_frontend/admin/periodic_jobs/model as periodic_job_model
import glot_frontend/admin/rate_limits/model as rate_limit_model
import glot_frontend/admin/rate_limits/policy as rate_limit_policy
import glot_frontend/admin/users/editor_policy as user_policy
import glot_frontend/admin/users/list_filter
import glot_frontend/admin/users/list_model
import glot_frontend/admin/users/model as user_detail_model
import glot_frontend/request_generation
import glot_frontend/ui/mutation
import youid/uuid

pub fn create_job_policy_requires_valid_schedule_and_limits_test() {
  let valid = job_editor("2026-07-22", "12:30", "3", "60")
  assert create_job_policy.validate(valid) == Ok(Nil)

  assert create_job_policy.validate(job_editor("", "12:30", "3", "60"))
    == Error("Run date and time are required.")
  assert create_job_policy.validate(job_editor("2026-07-22", "12:30", "0", "60"))
    == Error("Max attempts must be greater than zero.")
  assert create_job_policy.validate(job_editor(
      "2026-07-22",
      "12:30",
      "3",
      "soon",
    ))
    == Error("Timeout seconds must be a whole number.")
}

pub fn periodic_job_policy_requires_valid_schedule_and_interval_test() {
  assert periodic_job_policy.validate(periodic_job_editor(
      "2026-07-22",
      "12:30",
      "60",
    ))
    == Ok(Nil)
  assert periodic_job_policy.validate(periodic_job_editor("", "12:30", "60"))
    == Error("Next run date and time are required.")
  assert periodic_job_policy.validate(periodic_job_editor(
      "2026-07-22",
      "12:30",
      "0",
    ))
    == Error("Interval seconds must be greater than zero.")
}

pub fn rate_limit_policy_rejects_empty_and_invalid_drafts_test() {
  assert rate_limit_policy.to_request(rate_limit_editor(empty_limits()))
    == Error(
      "Add at least one limit in Anonymous, Free, or FreePlus before saving.",
    )

  let invalid =
    rate_limit_model.LimitFields(
      second: "not-a-number",
      minute: "",
      hour: "",
      day: "",
    )
  assert rate_limit_policy.to_request(rate_limit_editor(invalid))
    == Error("Per second must be a whole number.")
}

pub fn rate_limit_policy_builds_typed_rules_from_valid_fields_test() {
  let limits =
    rate_limit_model.LimitFields(second: "5", minute: "100", hour: "", day: "")
  let assert Ok(rate_limit_config_dto.UpsertRateLimitPolicyRequest(
    action,
    rules,
  )) = rate_limit_policy.to_request(rate_limit_editor(limits))
  assert action == public_action.RunAction
  let assert [
    rate_limit_config_dto.RateLimitRule(
      rate_limit_config_dto.AnonymousMatch,
      [
        rate_limit.RateLimit(rate_limit.Second, 5),
        rate_limit.RateLimit(rate_limit.Minute, 100),
      ],
    ),
  ] = rules
}

pub fn user_list_filter_classifies_one_search_value_test() {
  let id_text = "00000000-0000-4000-8000-000000000001"
  let assert Ok(id) = uuid.from_string(id_text)

  assert list_filter.email(" person@example.com ")
    == option.Some("person@example.com")
  assert list_filter.username(" person ") == option.Some("person")
  assert list_filter.user_id(" " <> id_text <> " ") == option.Some(id)
  assert list_filter.email("person") == option.None
  assert list_filter.username("person@example.com") == option.None
  assert list_filter.username(id_text) == option.None
}

pub fn user_list_filter_reports_active_fields_test() {
  let model =
    list_model.Model(
      page: loadable.NotLoaded,
      search_filter: "",
      role_filter: "",
      account_state_filter: "",
      account_tier_filter: "",
      query: list_query.empty(),
    )
  assert list_filter.has_filters(model) == False
  assert list_filter.has_filters(
      list_model.Model(..model, role_filter: "admin"),
    )
    == True
}

pub fn user_policy_normalizes_username_and_account_reason_test() {
  let active = user_editor(" person ", account_model.Active, " ignored ")
  let assert Ok(active_request) = user_policy.to_request(active)
  assert active_request.username == "person"
  assert active_request.account_state_reason == option.None

  let suspended =
    user_editor("person", account_model.Suspended, " policy violation ")
  let assert Ok(suspended_request) = user_policy.to_request(suspended)
  assert suspended_request.account_state_reason
    == option.Some("policy violation")

  assert user_policy.to_request(user_editor(
      "Invalid Name",
      account_model.Active,
      "",
    ))
    == Error(
      "Invalid username: use 3-40 lowercase letters, digits, dots, or hyphens",
    )
}

fn job_editor(
  date: String,
  time: String,
  max_attempts: String,
  timeout_seconds: String,
) -> job_model.CreateJobEditor {
  job_model.CreateJobEditor(
    source_job_id: uuid.v7(),
    draft: job_model.CreateJobDraft(
      periodic_job_id: option.None,
      job_type: "fixture",
      payload: "",
      max_attempts: max_attempts,
      timeout_seconds: timeout_seconds,
      run_date: date,
      run_time: time,
    ),
    state: job_model.CreateJobIdle,
  )
}

fn rate_limit_editor(
  anonymous: rate_limit_model.LimitFields,
) -> rate_limit_model.PolicyEditor {
  let tabs =
    rate_limit_model.PolicyTabs(
      anonymous: anonymous,
      free: empty_limits(),
      free_plus: empty_limits(),
    )
  rate_limit_model.PolicyEditor(
    action: public_action.RunAction,
    saved_tabs: tabs,
    draft_tabs: tabs,
    state: mutation.Idle,
    save_generation: request_generation.initial(),
  )
}

fn periodic_job_editor(
  date: String,
  time: String,
  interval_seconds: String,
) -> periodic_job_model.PeriodicJobEditor {
  let fields =
    periodic_job_model.PeriodicJobFields(
      payload: "",
      interval_seconds: interval_seconds,
      enabled: True,
      next_run_date: date,
      next_run_time: time,
    )
  let now = timestamp.from_unix_seconds(0)
  periodic_job_model.PeriodicJobEditor(
    id: uuid.v7(),
    job_type: "fixture",
    saved: fields,
    draft: fields,
    metadata: periodic_job_model.PeriodicJobMetadata(
      next_run_at: now,
      last_enqueued_at: option.None,
      last_enqueue_error: option.None,
      created_at: now,
      updated_at: now,
    ),
    state: periodic_job_model.Idle,
  )
}

fn user_editor(
  username: String,
  account_state: account_model.AccountState,
  account_state_reason: String,
) -> user_detail_model.UserEditor {
  let fields =
    user_detail_model.UserFields(
      username: username,
      role: user_model.RegularUser,
      account_state: account_state,
      account_state_reason: account_state_reason,
      account_tier: account_model.FreeTier,
    )
  let now = timestamp.from_unix_seconds(0)
  user_detail_model.UserEditor(
    id: uuid.v7(),
    account_id: uuid.v7(),
    email: email_address_model.EmailAddress("person@example.com"),
    saved: fields,
    draft: fields,
    metadata: user_detail_model.UserMetadata(
      delete_job_id: option.None,
      delete_scheduled_at: option.None,
      last_login_at: now,
      created_at: now,
      updated_at: now,
    ),
    state: mutation.Idle,
  )
}

fn empty_limits() -> rate_limit_model.LimitFields {
  rate_limit_model.LimitFields(second: "", minute: "", hour: "", day: "")
}

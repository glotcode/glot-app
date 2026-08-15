import gleam/dict.{type Dict}
import gleam/list
import gleam/option
import gleam/regexp
import gleam/time/timestamp
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/app_config/model/system_config
import glot_backend/auth/model/config as auth_feature_config
import glot_backend/email/model/config as email_feature_config
import glot_backend/email/model/template as email_template
import glot_backend/logging/ingestion/model/config as logging_config
import glot_backend/request_policy/model/config as request_policy_config
import glot_backend/run_code/model/config as run_code_config
import glot_backend/system/request/context
import glot_core/auth/account_model
import glot_core/auth/platform_model
import glot_core/auth/session_model
import glot_core/auth/user_model
import glot_core/availability_mode
import glot_core/email/email_address_model
import glot_core/job/job_model
import glot_core/language
import glot_core/snippet/snippet_model
import support/integration/model
import support/integration/store/common
import youid/uuid

pub fn integration_fixture(
  next_uuids next_uuids: List(uuid.Uuid),
  jobs jobs: List(job_model.Job),
  account_delete_job_id account_delete_job_id: option.Option(uuid.Uuid),
) -> model.TestFixture {
  let account =
    account_model.Account(
      id: test_account_id(),
      account_state: account_model.Active,
      account_state_reason: option.None,
      account_tier: account_model.FreeTier,
      delete_job_id: account_delete_job_id,
      created_at: test_timestamp(),
      updated_at: test_timestamp(),
    )
  let user =
    user_model.User(
      id: test_user_id(),
      account_id: account.id,
      email: email_address_model.EmailAddress("user@example.com"),
      username: "user",
      role: user_model.RegularUser,
      last_login_at: test_timestamp(),
      created_at: test_timestamp(),
      updated_at: test_timestamp(),
    )
  let session =
    session_model.Session(
      id: test_session_id(),
      user_id: user.id,
      token: "session-token",
      previous_token: option.None,
      previous_token_valid_until: option.None,
      ip: option.Some("127.0.0.1"),
      os_name: option.Some(platform_model.MacOS),
      browser_name: option.Some(platform_model.Chrome),
      user_agent: option.Some("gleeunit"),
      created_at: test_timestamp(),
      token_updated_at: test_timestamp(),
      last_activity_at: test_timestamp(),
    )
  let snippet =
    snippet_model.Snippet(
      id: test_snippet_id(),
      slug: "snippet-slug",
      user_id: user.id,
      title: "Snippet",
      language: language.Python,
      visibility: snippet_model.Public,
      stdin: "",
      run_instructions: option.None,
      files: [snippet_model.File(name: "main.py", content: "print(1)")],
      created_at: test_timestamp(),
      updated_at: test_timestamp(),
    )
  let db =
    model.TestState(
      dynamic_config: test_dynamic_config(),
      accounts: dict.from_list([#(common.uuid_key(account.id), account)]),
      users: dict.from_list([#(common.uuid_key(user.id), user)]),
      email_templates: default_email_templates(),
      login_tokens: dict.new(),
      email_change_tokens: dict.new(),
      passkey_credentials: dict.new(),
      passkey_challenges: dict.new(),
      sessions: dict.from_list([#(common.uuid_key(session.id), session)]),
      session_ids_by_token: dict.from_list([
        #(session.token, common.uuid_key(session.id)),
      ]),
      run_logs: dict.new(),
      jobs: dict.from_list(
        list.map(jobs, fn(job) { #(common.uuid_key(job.id), job) }),
      ),
      job_type_policies: default_job_type_policies(),
      periodic_jobs: dict.new(),
      snippets: dict.from_list([#(common.uuid_key(snippet.id), snippet)]),
      user_actions: dict.new(),
      user_action_count: 0,
      write_steps: [],
      deletion_steps: [],
      next_uuids: next_uuids,
      system_time: test_system_time(),
    )
  let ctx =
    context.Context(
      ..test_context(),
      request_id: test_request_id(),
      timestamp: test_timestamp(),
      client_info: context.ClientInfo(
        session_token: option.Some(session.token),
        ip: option.Some("127.0.0.1"),
        user_agent: option.Some("gleeunit"),
        referrer: option.None,
      ),
    )

  model.TestFixture(
    ctx: ctx,
    state: db,
    account: account,
    user: user,
    session: session,
    snippet: snippet,
  )
}

pub fn suspended_integration_fixture(
  next_uuids next_uuids: List(uuid.Uuid),
  jobs jobs: List(job_model.Job),
  account_delete_job_id account_delete_job_id: option.Option(uuid.Uuid),
) -> model.TestFixture {
  let fixture =
    integration_fixture(
      next_uuids: next_uuids,
      jobs: jobs,
      account_delete_job_id: account_delete_job_id,
    )
  let suspended_account =
    account_model.Account(
      ..fixture.account,
      account_state: account_model.Suspended,
      account_state_reason: option.Some("suspended for test"),
    )
  let db =
    model.TestState(
      ..fixture.state,
      accounts: dict.insert(
        fixture.state.accounts,
        common.uuid_key(suspended_account.id),
        suspended_account,
      ),
    )

  model.TestFixture(..fixture, state: db, account: suspended_account)
}

pub fn admin_integration_fixture() -> model.TestFixture {
  let fixture =
    integration_fixture(
      next_uuids: [],
      jobs: [],
      account_delete_job_id: option.None,
    )
  let admin_user = user_model.User(..fixture.user, role: user_model.AdminUser)
  let db =
    model.TestState(
      ..fixture.state,
      users: dict.from_list([#(common.uuid_key(admin_user.id), admin_user)]),
    )

  model.TestFixture(..fixture, state: db, user: admin_user)
}

pub fn empty_test_state() -> model.TestState {
  model.TestState(
    dynamic_config: test_dynamic_config(),
    accounts: dict.new(),
    users: dict.new(),
    email_templates: default_email_templates(),
    login_tokens: dict.new(),
    email_change_tokens: dict.new(),
    passkey_credentials: dict.new(),
    passkey_challenges: dict.new(),
    sessions: dict.new(),
    session_ids_by_token: dict.new(),
    run_logs: dict.new(),
    jobs: dict.new(),
    job_type_policies: default_job_type_policies(),
    periodic_jobs: dict.new(),
    snippets: dict.new(),
    user_actions: dict.new(),
    user_action_count: 0,
    write_steps: [],
    deletion_steps: [],
    next_uuids: [],
    system_time: test_system_time(),
  )
}

pub fn default_email_templates() -> Dict(String, email_template.EmailTemplate) {
  dict.from_list([
    #(
      email_template.to_db_name(email_template.LoginTokenTemplate),
      email_template.EmailTemplate(
        name: email_template.LoginTokenTemplate,
        subject_template: "Your login token",
        text_body_template: "Your login token is: {{token}}",
        html_body_template: option.None,
        updated_at: test_system_time(),
      ),
    ),
    #(
      email_template.to_db_name(email_template.AccountDeletedTemplate),
      email_template.EmailTemplate(
        name: email_template.AccountDeletedTemplate,
        subject_template: "Your account has been deleted",
        text_body_template: "Your account has been deleted.",
        html_body_template: option.None,
        updated_at: test_system_time(),
      ),
    ),
    #(
      email_template.to_db_name(email_template.ContactTemplate),
      email_template.EmailTemplate(
        name: email_template.ContactTemplate,
        subject_template: "Contact form submission: {{topic}}",
        text_body_template: "Topic: {{topic}}\nSubmitted email (not verified): {{email}}\nAuthenticated user ID: {{user_id}}\nRequest ID: {{request_id}}\n\n{{message}}",
        html_body_template: option.None,
        updated_at: test_system_time(),
      ),
    ),
    #(
      email_template.to_db_name(email_template.EmailChangeVerificationTemplate),
      email_template.EmailTemplate(
        name: email_template.EmailChangeVerificationTemplate,
        subject_template: "Verify your new email address",
        text_body_template: "Code: {{token}}",
        html_body_template: option.None,
        updated_at: test_system_time(),
      ),
    ),
    #(
      email_template.to_db_name(email_template.EmailChangedTemplate),
      email_template.EmailTemplate(
        name: email_template.EmailChangedTemplate,
        subject_template: "Your email address changed",
        text_body_template: "Changed to {{new_email}}",
        html_body_template: option.None,
        updated_at: test_system_time(),
      ),
    ),
    #(
      email_template.to_db_name(email_template.EmailChangeAddressInUseTemplate),
      email_template.EmailTemplate(
        name: email_template.EmailChangeAddressInUseTemplate,
        subject_template: "Email address already in use",
        text_body_template: "This email address is already associated with a glot account, so the requested email change was not completed. Please choose a different email address.",
        html_body_template: option.None,
        updated_at: test_system_time(),
      ),
    ),
  ])
}

pub fn default_job_type_policies() -> Dict(String, job_model.JobTypePolicy) {
  let created_at = test_system_time()

  [
    job_model.SendEmailJob,
    job_model.DeleteAccountJob,
    job_model.CleanApiLogJob,
    job_model.CleanPageLogJob,
    job_model.CleanPageviewLogJob,
    job_model.CleanRunLogJob,
    job_model.CleanJobLogJob,
    job_model.CleanJobsJob,
    job_model.CleanSessionsJob,
    job_model.CleanVerificationTokensJob,
    job_model.CleanUserActionsJob,
    job_model.AggregateMetricsJob,
  ]
  |> list.map(fn(job_type) {
    let policy =
      job_model.JobTypePolicy(
        job_type: job_type,
        queue: job_model.DefaultQueue,
        max_attempts: 5,
        timeout_seconds: 120,
        base_backoff_seconds: 5,
        max_backoff_seconds: 300,
        created_at: created_at,
        updated_at: created_at,
      )
    #(job_model.job_type_to_string(job_type), policy)
  })
  |> dict.from_list
}

pub fn test_job_type_policy(
  job_type: job_model.JobType,
) -> job_model.JobTypePolicy {
  let assert Ok(policy) =
    dict.get(
      default_job_type_policies(),
      job_model.job_type_to_string(job_type),
    )
  policy
}

pub fn repeat_string(value: String, count: Int) -> String {
  case count <= 0 {
    True -> ""
    False -> value <> repeat_string(value, count - 1)
  }
}

pub fn test_dynamic_config() -> dynamic_config.DynamicConfig {
  dynamic_config.DynamicConfig(
    debug: system_config.DebugConfig(enabled: False),
    http_pool: system_config.HttpPoolConfig(16, 4, 120_000),
    availability: test_availability_config(),
    auth: test_auth_config(),
    passkey: test_passkey_config(),
    cleanup: test_cleanup_config(),
    log_worker: test_log_worker_config(),
    language_version_cache_worker: test_language_version_cache_worker_config(),
    docker_run: option.None,
    spam_classifier: option.None,
    cloudflare: option.Some(test_cloudflare_config()),
    email: option.Some(test_email_config()),
    rate_limit_policies: dict.new(),
  )
}

pub fn test_cloudflare_config() -> email_feature_config.CloudflareConfig {
  email_feature_config.CloudflareConfig(
    account_id: "cf-account-id",
    api_token: "cf-api-token",
  )
}

pub fn test_email_config() -> email_feature_config.EmailConfig {
  email_feature_config.EmailConfig(
    from_address: "sender@example.com",
    from_name: option.Some("Sender"),
    contact_address: option.Some("contact@example.com"),
    default_timeout_ms: 60_000,
  )
}

pub fn anonymous_test_context() -> context.Context {
  context.Context(
    ..test_context(),
    client_info: context.ClientInfo(
      session_token: option.None,
      ip: option.Some("127.0.0.1"),
      user_agent: option.Some("gleeunit"),
      referrer: option.None,
    ),
  )
}

pub fn test_passkey_config() -> auth_feature_config.PasskeyConfig {
  auth_feature_config.PasskeyConfig(
    origin: "https://glot.io",
    rp_id: "glot.io",
    challenge_timeout_seconds: 120,
  )
}

pub fn test_log_worker_config() -> logging_config.Config {
  logging_config.Config(
    flush_interval_ms: 5000,
    max_batch_size: 100,
    max_buffer_size: 1000,
  )
}

pub fn test_language_version_cache_worker_config() -> run_code_config.LanguageVersionCacheWorkerConfig {
  run_code_config.LanguageVersionCacheWorkerConfig(
    refresh_interval_ms: 3_600_000,
    refresh_step_delay_ms: 1000,
    refresh_step_jitter_ms: 500,
    default_timeout_ms: 60_000,
  )
}

pub fn test_auth_config() -> auth_feature_config.AuthConfig {
  auth_feature_config.AuthConfig(
    login_token_max_age: 900,
    session_token_max_age: 86_400,
    session_idle_timeout_seconds: 86_400,
    session_cookie_max_age: 86_400,
    session_refresh_interval_seconds: 300,
    session_previous_token_grace_seconds: 60,
    session_heartbeat_interval_seconds: 60,
  )
}

pub fn test_availability_config() -> request_policy_config.AvailabilityConfig {
  request_policy_config.AvailabilityConfig(
    mode: availability_mode.NormalMode,
    message: "glot.io is temporarily unavailable right now.",
    retry_after_seconds: option.None,
  )
}

pub fn test_cleanup_config() -> system_config.CleanupConfig {
  system_config.CleanupConfig(
    api_log_retention_days: 30,
    page_log_retention_days: 30,
    pageview_log_retention_days: 30,
    run_log_retention_days: 30,
    job_log_retention_days: 30,
    jobs_retention_days: 30,
    login_tokens_retention_days: 30,
    user_actions_retention_days: 30,
  )
}

pub fn must_uuid(value: String) -> uuid.Uuid {
  let assert Ok(id) = uuid.from_string(value)
  id
}

pub fn test_request_id() -> uuid.Uuid {
  must_uuid("00000000-0000-0000-0000-000000000001")
}

pub fn test_account_id() -> uuid.Uuid {
  must_uuid("00000000-0000-0000-0000-000000000010")
}

pub fn test_email_address() -> email_address_model.EmailAddress {
  email_address_model.EmailAddress("user@example.com")
}

pub fn test_user_id() -> uuid.Uuid {
  must_uuid("00000000-0000-0000-0000-000000000011")
}

pub fn test_session_id() -> uuid.Uuid {
  must_uuid("00000000-0000-0000-0000-000000000012")
}

pub fn test_snippet_id() -> uuid.Uuid {
  must_uuid("00000000-0000-0000-0000-000000000013")
}

pub fn test_timestamp() -> timestamp.Timestamp {
  timestamp.from_unix_seconds_and_nanoseconds(1_700_000_000, 0)
}

pub fn test_system_time() -> timestamp.Timestamp {
  timestamp.from_unix_seconds_and_nanoseconds(1_700_000_005, 0)
}

pub fn add_seconds(
  ts: timestamp.Timestamp,
  seconds_to_add: Int,
) -> timestamp.Timestamp {
  let #(seconds, nanos) = timestamp.to_unix_seconds_and_nanoseconds(ts)
  timestamp.from_unix_seconds_and_nanoseconds(seconds + seconds_to_add, nanos)
}

pub fn login_test_context() -> context.Context {
  context.Context(
    ..test_context(),
    timestamp: test_timestamp(),
    client_info: context.ClientInfo(
      session_token: option.None,
      ip: option.Some("127.0.0.1"),
      user_agent: option.Some("gleeunit"),
      referrer: option.None,
    ),
  )
}

pub fn test_context() -> context.Context {
  let assert Ok(is_email) = regexp.from_string(".*")

  context.Context(
    config: context.Config(
      app_env: context.Dev,
      encryption_key: "test",
      listening_address: "localhost",
      listening_port: 3000,
      static_base_path: "/tmp",
      postgres: context.PostgresConfig(
        host: "localhost",
        port: 5432,
        db: "test",
        user: "test",
        pass: "test",
        pool_size: 1,
      ),
    ),
    regexes: context.Regexes(is_email: is_email),
    request_id: uuid.nil,
    started_at: 0,
    deadline_at_monotonic_ns: option.None,
    timestamp: timestamp.system_time(),
    client_info: context.ClientInfo(
      session_token: option.None,
      ip: option.None,
      user_agent: option.None,
      referrer: option.None,
    ),
  )
}

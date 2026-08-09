import gleam/dict.{type Dict}
import gleam/time/timestamp
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/email/model/template as email_template
import glot_backend/system/request/context
import glot_core/auth/account_model
import glot_core/auth/email_change_token_model
import glot_core/auth/login_token_model
import glot_core/auth/passkey_challenge_model
import glot_core/auth/passkey_credential_model
import glot_core/auth/session_model
import glot_core/auth/user_model
import glot_core/job/job_model
import glot_core/periodic_job/periodic_job_model
import glot_core/run_log_model
import glot_core/snippet/snippet_model
import glot_core/user_action
import youid/uuid

pub type TestFixture {
  TestFixture(
    ctx: context.Context,
    state: TestState,
    account: account_model.Account,
    user: user_model.User,
    session: session_model.Session,
    snippet: snippet_model.Snippet,
  )
}

pub type TestState {
  TestState(
    dynamic_config: dynamic_config.DynamicConfig,
    accounts: Dict(String, account_model.Account),
    users: Dict(String, user_model.User),
    email_templates: Dict(String, email_template.EmailTemplate),
    login_tokens: Dict(String, login_token_model.LoginToken),
    email_change_tokens: Dict(String, email_change_token_model.EmailChangeToken),
    passkey_credentials: Dict(
      String,
      passkey_credential_model.PasskeyCredential,
    ),
    passkey_challenges: Dict(String, passkey_challenge_model.PasskeyChallenge),
    sessions: Dict(String, session_model.Session),
    session_ids_by_token: Dict(String, String),
    run_logs: Dict(String, run_log_model.RunLog),
    jobs: Dict(String, job_model.Job),
    job_type_policies: Dict(String, job_model.JobTypePolicy),
    periodic_jobs: Dict(String, periodic_job_model.PeriodicJob),
    snippets: Dict(String, snippet_model.Snippet),
    user_actions: Dict(String, user_action.UserAction),
    user_action_count: Int,
    write_steps: List(String),
    deletion_steps: List(String),
    next_uuids: List(uuid.Uuid),
    system_time: timestamp.Timestamp,
  )
}

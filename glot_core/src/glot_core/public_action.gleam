import gleam/dynamic/decode
import gleam/json
import gleam/option
import glot_core/server_timing_policy

pub type PublicAction {
  TrackPageviewAction
  RunAction
  GetLanguageVersionAction
  GetSessionAction
  RefreshSessionAction
  LogoutAction
  GetAccountAction
  ListAccountSessionsAction
  ListAccountPasskeysAction
  UpdateAccountAction
  BeginEmailChangeAction
  ConfirmEmailChangeAction
  DeleteAccountSessionAction
  DeleteAccountPasskeyAction
  ScheduleDeleteAccountAction
  CancelDeleteAccountAction
  GetSnippetAction
  ListPublicSnippetsAction
  ListSessionSnippetsAction
  CreateSnippetAction
  UpdateSnippetAction
  DeleteSnippetAction
  SubmitContactAction
  SendLoginTokenAction
  LoginAction
  BeginPasskeyRegistrationAction
  FinishPasskeyRegistrationAction
  BeginPasskeyLoginAction
  FinishPasskeyLoginAction
}

pub fn list() -> List(PublicAction) {
  [
    TrackPageviewAction,
    RunAction,
    GetLanguageVersionAction,
    GetSessionAction,
    RefreshSessionAction,
    LogoutAction,
    GetAccountAction,
    ListAccountSessionsAction,
    ListAccountPasskeysAction,
    UpdateAccountAction,
    BeginEmailChangeAction,
    ConfirmEmailChangeAction,
    DeleteAccountSessionAction,
    DeleteAccountPasskeyAction,
    ScheduleDeleteAccountAction,
    CancelDeleteAccountAction,
    GetSnippetAction,
    ListPublicSnippetsAction,
    ListSessionSnippetsAction,
    CreateSnippetAction,
    UpdateSnippetAction,
    DeleteSnippetAction,
    SubmitContactAction,
    SendLoginTokenAction,
    LoginAction,
    BeginPasskeyRegistrationAction,
    FinishPasskeyRegistrationAction,
    BeginPasskeyLoginAction,
    FinishPasskeyLoginAction,
  ]
}

pub fn decoder() -> decode.Decoder(PublicAction) {
  use action <- decode.then(decode.string)
  case from_string(action) {
    option.Some(action) -> decode.success(action)
    option.None -> decode.failure(RunAction, "PublicAction")
  }
}

pub fn encode(action: PublicAction) -> json.Json {
  action |> to_string |> json.string
}

pub fn to_string(action: PublicAction) -> String {
  case action {
    TrackPageviewAction -> "track_pageview"
    RunAction -> "run"
    GetLanguageVersionAction -> "get_language_version"
    GetSessionAction -> "get_session"
    RefreshSessionAction -> "refresh_session"
    LogoutAction -> "logout"
    GetAccountAction -> "get_account"
    ListAccountSessionsAction -> "list_account_sessions"
    ListAccountPasskeysAction -> "list_account_passkeys"
    UpdateAccountAction -> "update_account"
    BeginEmailChangeAction -> "begin_email_change"
    ConfirmEmailChangeAction -> "confirm_email_change"
    DeleteAccountSessionAction -> "delete_account_session"
    DeleteAccountPasskeyAction -> "delete_account_passkey"
    ScheduleDeleteAccountAction -> "schedule_delete_account"
    CancelDeleteAccountAction -> "cancel_delete_account"
    GetSnippetAction -> "get_snippet"
    ListPublicSnippetsAction -> "list_public_snippets"
    ListSessionSnippetsAction -> "list_session_snippets"
    CreateSnippetAction -> "create_snippet"
    UpdateSnippetAction -> "update_snippet"
    DeleteSnippetAction -> "delete_snippet"
    SubmitContactAction -> "submit_contact"
    SendLoginTokenAction -> "send_login_token"
    LoginAction -> "login"
    BeginPasskeyRegistrationAction -> "begin_passkey_registration"
    FinishPasskeyRegistrationAction -> "finish_passkey_registration"
    BeginPasskeyLoginAction -> "begin_passkey_login"
    FinishPasskeyLoginAction -> "finish_passkey_login"
  }
}

pub fn from_string(action: String) -> option.Option(PublicAction) {
  case action {
    "track_pageview" -> option.Some(TrackPageviewAction)
    "run" -> option.Some(RunAction)
    "get_language_version" -> option.Some(GetLanguageVersionAction)
    "get_session" -> option.Some(GetSessionAction)
    "refresh_session" -> option.Some(RefreshSessionAction)
    "logout" -> option.Some(LogoutAction)
    "get_account" -> option.Some(GetAccountAction)
    "list_account_sessions" -> option.Some(ListAccountSessionsAction)
    "list_account_passkeys" -> option.Some(ListAccountPasskeysAction)
    "update_account" -> option.Some(UpdateAccountAction)
    "begin_email_change" -> option.Some(BeginEmailChangeAction)
    "confirm_email_change" -> option.Some(ConfirmEmailChangeAction)
    "delete_account_session" -> option.Some(DeleteAccountSessionAction)
    "delete_account_passkey" -> option.Some(DeleteAccountPasskeyAction)
    "schedule_delete_account" -> option.Some(ScheduleDeleteAccountAction)
    "cancel_delete_account" -> option.Some(CancelDeleteAccountAction)
    "get_snippet" -> option.Some(GetSnippetAction)
    "list_public_snippets" -> option.Some(ListPublicSnippetsAction)
    "list_session_snippets" -> option.Some(ListSessionSnippetsAction)
    "create_snippet" -> option.Some(CreateSnippetAction)
    "update_snippet" -> option.Some(UpdateSnippetAction)
    "delete_snippet" -> option.Some(DeleteSnippetAction)
    "submit_contact" -> option.Some(SubmitContactAction)
    "send_login_token" -> option.Some(SendLoginTokenAction)
    "login" -> option.Some(LoginAction)
    "begin_passkey_registration" -> option.Some(BeginPasskeyRegistrationAction)
    "finish_passkey_registration" ->
      option.Some(FinishPasskeyRegistrationAction)
    "begin_passkey_login" -> option.Some(BeginPasskeyLoginAction)
    "finish_passkey_login" -> option.Some(FinishPasskeyLoginAction)
    _ -> option.None
  }
}

pub fn server_timing_policy(
  action: PublicAction,
) -> server_timing_policy.ServerTimingPolicy {
  case action {
    TrackPageviewAction
    | RunAction
    | GetLanguageVersionAction
    | GetSnippetAction
    | ListPublicSnippetsAction
    | ListSessionSnippetsAction
    | CreateSnippetAction
    | UpdateSnippetAction
    | DeleteSnippetAction -> server_timing_policy.ExposeServerTiming
    GetSessionAction
    | RefreshSessionAction
    | LogoutAction
    | GetAccountAction
    | ListAccountSessionsAction
    | ListAccountPasskeysAction
    | UpdateAccountAction
    | BeginEmailChangeAction
    | ConfirmEmailChangeAction
    | DeleteAccountSessionAction
    | DeleteAccountPasskeyAction
    | ScheduleDeleteAccountAction
    | CancelDeleteAccountAction
    | SubmitContactAction
    | SendLoginTokenAction
    | LoginAction
    | BeginPasskeyRegistrationAction
    | FinishPasskeyRegistrationAction
    | BeginPasskeyLoginAction
    | FinishPasskeyLoginAction -> server_timing_policy.SuppressServerTiming
  }
}

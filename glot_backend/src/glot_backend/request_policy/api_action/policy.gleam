import glot_core/admin_action.{type AdminAction}
import glot_core/api_action.{type ApiAction}
import glot_core/auth/account_model.{type AccountState}
import glot_core/public_action.{type PublicAction}

pub type AuthenticationPolicy {
  NoAuthenticationRequired
  RequireAuthentication
}

pub type AuthorizationPolicy {
  NoSpecialAuthorization
  RequireAdmin
}

pub type AccountStatePolicy {
  NoAccountStateRequirement
  AllowedAccountStates(List(AccountState))
}

pub type Policy {
  Policy(
    authentication: AuthenticationPolicy,
    authorization: AuthorizationPolicy,
    account_state: AccountStatePolicy,
  )
}

pub fn for_action(action: ApiAction) -> Policy {
  case action {
    api_action.PublicAction(action) -> for_public_action(action)
    api_action.AdminAction(action) -> for_admin_action(action)
  }
}

fn for_public_action(action: PublicAction) -> Policy {
  case action {
    public_action.TrackPageviewAction -> public(NoAccountStateRequirement)
    public_action.GetLanguageVersionAction -> public(NoAccountStateRequirement)
    public_action.SendLoginTokenAction -> public(active_or_read_only())
    public_action.SubmitContactAction -> public(active_read_only_or_suspended())
    public_action.LoginAction -> public(active_or_read_only())
    public_action.BeginPasskeyLoginAction -> public(active_or_read_only())
    public_action.FinishPasskeyLoginAction -> public(active_or_read_only())
    public_action.GetSessionAction -> public(active_read_only_or_suspended())
    public_action.RefreshSessionAction ->
      authenticated(active_read_only_or_suspended())
    public_action.LogoutAction -> authenticated(active_read_only_or_suspended())
    public_action.GetAccountAction -> authenticated(active_or_read_only())
    public_action.ListAccountSessionsAction ->
      authenticated(active_or_read_only())
    public_action.ListAccountPasskeysAction ->
      authenticated(active_or_read_only())
    public_action.UpdateAccountAction -> authenticated(active_only())
    public_action.BeginEmailChangeAction -> authenticated(active_only())
    public_action.ConfirmEmailChangeAction -> authenticated(active_only())
    public_action.DeleteAccountSessionAction -> authenticated(active_only())
    public_action.DeleteAccountPasskeyAction -> authenticated(active_only())
    public_action.BeginPasskeyRegistrationAction -> authenticated(active_only())
    public_action.FinishPasskeyRegistrationAction ->
      authenticated(active_only())
    public_action.ScheduleDeleteAccountAction -> authenticated(active_only())
    public_action.CancelDeleteAccountAction -> authenticated(active_only())
    public_action.GetSnippetAction -> public(active_or_read_only())
    public_action.ListPublicSnippetsAction -> public(active_or_read_only())
    public_action.ListSessionSnippetsAction ->
      authenticated(active_or_read_only())
    public_action.CreateSnippetAction -> authenticated(active_only())
    public_action.UpdateSnippetAction -> authenticated(active_only())
    public_action.DeleteSnippetAction -> authenticated(active_only())
    public_action.RunAction -> public(active_only())
  }
}

fn for_admin_action(_action: AdminAction) -> Policy {
  admin(active_or_read_only())
}

fn public(account_state: AccountStatePolicy) -> Policy {
  Policy(
    authentication: NoAuthenticationRequired,
    authorization: NoSpecialAuthorization,
    account_state: account_state,
  )
}

fn authenticated(account_state: AccountStatePolicy) -> Policy {
  Policy(
    authentication: RequireAuthentication,
    authorization: NoSpecialAuthorization,
    account_state: account_state,
  )
}

fn admin(account_state: AccountStatePolicy) -> Policy {
  Policy(
    authentication: RequireAuthentication,
    authorization: RequireAdmin,
    account_state: account_state,
  )
}

fn active_only() -> AccountStatePolicy {
  AllowedAccountStates([account_model.Active])
}

fn active_or_read_only() -> AccountStatePolicy {
  AllowedAccountStates([account_model.Active, account_model.ReadOnly])
}

fn active_read_only_or_suspended() -> AccountStatePolicy {
  AllowedAccountStates([
    account_model.Active,
    account_model.ReadOnly,
    account_model.Suspended,
  ])
}

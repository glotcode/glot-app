import glot_core/admin_action.{type AdminAction}
import glot_core/public_action.{type PublicAction}
import glot_frontend/api/transport

pub fn public(action: PublicAction) -> transport.Ownership {
  case action {
    public_action.RunAction -> transport.Run
    public_action.GetLanguageVersionAction
    | public_action.GetAccountAction
    | public_action.ListAccountSessionsAction
    | public_action.ListAccountPasskeysAction
    | public_action.GetSnippetAction
    | public_action.ListPublicSnippetsAction
    | public_action.ListSessionSnippetsAction -> transport.Navigation
    public_action.TrackPageviewAction
    | public_action.GetSessionAction
    | public_action.RefreshSessionAction
    | public_action.LogoutAction
    | public_action.UpdateAccountAction
    | public_action.BeginEmailChangeAction
    | public_action.ConfirmEmailChangeAction
    | public_action.DeleteAccountSessionAction
    | public_action.DeleteAccountPasskeyAction
    | public_action.ScheduleDeleteAccountAction
    | public_action.CancelDeleteAccountAction
    | public_action.CreateSnippetAction
    | public_action.UpdateSnippetAction
    | public_action.DeleteSnippetAction
    | public_action.SubmitContactAction
    | public_action.SendLoginTokenAction
    | public_action.LoginAction
    | public_action.BeginPasskeyRegistrationAction
    | public_action.FinishPasskeyRegistrationAction
    | public_action.BeginPasskeyLoginAction
    | public_action.FinishPasskeyLoginAction -> transport.Persistent
  }
}

pub fn admin(action: AdminAction) -> transport.Ownership {
  case action {
    admin_action.GetAdminAnalyticsAction
    | admin_action.GetAdminDebugConfigAction
    | admin_action.GetAdminAvailabilityConfigAction
    | admin_action.GetAdminAuthConfigAction
    | admin_action.GetAdminPasskeyConfigAction
    | admin_action.GetAdminCleanupConfigAction
    | admin_action.GetAdminLogWorkerConfigAction
    | admin_action.GetAdminHttpPoolConfigAction
    | admin_action.GetAdminLanguageVersionCacheWorkerConfigAction
    | admin_action.GetAdminPeriodicJobsAction
    | admin_action.GetAdminPeriodicJobAction
    | admin_action.GetAdminJobsAction
    | admin_action.GetAdminJobAction
    | admin_action.GetAdminEmailTemplatesAction
    | admin_action.GetAdminEmailTemplateAction
    | admin_action.GetAdminSnippetsAction
    | admin_action.GetAdminSnippetAction
    | admin_action.GetAdminUsersAction
    | admin_action.GetAdminUserAction
    | admin_action.GetAdminApiLogsAction
    | admin_action.GetAdminApiLogAction
    | admin_action.GetAdminRunLogsAction
    | admin_action.GetAdminRunLogAction
    | admin_action.GetAdminJobLogsAction
    | admin_action.GetAdminJobLogAction
    | admin_action.GetAdminRateLimitPoliciesAction
    | admin_action.GetAdminJobTypePoliciesAction
    | admin_action.GetAdminDockerRunConfigAction
    | admin_action.GetAdminSpamClassifierConfigAction
    | admin_action.GetAdminCloudflareConfigAction
    | admin_action.GetAdminEmailConfigAction -> transport.Navigation
    admin_action.UpsertAdminDebugConfigAction
    | admin_action.UpsertAdminAvailabilityConfigAction
    | admin_action.UpsertAdminAuthConfigAction
    | admin_action.UpsertAdminPasskeyConfigAction
    | admin_action.UpsertAdminCleanupConfigAction
    | admin_action.UpsertAdminLogWorkerConfigAction
    | admin_action.UpsertAdminHttpPoolConfigAction
    | admin_action.UpsertAdminLanguageVersionCacheWorkerConfigAction
    | admin_action.UpdateAdminPeriodicJobAction
    | admin_action.CreateAdminJobAction
    | admin_action.UpdateAdminEmailTemplateAction
    | admin_action.ClassifyAdminSnippetAction
    | admin_action.DeleteAdminSnippetAction
    | admin_action.UpdateAdminUserAction
    | admin_action.DeleteAdminAccountAction
    | admin_action.UpsertAdminRateLimitPolicyAction
    | admin_action.UpsertAdminJobTypePolicyAction
    | admin_action.UpsertAdminDockerRunConfigAction
    | admin_action.UpsertAdminCloudflareConfigAction
    | admin_action.UpsertAdminEmailConfigAction
    | admin_action.UpsertAdminSpamClassifierConfigAction -> transport.Persistent
  }
}

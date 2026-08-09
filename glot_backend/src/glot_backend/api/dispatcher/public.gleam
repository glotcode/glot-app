import gleam/dynamic
import glot_backend/api/model/api_result.{type ApiResult}
import glot_backend/auth/domain/account/cancel_delete as cancel_delete_account_domain
import glot_backend/auth/domain/account/get as get_account_domain
import glot_backend/auth/domain/account/schedule_delete as schedule_delete_account_domain
import glot_backend/auth/domain/account/update as update_account_domain
import glot_backend/auth/domain/email_change/begin as begin_email_change_domain
import glot_backend/auth/domain/email_change/confirm as confirm_email_change_domain
import glot_backend/auth/domain/login_token/login as login_domain
import glot_backend/auth/domain/login_token/send as send_login_token_domain
import glot_backend/auth/domain/passkey/begin_login as begin_passkey_login_domain
import glot_backend/auth/domain/passkey/begin_registration as begin_passkey_registration_domain
import glot_backend/auth/domain/passkey/delete as delete_account_passkey_domain
import glot_backend/auth/domain/passkey/finish_login as finish_passkey_login_domain
import glot_backend/auth/domain/passkey/finish_registration as finish_passkey_registration_domain
import glot_backend/auth/domain/passkey/list as list_account_passkeys_domain
import glot_backend/auth/domain/session/delete as delete_account_session_domain
import glot_backend/auth/domain/session/get as get_session_domain
import glot_backend/auth/domain/session/list as list_account_sessions_domain
import glot_backend/auth/domain/session/logout as logout_domain
import glot_backend/auth/domain/session/refresh as refresh_session_domain
import glot_backend/contact/domain/submit as submit_contact_domain
import glot_backend/logging/pageview/domain/track as track_pageview_domain
import glot_backend/run_code/domain/get_language_version as get_language_version_domain
import glot_backend/run_code/domain/run as run_domain
import glot_backend/snippet/domain/create as create_snippet_domain
import glot_backend/snippet/domain/delete as delete_snippet_domain
import glot_backend/snippet/domain/get as get_snippet_domain
import glot_backend/snippet/domain/list_public as list_public_snippets_domain
import glot_backend/snippet/domain/list_session as list_session_snippets_domain
import glot_backend/snippet/domain/update as update_snippet_domain
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types
import glot_backend/system/request/hydrated_context as request_context
import glot_core/public_action.{type PublicAction}

pub fn dispatch(
  request_ctx: request_context.RequestContext,
  action: PublicAction,
  data: dynamic.Dynamic,
) -> program_types.Program(ApiResult) {
  let ctx = request_ctx.context
  case action {
    public_action.TrackPageviewAction -> {
      use request <- program.and_then(
        track_pageview_domain.request_from_dynamic(data),
      )
      track_pageview_domain.track_pageview(request_ctx, request)
      |> program.map(api_result.TrackPageviewResponse)
    }
    public_action.RunAction -> {
      use request <- program.and_then(run_domain.request_from_dynamic(data))
      run_domain.run(request_ctx, request)
      |> program.map(api_result.RunResultResponse)
    }
    public_action.GetLanguageVersionAction -> {
      use request <- program.and_then(
        get_language_version_domain.request_from_dynamic(data),
      )
      get_language_version_domain.get_language_version(request_ctx, request)
      |> program.map(api_result.RunResultResponse)
    }
    public_action.GetSessionAction ->
      get_session_domain.get_session(request_ctx)
      |> program.map(api_result.SessionResponse)
    public_action.RefreshSessionAction ->
      refresh_session_domain.refresh_session(request_ctx)
      |> program.map(api_result.RefreshSessionResponse)
    public_action.LogoutAction ->
      logout_domain.logout(request_ctx)
      |> program.map(fn(_) { api_result.LogoutResponse })
    public_action.GetAccountAction ->
      get_account_domain.get_account(request_ctx)
      |> program.map(api_result.AccountResponse)
    public_action.ListAccountSessionsAction ->
      list_account_sessions_domain.list_account_sessions(request_ctx)
      |> program.map(api_result.ListAccountSessionsResponse)
    public_action.ListAccountPasskeysAction ->
      list_account_passkeys_domain.list_account_passkeys(request_ctx)
      |> program.map(api_result.AccountPasskeysResponse)
    public_action.UpdateAccountAction -> {
      use request <- program.and_then(
        update_account_domain.request_from_dynamic(data),
      )
      update_account_domain.update_account(request_ctx, request)
      |> program.map(api_result.AccountResponse)
    }
    public_action.BeginEmailChangeAction -> {
      use request <- program.and_then(
        begin_email_change_domain.request_from_dynamic(request_ctx, data),
      )
      begin_email_change_domain.begin_email_change(request_ctx, request)
      |> program.map(fn(_) { api_result.NoContentResponse })
    }
    public_action.ConfirmEmailChangeAction -> {
      use request <- program.and_then(
        confirm_email_change_domain.request_from_dynamic(data),
      )
      confirm_email_change_domain.confirm_email_change(request_ctx, request)
      |> program.map(api_result.AccountResponse)
    }
    public_action.DeleteAccountPasskeyAction -> {
      use request <- program.and_then(
        delete_account_passkey_domain.request_from_dynamic(data),
      )
      delete_account_passkey_domain.delete_account_passkey(request_ctx, request)
      |> program.map(fn(_) { api_result.NoContentResponse })
    }
    public_action.DeleteAccountSessionAction -> {
      use request <- program.and_then(
        delete_account_session_domain.request_from_dynamic(data),
      )
      delete_account_session_domain.delete_account_session(request_ctx, request)
      |> program.map(fn(_) { api_result.NoContentResponse })
    }
    public_action.ScheduleDeleteAccountAction ->
      schedule_delete_account_domain.schedule_delete_account(request_ctx)
      |> program.map(fn(_) { api_result.NoContentResponse })
    public_action.CancelDeleteAccountAction ->
      cancel_delete_account_domain.cancel_delete_account(request_ctx)
      |> program.map(fn(_) { api_result.NoContentResponse })
    public_action.GetSnippetAction -> {
      use request <- program.and_then(get_snippet_domain.request_from_dynamic(
        data,
      ))
      get_snippet_domain.get_snippet(request_ctx, request)
      |> program.map(api_result.SnippetResponse)
    }
    public_action.ListPublicSnippetsAction -> {
      use request <- program.and_then(
        list_public_snippets_domain.request_from_dynamic(data),
      )
      list_public_snippets_domain.list_public_snippets(request_ctx, request)
      |> program.map(api_result.SnippetsResponse)
    }
    public_action.ListSessionSnippetsAction -> {
      use request <- program.and_then(
        list_session_snippets_domain.request_from_dynamic(data),
      )
      list_session_snippets_domain.list_session_snippets(request_ctx, request)
      |> program.map(api_result.SnippetsResponse)
    }
    public_action.CreateSnippetAction -> {
      use request <- program.and_then(
        create_snippet_domain.request_from_dynamic(data),
      )
      create_snippet_domain.create_snippet(request_ctx, request)
      |> program.map(api_result.SnippetResponse)
    }
    public_action.UpdateSnippetAction -> {
      use request <- program.and_then(
        update_snippet_domain.request_from_dynamic(data),
      )
      update_snippet_domain.update_snippet(request_ctx, request)
      |> program.map(api_result.SnippetResponse)
    }
    public_action.DeleteSnippetAction -> {
      use request <- program.and_then(
        delete_snippet_domain.request_from_dynamic(data),
      )
      delete_snippet_domain.delete_snippet(request_ctx, request)
      |> program.map(fn(_) { api_result.NoContentResponse })
    }
    public_action.SubmitContactAction -> {
      use request <- program.and_then(
        submit_contact_domain.request_from_dynamic(data),
      )
      submit_contact_domain.submit_contact(request_ctx, request)
      |> program.map(fn(_) { api_result.NoContentResponse })
    }
    public_action.SendLoginTokenAction -> {
      use request <- program.and_then(
        send_login_token_domain.request_from_dynamic(ctx, data),
      )
      send_login_token_domain.send_login_token(request_ctx, request)
      |> program.map(fn(_) { api_result.NoContentResponse })
    }
    public_action.LoginAction -> {
      use request <- program.and_then(login_domain.request_from_dynamic(
        ctx,
        data,
      ))
      login_domain.login(request_ctx, request)
      |> program.map(api_result.LoginResponse)
    }
    public_action.BeginPasskeyRegistrationAction ->
      begin_passkey_registration_domain.begin_passkey_registration(request_ctx)
      |> program.map(api_result.BeginPasskeyRegistrationResponse)
    public_action.FinishPasskeyRegistrationAction -> {
      use request <- program.and_then(
        finish_passkey_registration_domain.request_from_dynamic(data),
      )
      finish_passkey_registration_domain.finish_passkey_registration(
        request_ctx,
        request,
      )
      |> program.map(fn(_) { api_result.NoContentResponse })
    }
    public_action.BeginPasskeyLoginAction -> {
      let _ = data
      begin_passkey_login_domain.begin_passkey_login(request_ctx)
      |> program.map(api_result.BeginPasskeyLoginResponse)
    }
    public_action.FinishPasskeyLoginAction -> {
      use request <- program.and_then(
        finish_passkey_login_domain.request_from_dynamic(data),
      )
      finish_passkey_login_domain.finish_passkey_login(request_ctx, request)
      |> program.map(api_result.FinishPasskeyLoginResponse)
    }
  }
}

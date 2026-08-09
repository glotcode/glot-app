import glot_backend/auth/ports/account_store.{type AccountStore}
import glot_backend/auth/ports/email_change_token_store.{
  type EmailChangeTokenStore,
}
import glot_backend/auth/ports/login_token_store.{type LoginTokenStore}
import glot_backend/auth/ports/passkey_store.{type PasskeyStore}
import glot_backend/auth/ports/session_store.{type SessionStore}
import glot_backend/auth/ports/user_store.{type UserStore}

pub type Ports {
  Ports(
    accounts: AccountStore,
    users: UserStore,
    sessions: SessionStore,
    login_tokens: LoginTokenStore,
    passkeys: PasskeyStore,
    email_change_tokens: EmailChangeTokenStore,
  )
}

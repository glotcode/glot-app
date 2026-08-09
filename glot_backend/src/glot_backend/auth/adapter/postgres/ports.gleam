import glot_backend/auth/adapter/postgres/account_store
import glot_backend/auth/adapter/postgres/email_change_token_store
import glot_backend/auth/adapter/postgres/login_token_store
import glot_backend/auth/adapter/postgres/passkey_store
import glot_backend/auth/adapter/postgres/session/store as session_store
import glot_backend/auth/adapter/postgres/user/store as user_store
import glot_backend/auth/ports
import glot_backend/system/database as db_helpers

pub fn new(db: db_helpers.Db) -> ports.Ports {
  ports.Ports(
    accounts: account_store.new(db),
    users: user_store.new(db),
    sessions: session_store.new(db),
    login_tokens: login_token_store.new(db),
    passkeys: passkey_store.new(db),
    email_change_tokens: email_change_token_store.new(db),
  )
}

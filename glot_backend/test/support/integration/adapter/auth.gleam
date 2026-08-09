import glot_backend/auth/ports
import glot_backend/auth/ports/account_store
import glot_backend/auth/ports/email_change_token_store
import glot_backend/auth/ports/login_token_store
import glot_backend/auth/ports/passkey_store
import glot_backend/auth/ports/session_store
import glot_backend/auth/ports/user_store
import support/integration/adapter/state
import support/integration/adapter/unexpected
import support/integration/store/auth

pub fn defaults() -> ports.Ports {
  ports.Ports(
    accounts: account_store.AccountStore(
      create: fn(_) { unexpected.command("auth.accounts.create") },
      update: fn(_) { unexpected.command("auth.accounts.update") },
      delete: fn(_) { unexpected.command("auth.accounts.delete") },
    ),
    users: user_store.UserStore(
      get_by_email: fn(_, _) { unexpected.query("auth.users.get_by_email") },
      get_by_id: fn(_, _) { unexpected.query("auth.users.get_by_id") },
      get_by_id_for_update: fn(_, _) {
        unexpected.query("auth.users.get_by_id_for_update")
      },
      list: fn(_, _, _) { unexpected.query("auth.users.list") },
      create: fn(_) { unexpected.command("auth.users.create") },
      update_last_login: fn(_, _) {
        unexpected.command("auth.users.update_last_login")
      },
      update_email: fn(_, _, _) {
        unexpected.command("auth.users.update_email")
      },
      update_username: fn(_, _, _) {
        unexpected.command("auth.users.update_username")
      },
      update_role: fn(_, _, _) { unexpected.command("auth.users.update_role") },
      lock_email: fn(_) { unexpected.command("auth.users.lock_email") },
      delete_by_account_id: fn(_) {
        unexpected.command("auth.users.delete_by_account_id")
      },
    ),
    sessions: session_store.SessionStore(
      list_by_user_id: fn(_, _, _) {
        unexpected.query("auth.sessions.list_by_user_id")
      },
      get_by_token: fn(_, _) { unexpected.query("auth.sessions.get_by_token") },
      get_by_token_for_update: fn(_) {
        unexpected.query("auth.sessions.get_by_token_for_update")
      },
      get_by_previous_token: fn(_, _) {
        unexpected.query("auth.sessions.get_by_previous_token")
      },
      get_by_previous_token_for_update: fn(_) {
        unexpected.query("auth.sessions.get_by_previous_token_for_update")
      },
      create: fn(_) { unexpected.command("auth.sessions.create") },
      update: fn(_) { unexpected.command("auth.sessions.update") },
      delete: fn(_) { unexpected.command("auth.sessions.delete") },
      delete_by_account_id: fn(_) {
        unexpected.command("auth.sessions.delete_by_account_id")
      },
      delete_expired: fn(_, _) {
        unexpected.command("auth.sessions.delete_expired")
      },
    ),
    login_tokens: login_token_store.LoginTokenStore(
      list_by_email: fn(_, _, _) {
        unexpected.query("auth.login_tokens.list_by_email")
      },
      create: fn(_) { unexpected.command("auth.login_tokens.create") },
      update: fn(_) { unexpected.command("auth.login_tokens.update") },
      delete_before: fn(_) {
        unexpected.command("auth.login_tokens.delete_before")
      },
      invalidate_by_emails: fn(_, _, _) {
        unexpected.command("auth.login_tokens.invalidate_by_emails")
      },
    ),
    passkeys: passkey_store.PasskeyStore(
      get_credential_by_credential_id: fn(_) {
        unexpected.query("auth.passkeys.get_credential_by_credential_id")
      },
      list_credentials_by_user_id: fn(_) {
        unexpected.query("auth.passkeys.list_credentials_by_user_id")
      },
      get_challenge_by_id: fn(_) {
        unexpected.query("auth.passkeys.get_challenge_by_id")
      },
      create_credential: fn(_) {
        unexpected.command("auth.passkeys.create_credential")
      },
      update_credential: fn(_) {
        unexpected.command("auth.passkeys.update_credential")
      },
      delete_credential: fn(_) {
        unexpected.command("auth.passkeys.delete_credential")
      },
      create_challenge: fn(_) {
        unexpected.command("auth.passkeys.create_challenge")
      },
      delete_challenge: fn(_) {
        unexpected.command("auth.passkeys.delete_challenge")
      },
    ),
    email_change_tokens: email_change_token_store.EmailChangeTokenStore(
      list_by_user_id: fn(_, _, _) {
        unexpected.query("auth.email_change_tokens.list_by_user_id")
      },
      list_by_user_id_for_update: fn(_, _, _) {
        unexpected.query("auth.email_change_tokens.list_by_user_id_for_update")
      },
      create: fn(_) { unexpected.command("auth.email_change_tokens.create") },
      update: fn(_) { unexpected.command("auth.email_change_tokens.update") },
      delete_before: fn(_) {
        unexpected.command("auth.email_change_tokens.delete_before")
      },
    ),
  )
}

pub fn new(test_state: state.State) -> ports.Ports {
  ports.Ports(
    accounts: accounts(test_state),
    users: users(test_state),
    sessions: sessions(test_state),
    login_tokens: login_tokens(test_state),
    passkeys: passkeys(test_state),
    email_change_tokens: email_change_tokens(test_state),
  )
}

fn accounts(test_state: state.State) -> account_store.AccountStore {
  account_store.AccountStore(
    create: fn(value) {
      state.update(test_state, fn(db) { auth.insert_account(db, value) })
      Ok(Nil)
    },
    update: fn(value) {
      state.update(test_state, fn(db) { auth.insert_account(db, value) })
      Ok(Nil)
    },
    delete: fn(id) {
      state.update(test_state, fn(db) { auth.delete_account_by_id(db, id) })
      Ok(Nil)
    },
  )
}

fn users(test_state: state.State) -> user_store.UserStore {
  user_store.UserStore(
    get_by_email: fn(_, email) {
      Ok(auth.find_user_by_email(state.get(test_state), email))
    },
    get_by_id: fn(_, id) { Ok(auth.find_user_by_id(state.get(test_state), id)) },
    get_by_id_for_update: fn(_, id) {
      Ok(auth.find_user_by_id(state.get(test_state), id))
    },
    list: fn(_, pagination, filters) {
      Ok(auth.find_users(state.get(test_state), pagination, filters))
    },
    create: fn(value) {
      state.update(test_state, fn(db) { auth.insert_user(db, value) })
      Ok(Nil)
    },
    update_last_login: fn(id, timestamp) {
      state.update(test_state, fn(db) {
        auth.update_user_last_login(db, id, timestamp)
      })
      Ok(Nil)
    },
    update_email: fn(id, email, timestamp) {
      state.update(test_state, fn(db) {
        auth.update_user_email(db, id, email, timestamp)
      })
      Ok(Nil)
    },
    update_username: fn(id, username, timestamp) {
      state.update(test_state, fn(db) {
        auth.update_user_username(db, id, username, timestamp)
      })
      Ok(Nil)
    },
    update_role: fn(id, role, timestamp) {
      state.update(test_state, fn(db) {
        auth.update_user_role(db, id, role, timestamp)
      })
      Ok(Nil)
    },
    lock_email: fn(_) { Ok(Nil) },
    delete_by_account_id: fn(account_id) {
      state.update(test_state, fn(db) {
        auth.delete_users_by_account_id(db, account_id)
      })
      Ok(Nil)
    },
  )
}

fn sessions(test_state: state.State) -> session_store.SessionStore {
  session_store.SessionStore(
    list_by_user_id: fn(user_id, created_since, last_activity_since) {
      let db = state.get(test_state)
      Ok(auth.find_sessions_by_user_id(
        db,
        user_id,
        created_since,
        last_activity_since,
      ))
    },
    get_by_token: fn(_, token) {
      Ok(auth.find_hydrated_session_by_current_token(
        state.get(test_state),
        token,
      ))
    },
    get_by_token_for_update: fn(token) {
      Ok(auth.find_session_by_current_token(state.get(test_state), token))
    },
    get_by_previous_token: fn(_, token) {
      Ok(auth.find_hydrated_session_by_previous_token(
        state.get(test_state),
        token,
      ))
    },
    get_by_previous_token_for_update: fn(token) {
      Ok(auth.find_session_by_previous_token(state.get(test_state), token))
    },
    create: fn(value) {
      state.update(test_state, fn(db) { auth.insert_session(db, value) })
      Ok(Nil)
    },
    update: fn(value) {
      state.update(test_state, fn(db) { auth.update_session(db, value) })
      Ok(Nil)
    },
    delete: fn(id) {
      state.update(test_state, fn(db) { auth.delete_session_by_id(db, id) })
      Ok(Nil)
    },
    delete_by_account_id: fn(account_id) {
      state.update(test_state, fn(db) {
        auth.delete_sessions_by_account_id(db, account_id)
      })
      Ok(Nil)
    },
    delete_expired: fn(created_before, last_activity_before) {
      state.update(test_state, fn(db) {
        auth.delete_expired_sessions(db, created_before, last_activity_before)
      })
      Ok(Nil)
    },
  )
}

fn login_tokens(test_state: state.State) -> login_token_store.LoginTokenStore {
  login_token_store.LoginTokenStore(
    list_by_email: fn(email, created_since, limit) {
      Ok(auth.find_login_tokens_by_email(
        state.get(test_state),
        email,
        created_since,
        limit,
      ))
    },
    create: fn(value) {
      state.update(test_state, fn(db) { auth.upsert_login_token(db, value) })
      Ok(Nil)
    },
    update: fn(value) {
      state.update(test_state, fn(db) { auth.upsert_login_token(db, value) })
      Ok(Nil)
    },
    delete_before: fn(before) {
      state.update(test_state, fn(db) {
        auth.delete_login_tokens_before(db, before)
      })
      Ok(Nil)
    },
    invalidate_by_emails: fn(old_email, new_email, timestamp) {
      state.update(test_state, fn(db) {
        auth.invalidate_login_tokens(db, old_email, new_email, timestamp)
      })
      Ok(Nil)
    },
  )
}

fn email_change_tokens(
  test_state: state.State,
) -> email_change_token_store.EmailChangeTokenStore {
  email_change_token_store.EmailChangeTokenStore(
    list_by_user_id: fn(user_id, created_since, limit) {
      Ok(auth.find_email_change_tokens_by_user_id(
        state.get(test_state),
        user_id,
        created_since,
        limit,
      ))
    },
    list_by_user_id_for_update: fn(user_id, created_since, limit) {
      Ok(auth.find_email_change_tokens_by_user_id(
        state.get(test_state),
        user_id,
        created_since,
        limit,
      ))
    },
    create: fn(token) {
      state.update(test_state, fn(db) {
        auth.upsert_email_change_token(db, token)
      })
      Ok(Nil)
    },
    update: fn(token) {
      state.update(test_state, fn(db) {
        auth.upsert_email_change_token(db, token)
      })
      Ok(Nil)
    },
    delete_before: fn(before) {
      state.update(test_state, fn(db) {
        auth.delete_email_change_tokens_before(db, before)
      })
      Ok(Nil)
    },
  )
}

fn passkeys(test_state: state.State) -> passkey_store.PasskeyStore {
  passkey_store.PasskeyStore(
    get_credential_by_credential_id: fn(id) {
      Ok(auth.find_passkey_credential_by_credential_id(
        state.get(test_state),
        id,
      ))
    },
    list_credentials_by_user_id: fn(user_id) {
      Ok(auth.find_passkey_credentials_by_user_id(
        state.get(test_state),
        user_id,
      ))
    },
    get_challenge_by_id: fn(id) {
      Ok(auth.find_passkey_challenge_by_id(state.get(test_state), id))
    },
    create_credential: fn(value) {
      state.update(test_state, fn(db) {
        auth.upsert_passkey_credential(db, value)
      })
      Ok(Nil)
    },
    update_credential: fn(value) {
      state.update(test_state, fn(db) {
        auth.upsert_passkey_credential(db, value)
      })
      Ok(Nil)
    },
    delete_credential: fn(id) {
      state.update(test_state, fn(db) {
        auth.delete_passkey_credential_by_id(db, id)
      })
      Ok(Nil)
    },
    create_challenge: fn(value) {
      state.update(test_state, fn(db) {
        auth.upsert_passkey_challenge(db, value)
      })
      Ok(Nil)
    },
    delete_challenge: fn(id) {
      state.update(test_state, fn(db) {
        auth.delete_passkey_challenge_by_id(db, id)
      })
      Ok(Nil)
    },
  )
}

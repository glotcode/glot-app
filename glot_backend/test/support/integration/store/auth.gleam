import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option
import gleam/order
import gleam/string
import gleam/time/timestamp
import glot_backend/auth/model/user_list_filters.{type UserListFilters}
import glot_core/auth/account_model
import glot_core/auth/email_change_token_model
import glot_core/auth/login_token_model
import glot_core/auth/passkey_challenge_model
import glot_core/auth/passkey_credential_model
import glot_core/auth/session_model
import glot_core/auth/user_model
import glot_core/email/email_address_model
import glot_core/helpers/timestamp_helpers
import glot_core/pagination_model
import support/integration/model
import support/integration/store/common
import youid/uuid

pub fn find_user_by_email(
  db: model.TestState,
  email: email_address_model.EmailAddress,
) -> option.Option(user_model.HydratedUser) {
  case
    db.users
    |> dict.to_list
    |> list.find(fn(entry) {
      let #(_, user) = entry
      user.email == email
    })
    |> option.from_result()
  {
    option.Some(entry) -> {
      let #(_, user) = entry
      db.accounts
      |> dict.get(common.uuid_key(user.account_id))
      |> option.from_result()
      |> option.map(fn(account) {
        user_model.HydratedUser(
          identity: user,
          account: account_model.HydratedAccount(
            identity: account,
            delete_scheduled_at: option.None,
          ),
        )
      })
    }
    option.None -> option.None
  }
}

pub fn find_user_by_id(
  db: model.TestState,
  id: uuid.Uuid,
) -> option.Option(user_model.HydratedUser) {
  case dict.get(db.users, common.uuid_key(id)) {
    Ok(user) ->
      db.accounts
      |> dict.get(common.uuid_key(user.account_id))
      |> option.from_result()
      |> option.map(fn(account) {
        user_model.HydratedUser(
          identity: user,
          account: account_model.HydratedAccount(
            identity: account,
            delete_scheduled_at: option.None,
          ),
        )
      })
    Error(_) -> option.None
  }
}

pub fn update_user_last_login(
  db: model.TestState,
  id: uuid.Uuid,
  now: timestamp.Timestamp,
) -> model.TestState {
  case dict.get(db.users, common.uuid_key(id)) {
    Error(_) -> db
    Ok(user) -> insert_user(db, user_model.mark_last_login(user, now))
  }
}

pub fn update_user_email(db, id, email, now) -> model.TestState {
  update_user_if_present(
    db,
    id,
    fn(user) { user_model.change_email(user, email, now) },
    "update_user_email",
  )
}

pub fn update_user_username(db, id, username, now) -> model.TestState {
  update_user_if_present(
    db,
    id,
    fn(user) { user_model.change_username(user, username, now) },
    "update_user_username",
  )
}

pub fn update_user_role(db, id, role, now) -> model.TestState {
  update_user_if_present(
    db,
    id,
    fn(user) { user_model.change_role(user, role, now) },
    "update_user_role",
  )
}

fn update_user_if_present(
  db: model.TestState,
  id: uuid.Uuid,
  change: fn(user_model.User) -> user_model.User,
  step: String,
) -> model.TestState {
  case dict.get(db.users, common.uuid_key(id)) {
    Error(_) -> db
    Ok(user) ->
      model.TestState(
        ..db,
        users: dict.insert(db.users, common.uuid_key(id), change(user)),
        write_steps: [step, ..db.write_steps],
      )
  }
}

pub fn find_email_change_tokens_by_user_id(
  db: model.TestState,
  user_id: uuid.Uuid,
  created_since: timestamp.Timestamp,
  limit: Int,
) -> List(email_change_token_model.EmailChangeToken) {
  db.email_change_tokens
  |> dict.to_list
  |> list.filter(fn(entry) {
    let token = entry.1
    token.user_id == user_id
    && token.used_at == option.None
    && timestamp_helpers.to_microseconds(token.created_at)
    >= timestamp_helpers.to_microseconds(created_since)
  })
  |> list.map(fn(entry) { entry.1 })
  |> list.sort(fn(a, b) {
    newest_token_order(a.created_at, a.id, b.created_at, b.id)
  })
  |> list.take(limit)
}

pub fn upsert_email_change_token(
  db: model.TestState,
  token: email_change_token_model.EmailChangeToken,
) -> model.TestState {
  model.TestState(
    ..db,
    email_change_tokens: dict.insert(
      db.email_change_tokens,
      common.uuid_key(token.id),
      token,
    ),
    write_steps: ["upsert_email_change_token", ..db.write_steps],
  )
}

pub fn delete_email_change_tokens_before(
  db: model.TestState,
  before: timestamp.Timestamp,
) -> model.TestState {
  let tokens =
    dict.filter(db.email_change_tokens, fn(_, token) {
      timestamp_helpers.to_microseconds(token.created_at)
      >= timestamp_helpers.to_microseconds(before)
    })
  model.TestState(..db, email_change_tokens: tokens, deletion_steps: [
    "delete_email_change_tokens_before",
    ..db.deletion_steps
  ])
}

pub fn invalidate_login_tokens(
  db: model.TestState,
  old_email: email_address_model.EmailAddress,
  new_email: email_address_model.EmailAddress,
  now: timestamp.Timestamp,
) -> model.TestState {
  let login_tokens =
    db.login_tokens
    |> dict.map_values(fn(_, token) {
      case
        token.used_at == option.None
        && { token.email == old_email || token.email == new_email }
      {
        True -> login_token_model.mark_as_used(token, now)
        False -> token
      }
    })
  model.TestState(..db, login_tokens:, write_steps: [
    "invalidate_login_tokens",
    ..db.write_steps
  ])
}

pub fn find_users(
  db: model.TestState,
  pagination: pagination_model.CursorPagination,
  _filters: UserListFilters,
) -> List(user_model.HydratedUser) {
  let users =
    db.users
    |> dict.to_list
    |> list.sort(fn(a, b) {
      case string.compare(a.0, b.0) {
        order.Lt -> order.Gt
        order.Eq -> order.Eq
        order.Gt -> order.Lt
      }
    })
    |> list.map(fn(entry) { entry.1 })
    |> list.map(fn(user) {
      let assert Ok(account) =
        dict.get(db.accounts, common.uuid_key(user.account_id))
      user_model.HydratedUser(
        identity: user,
        account: account_model.HydratedAccount(
          identity: account,
          delete_scheduled_at: option.None,
        ),
      )
    })

  case pagination {
    pagination_model.InitialPage(limit) -> take_users(users, limit)
    pagination_model.AfterPage(cursor, limit) ->
      users
      |> list.filter(fn(user) {
        string.compare(
          common.uuid_key(user.identity.id),
          pagination_model.to_string(cursor),
        )
        == order.Lt
      })
      |> take_users(limit)
    pagination_model.BeforePage(cursor, limit) ->
      users
      |> list.filter(fn(user) {
        string.compare(
          common.uuid_key(user.identity.id),
          pagination_model.to_string(cursor),
        )
        == order.Gt
      })
      |> list.reverse
      |> take_users(limit)
      |> list.reverse
  }
}

fn take_users(
  users: List(user_model.HydratedUser),
  limit: Int,
) -> List(user_model.HydratedUser) {
  case limit <= 0 {
    True -> []
    False ->
      case users {
        [] -> []
        [first, ..rest] -> [first, ..take_users(rest, limit - 1)]
      }
  }
}

pub fn find_login_tokens_by_email(
  db: model.TestState,
  email: email_address_model.EmailAddress,
  created_since: timestamp.Timestamp,
  limit: Int,
) -> List(login_token_model.LoginToken) {
  db.login_tokens
  |> dict.to_list
  |> list.filter(fn(entry) {
    let #(_, login_token) = entry
    login_token.email == email
    && login_token.used_at == option.None
    && timestamp_helpers.to_microseconds(login_token.created_at)
    >= timestamp_helpers.to_microseconds(created_since)
  })
  |> list.map(fn(entry) {
    let #(_, login_token) = entry
    login_token
  })
  |> list.sort(fn(a, b) {
    newest_token_order(a.created_at, a.id, b.created_at, b.id)
  })
  |> list.take(limit)
}

fn newest_token_order(a_created_at, a_id, b_created_at, b_id) {
  case
    int.compare(
      timestamp_helpers.to_microseconds(b_created_at),
      timestamp_helpers.to_microseconds(a_created_at),
    )
  {
    order.Eq -> string.compare(common.uuid_key(b_id), common.uuid_key(a_id))
    ordering -> ordering
  }
}

pub fn find_passkey_credential_by_credential_id(
  db: model.TestState,
  credential_id: BitArray,
) -> option.Option(passkey_credential_model.PasskeyCredential) {
  db.passkey_credentials
  |> dict.to_list
  |> list.find(fn(entry) {
    let #(_, credential) = entry
    credential.credential_id == credential_id
  })
  |> option.from_result()
  |> option.map(fn(entry) { entry.1 })
}

pub fn find_passkey_credentials_by_user_id(
  db: model.TestState,
  user_id: uuid.Uuid,
) -> List(passkey_credential_model.PasskeyCredential) {
  db.passkey_credentials
  |> dict.to_list
  |> list.filter(fn(entry) { entry.1.user_id == user_id })
  |> list.map(fn(entry) { entry.1 })
}

pub fn find_sessions_by_user_id(
  db: model.TestState,
  user_id: uuid.Uuid,
  created_since: timestamp.Timestamp,
  last_activity_since: timestamp.Timestamp,
) -> List(session_model.Session) {
  db.sessions
  |> dict.to_list
  |> list.filter(fn(entry) {
    let session = entry.1
    session.user_id == user_id
    && timestamp_helpers.to_microseconds(session.created_at)
    >= timestamp_helpers.to_microseconds(created_since)
    && timestamp_helpers.to_microseconds(session.last_activity_at)
    >= timestamp_helpers.to_microseconds(last_activity_since)
  })
  |> list.map(fn(entry) { entry.1 })
}

pub fn find_passkey_challenge_by_id(
  db: model.TestState,
  id: uuid.Uuid,
) -> option.Option(passkey_challenge_model.PasskeyChallenge) {
  db.passkey_challenges
  |> dict.get(common.uuid_key(id))
  |> option.from_result()
}

pub fn find_hydrated_session(
  db: model.TestState,
  token: String,
  now: timestamp.Timestamp,
) -> option.Option(session_model.HydratedSession) {
  case find_session_by_token(db, token, now) {
    option.Some(session) ->
      case dict.get(db.users, common.uuid_key(session.user_id)) {
        Ok(user) ->
          case dict.get(db.accounts, common.uuid_key(user.account_id)) {
            Ok(account) ->
              option.Some(session_model.HydratedSession(
                identity: session,
                user: user_model.HydratedUser(
                  identity: user,
                  account: account_model.HydratedAccount(
                    identity: account,
                    delete_scheduled_at: option.None,
                  ),
                ),
              ))
            Error(_) -> option.None
          }
        Error(_) -> option.None
      }
    option.None -> option.None
  }
}

pub fn find_hydrated_session_by_current_token(
  db: model.TestState,
  token: String,
) -> option.Option(session_model.HydratedSession) {
  case dict.get(db.session_ids_by_token, token) {
    Ok(session_id) ->
      case dict.get(db.sessions, session_id) {
        Ok(session) -> hydrate_session(db, session)
        Error(_) -> option.None
      }
    Error(_) -> option.None
  }
}

pub fn find_session_by_current_token(
  db: model.TestState,
  token: String,
) -> option.Option(session_model.Session) {
  case dict.get(db.session_ids_by_token, token) {
    Ok(session_id) -> dict.get(db.sessions, session_id) |> option.from_result
    Error(_) -> option.None
  }
}

pub fn find_hydrated_session_by_previous_token(
  db: model.TestState,
  token: String,
) -> option.Option(session_model.HydratedSession) {
  case find_session_by_previous_token(db, token) {
    option.Some(session) -> hydrate_session(db, session)
    option.None -> option.None
  }
}

pub fn find_session_by_previous_token(
  db: model.TestState,
  token: String,
) -> option.Option(session_model.Session) {
  db.sessions
  |> dict.to_list
  |> list.find(fn(entry) { entry.1.previous_token == option.Some(token) })
  |> option.from_result
  |> option.map(fn(entry) { entry.1 })
}

fn hydrate_session(
  db: model.TestState,
  session: session_model.Session,
) -> option.Option(session_model.HydratedSession) {
  case dict.get(db.users, common.uuid_key(session.user_id)) {
    Error(_) -> option.None
    Ok(user) ->
      case dict.get(db.accounts, common.uuid_key(user.account_id)) {
        Error(_) -> option.None
        Ok(account) ->
          option.Some(session_model.HydratedSession(
            identity: session,
            user: user_model.HydratedUser(
              identity: user,
              account: account_model.HydratedAccount(
                identity: account,
                delete_scheduled_at: option.None,
              ),
            ),
          ))
      }
  }
}

pub fn find_session_by_token(
  db: model.TestState,
  token: String,
  now: timestamp.Timestamp,
) -> option.Option(session_model.Session) {
  case dict.get(db.session_ids_by_token, token) {
    Ok(session_id) ->
      case dict.get(db.sessions, session_id) {
        Ok(session) -> option.Some(session)
        Error(_) -> option.None
      }
    Error(_) ->
      db.sessions
      |> dict.to_list
      |> list.find(fn(entry) {
        let #(_, session) = entry
        case session.previous_token, session.previous_token_valid_until {
          option.Some(previous_token), option.Some(valid_until) ->
            previous_token == token
            && timestamp_helpers.to_microseconds(valid_until)
            >= timestamp_helpers.to_microseconds(now)
          _, _ -> False
        }
      })
      |> option.from_result()
      |> option.map(fn(entry) {
        let #(_, session) = entry
        session
      })
  }
}

fn session_belongs_to_account(
  db: model.TestState,
  session: session_model.Session,
  account_id: uuid.Uuid,
) -> Bool {
  case dict.get(db.users, common.uuid_key(session.user_id)) {
    Ok(user) -> user.account_id == account_id
    Error(_) -> False
  }
}

pub fn insert_user(
  db: model.TestState,
  user: user_model.User,
) -> model.TestState {
  model.TestState(
    ..db,
    users: dict.insert(db.users, common.uuid_key(user.id), user),
    write_steps: ["create_user", ..db.write_steps],
  )
}

pub fn insert_account(
  db: model.TestState,
  account: account_model.Account,
) -> model.TestState {
  model.TestState(
    ..db,
    accounts: dict.insert(db.accounts, common.uuid_key(account.id), account),
    write_steps: ["create_account", ..db.write_steps],
  )
}

pub fn insert_session(
  db: model.TestState,
  session: session_model.Session,
) -> model.TestState {
  model.TestState(
    ..db,
    sessions: dict.insert(db.sessions, common.uuid_key(session.id), session),
    session_ids_by_token: dict.insert(
      db.session_ids_by_token,
      session.token,
      common.uuid_key(session.id),
    ),
    write_steps: ["create_session", ..db.write_steps],
  )
}

pub fn update_session(
  db: model.TestState,
  session: session_model.Session,
) -> model.TestState {
  let session_key = common.uuid_key(session.id)
  case dict.get(db.sessions, session_key) {
    Ok(previous_session) -> {
      model.TestState(
        ..db,
        sessions: dict.insert(db.sessions, session_key, session),
        session_ids_by_token: db.session_ids_by_token
          |> dict.delete(previous_session.token)
          |> dict.insert(session.token, session_key),
        write_steps: ["update_session", ..db.write_steps],
      )
    }
    Error(_) -> db
  }
}

pub fn upsert_login_token(
  db: model.TestState,
  login_token: login_token_model.LoginToken,
) -> model.TestState {
  model.TestState(
    ..db,
    login_tokens: dict.insert(
      db.login_tokens,
      common.uuid_key(login_token.id),
      login_token,
    ),
    write_steps: ["update_login_token", ..db.write_steps],
  )
}

pub fn upsert_passkey_credential(
  db: model.TestState,
  passkey_credential: passkey_credential_model.PasskeyCredential,
) -> model.TestState {
  model.TestState(
    ..db,
    passkey_credentials: dict.insert(
      db.passkey_credentials,
      common.uuid_key(passkey_credential.id),
      passkey_credential,
    ),
  )
}

pub fn upsert_passkey_challenge(
  db: model.TestState,
  passkey_challenge: passkey_challenge_model.PasskeyChallenge,
) -> model.TestState {
  model.TestState(
    ..db,
    passkey_challenges: dict.insert(
      db.passkey_challenges,
      common.uuid_key(passkey_challenge.id),
      passkey_challenge,
    ),
  )
}

pub fn delete_login_tokens_before(
  db: model.TestState,
  before: timestamp.Timestamp,
) -> model.TestState {
  let before_microseconds = timestamp_helpers.to_microseconds(before)
  let kept_login_tokens =
    db.login_tokens
    |> dict.to_list
    |> list.filter(fn(entry) {
      let #(_, login_token) = entry
      timestamp_helpers.to_microseconds(login_token.created_at)
      >= before_microseconds
    })
    |> dict.from_list

  model.TestState(..db, login_tokens: kept_login_tokens)
}

pub fn delete_sessions_by_account_id(
  db: model.TestState,
  account_id: uuid.Uuid,
) -> model.TestState {
  let kept_sessions =
    db.sessions
    |> dict.to_list
    |> list.filter(fn(entry) {
      let #(_, session) = entry
      !session_belongs_to_account(db, session, account_id)
    })
    |> dict.from_list
  let kept_session_ids_by_token =
    db.session_ids_by_token
    |> dict.to_list
    |> list.filter(fn(entry) {
      let #(_, session_id) = entry
      dict.has_key(kept_sessions, session_id)
    })
    |> dict.from_list

  model.TestState(
    ..db,
    sessions: kept_sessions,
    session_ids_by_token: kept_session_ids_by_token,
    deletion_steps: ["delete_sessions_by_account_id", ..db.deletion_steps],
  )
}

pub fn delete_expired_sessions(
  db: model.TestState,
  created_before: timestamp.Timestamp,
  last_activity_before: timestamp.Timestamp,
) -> model.TestState {
  let created_before_microseconds =
    timestamp_helpers.to_microseconds(created_before)
  let last_activity_before_microseconds =
    timestamp_helpers.to_microseconds(last_activity_before)
  let kept_sessions =
    db.sessions
    |> dict.to_list
    |> list.filter(fn(entry) {
      let #(_, session) = entry
      timestamp_helpers.to_microseconds(session.created_at)
      >= created_before_microseconds
      && timestamp_helpers.to_microseconds(session.last_activity_at)
      >= last_activity_before_microseconds
    })
    |> dict.from_list
  let kept_session_ids_by_token =
    db.session_ids_by_token
    |> dict.to_list
    |> list.filter(fn(entry) {
      let #(_, session_id) = entry
      dict.has_key(kept_sessions, session_id)
    })
    |> dict.from_list

  model.TestState(
    ..db,
    sessions: kept_sessions,
    session_ids_by_token: kept_session_ids_by_token,
  )
}

pub fn delete_users_by_account_id(
  db: model.TestState,
  account_id: uuid.Uuid,
) -> model.TestState {
  model.TestState(
    ..db,
    users: remove_users_by_account_id(db.users, account_id),
    deletion_steps: ["delete_users_by_account_id", ..db.deletion_steps],
  )
}

pub fn delete_account_by_id(
  db: model.TestState,
  account_id: uuid.Uuid,
) -> model.TestState {
  model.TestState(
    ..db,
    accounts: dict.delete(db.accounts, common.uuid_key(account_id)),
    deletion_steps: ["delete_account", ..db.deletion_steps],
  )
}

pub fn delete_session_by_id(
  db: model.TestState,
  id: uuid.Uuid,
) -> model.TestState {
  let session_key = common.uuid_key(id)
  let session_ids_by_token = case dict.get(db.sessions, session_key) {
    Ok(session) -> dict.delete(db.session_ids_by_token, session.token)
    Error(_) -> db.session_ids_by_token
  }

  model.TestState(
    ..db,
    sessions: dict.delete(db.sessions, session_key),
    session_ids_by_token: session_ids_by_token,
  )
}

pub fn delete_passkey_challenge_by_id(
  db: model.TestState,
  id: uuid.Uuid,
) -> model.TestState {
  model.TestState(
    ..db,
    passkey_challenges: dict.delete(db.passkey_challenges, common.uuid_key(id)),
  )
}

pub fn delete_passkey_credential_by_id(
  db: model.TestState,
  id: uuid.Uuid,
) -> model.TestState {
  model.TestState(
    ..db,
    passkey_credentials: dict.delete(
      db.passkey_credentials,
      common.uuid_key(id),
    ),
  )
}

fn remove_users_by_account_id(
  users: Dict(String, user_model.User),
  account_id: uuid.Uuid,
) -> Dict(String, user_model.User) {
  users
  |> dict.to_list
  |> list.filter(fn(entry) {
    let #(_, user) = entry
    user.account_id != account_id
  })
  |> dict.from_list
}

pub type AuthError {
  InvalidLoginToken
  LoginTokenUsed
  LoginTokenExpired
  PasskeyChallengeNotFound
  PasskeyChallengeExpired
  InvalidPasskeyAssertion
  MissingSessionToken
  SessionNotFound
  SessionExpired
  MissingUserIdAndIp
  AuthenticationRequired
  NotOwner
  AdminRequired
  InvalidEmailChangeToken
  EmailAlreadyInUse
  EmailUnchanged
  EmailChangeBlockedByPendingDeletion
}

pub fn status(err: AuthError) -> Int {
  case err {
    InvalidLoginToken
    | LoginTokenExpired
    | PasskeyChallengeNotFound
    | PasskeyChallengeExpired
    | InvalidPasskeyAssertion
    | MissingSessionToken
    | SessionNotFound
    | SessionExpired
    | AuthenticationRequired -> 401
    LoginTokenUsed -> 409
    NotOwner | AdminRequired -> 403
    InvalidEmailChangeToken -> 400
    EmailAlreadyInUse | EmailUnchanged | EmailChangeBlockedByPendingDeletion ->
      409
    MissingUserIdAndIp -> 500
  }
}

pub fn code(err: AuthError) -> String {
  case err {
    InvalidLoginToken -> "login_invalid_token"
    LoginTokenUsed -> "login_token_used"
    LoginTokenExpired -> "login_token_expired"
    PasskeyChallengeNotFound -> "passkey_challenge_not_found"
    PasskeyChallengeExpired -> "passkey_challenge_expired"
    InvalidPasskeyAssertion -> "passkey_invalid_assertion"
    MissingSessionToken -> "session_missing_token"
    SessionNotFound -> "session_not_found"
    SessionExpired -> "session_expired"
    MissingUserIdAndIp -> "client_info_error"
    AuthenticationRequired -> "authorization_authentication_required"
    NotOwner -> "authorization_not_owner"
    AdminRequired -> "authorization_admin_required"
    InvalidEmailChangeToken -> "email_change_invalid_token"
    EmailAlreadyInUse -> "email_change_email_in_use"
    EmailUnchanged -> "email_change_email_unchanged"
    EmailChangeBlockedByPendingDeletion ->
      "email_change_blocked_by_pending_deletion"
  }
}

pub fn message(err: AuthError) -> String {
  case err {
    InvalidLoginToken -> "Invalid login token"
    LoginTokenUsed -> "Login token already used"
    LoginTokenExpired -> "Login token expired"
    PasskeyChallengeNotFound -> "Passkey challenge not found"
    PasskeyChallengeExpired -> "Passkey challenge expired"
    InvalidPasskeyAssertion -> "Invalid passkey assertion"
    MissingSessionToken -> "Missing session token"
    SessionNotFound -> "Session not found"
    SessionExpired -> "Session expired"
    MissingUserIdAndIp -> "Missing user_id and ip"
    AuthenticationRequired -> "Authentication required"
    NotOwner -> "Not authorized"
    AdminRequired -> "Admin access required"
    InvalidEmailChangeToken -> "Invalid email change verification code"
    EmailAlreadyInUse -> "Email address is already in use"
    EmailUnchanged -> "New email address matches the current email address"
    EmailChangeBlockedByPendingDeletion ->
      "Cancel scheduled account deletion before changing email"
  }
}

pub fn to_string(err: AuthError) -> String {
  case err {
    InvalidLoginToken -> "login_error:invalid_token"
    LoginTokenUsed -> "login_error:token_used"
    LoginTokenExpired -> "login_error:token_expired"
    PasskeyChallengeNotFound -> "passkey_error:challenge_not_found"
    PasskeyChallengeExpired -> "passkey_error:challenge_expired"
    InvalidPasskeyAssertion -> "passkey_error:invalid_assertion"
    MissingSessionToken -> "session_error:missing_session_token"
    SessionNotFound -> "session_error:session_not_found"
    SessionExpired -> "session_error:session_expired"
    MissingUserIdAndIp -> "client_info_error:missing_user_id_and_ip"
    AuthenticationRequired -> "authorization_error:authentication_required"
    NotOwner -> "authorization_error:not_owner"
    AdminRequired -> "authorization_error:admin_required"
    InvalidEmailChangeToken -> "email_change_error:invalid_token"
    EmailAlreadyInUse -> "email_change_error:email_in_use"
    EmailUnchanged -> "email_change_error:email_unchanged"
    EmailChangeBlockedByPendingDeletion -> "email_change_error:pending_deletion"
  }
}

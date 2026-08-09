import glot_backend/auth/effect/algebra
import glot_backend/auth/effect/algebra/account as account_algebra
import glot_backend/auth/effect/algebra/email_change as email_change_algebra
import glot_backend/auth/effect/algebra/login_token as login_token_algebra
import glot_backend/auth/effect/algebra/passkey as passkey_algebra
import glot_backend/auth/effect/algebra/session as session_algebra
import glot_backend/auth/effect/algebra/user as user_algebra
import glot_backend/system/effect/program_types

pub fn account(
  effect: account_algebra.Effect(next),
) -> program_types.DbEffect(next) {
  program_types.AuthEffect(algebra.Account(effect))
}

pub fn user(effect: user_algebra.Effect(next)) -> program_types.DbEffect(next) {
  program_types.AuthEffect(algebra.User(effect))
}

pub fn session(
  effect: session_algebra.Effect(next),
) -> program_types.DbEffect(next) {
  program_types.AuthEffect(algebra.Session(effect))
}

pub fn login_token(
  effect: login_token_algebra.Effect(next),
) -> program_types.DbEffect(next) {
  program_types.AuthEffect(algebra.LoginToken(effect))
}

pub fn passkey(
  effect: passkey_algebra.Effect(next),
) -> program_types.DbEffect(next) {
  program_types.AuthEffect(algebra.Passkey(effect))
}

pub fn email_change(
  effect: email_change_algebra.Effect(next),
) -> program_types.DbEffect(next) {
  program_types.AuthEffect(algebra.EmailChange(effect))
}

import glot_backend/auth/effect/algebra/account
import glot_backend/auth/effect/algebra/email_change
import glot_backend/auth/effect/algebra/login_token
import glot_backend/auth/effect/algebra/passkey
import glot_backend/auth/effect/algebra/session
import glot_backend/auth/effect/algebra/user

pub type AuthEffect(next) {
  Account(effect: account.Effect(next))
  User(effect: user.Effect(next))
  Session(effect: session.Effect(next))
  LoginToken(effect: login_token.Effect(next))
  Passkey(effect: passkey.Effect(next))
  EmailChange(effect: email_change.Effect(next))
}

pub fn map(effect: AuthEffect(a), f: fn(a) -> b) -> AuthEffect(b) {
  case effect {
    Account(effect) -> Account(account.map(effect, f))
    User(effect) -> User(user.map(effect, f))
    Session(effect) -> Session(session.map(effect, f))
    LoginToken(effect) -> LoginToken(login_token.map(effect, f))
    Passkey(effect) -> Passkey(passkey.map(effect, f))
    EmailChange(effect) -> EmailChange(email_change.map(effect, f))
  }
}

pub type EffectName {
  AccountName(account.EffectName)
  UserName(user.EffectName)
  SessionName(session.EffectName)
  LoginTokenName(login_token.EffectName)
  PasskeyName(passkey.EffectName)
  EmailChangeName(email_change.EffectName)
}

pub fn effect_name_to_string(name: EffectName) -> String {
  case name {
    AccountName(name) -> account.effect_name_to_string(name)
    UserName(name) -> user.effect_name_to_string(name)
    SessionName(name) -> session.effect_name_to_string(name)
    LoginTokenName(name) -> login_token.effect_name_to_string(name)
    PasskeyName(name) -> passkey.effect_name_to_string(name)
    EmailChangeName(name) -> email_change.effect_name_to_string(name)
  }
}

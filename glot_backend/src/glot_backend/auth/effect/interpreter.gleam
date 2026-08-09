import glot_backend/auth/effect/algebra as auth_algebra
import glot_backend/auth/effect/interpreter/account
import glot_backend/auth/effect/interpreter/email_change
import glot_backend/auth/effect/interpreter/login_token
import glot_backend/auth/effect/interpreter/passkey
import glot_backend/auth/effect/interpreter/session
import glot_backend/auth/effect/interpreter/user
import glot_backend/auth/ports as auth_ports
import glot_backend/system/effect/error
import glot_backend/system/effect/program_state
import glot_backend/system/request/context

pub fn run(
  effect: auth_algebra.AuthEffect(next_program),
  ctx: context.Context,
  ports: auth_ports.Ports,
  state: program_state.State,
  continue: fn(next_program, program_state.State) ->
    #(Result(a, error.Error), program_state.State),
) -> #(Result(a, error.Error), program_state.State) {
  case effect {
    auth_algebra.Account(effect) ->
      account.run(effect, ports.accounts, state, continue)
    auth_algebra.User(effect) ->
      user.run(effect, ctx, ports.users, state, continue)
    auth_algebra.Session(effect) ->
      session.run(effect, ctx, ports.sessions, state, continue)
    auth_algebra.LoginToken(effect) ->
      login_token.run(effect, ports.login_tokens, state, continue)
    auth_algebra.Passkey(effect) ->
      passkey.run(effect, ports.passkeys, state, continue)
    auth_algebra.EmailChange(effect) ->
      email_change.run(effect, ports.email_change_tokens, state, continue)
  }
}

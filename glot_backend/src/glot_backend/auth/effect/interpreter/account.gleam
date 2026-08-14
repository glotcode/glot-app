import glot_backend/auth/effect/algebra as auth_algebra
import glot_backend/auth/effect/algebra/account as account_algebra
import glot_backend/auth/ports/account_store.{type AccountStore}
import glot_backend/system/effect/effect_trace
import glot_backend/system/effect/error
import glot_backend/system/effect/measured_interpreter
import glot_backend/system/effect/program_state

pub fn run(
  effect: account_algebra.Effect(next_program),
  store: AccountStore,
  state: program_state.State,
  continue: fn(next_program, program_state.State) ->
    #(Result(a, error.Error), program_state.State),
) -> #(Result(a, error.Error), program_state.State) {
  case effect {
    account_algebra.CreateAccount(account: account, next: next) ->
      measured_interpreter.run(
        fn() { store.create(account) },
        next,
        name: trace_name(account_algebra.CreateAccountEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
    account_algebra.UpdateAccount(account: account, next: next) ->
      measured_interpreter.run(
        fn() { store.update(account) },
        next,
        name: trace_name(account_algebra.UpdateAccountEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
    account_algebra.DeleteAccount(account_id: account_id, next: next) ->
      measured_interpreter.run(
        fn() { store.delete(account_id) },
        next,
        name: trace_name(account_algebra.DeleteAccountEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
  }
}

fn trace_name(name: account_algebra.EffectName) -> effect_trace.EffectName {
  effect_trace.AuthEffectName(auth_algebra.AccountName(name))
}

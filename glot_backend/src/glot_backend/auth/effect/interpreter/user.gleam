import glot_backend/auth/effect/algebra as auth_algebra
import glot_backend/auth/effect/algebra/user as user_algebra
import glot_backend/auth/ports/user_store.{type UserStore}
import glot_backend/system/effect/effect_trace
import glot_backend/system/effect/error
import glot_backend/system/effect/measured_interpreter
import glot_backend/system/effect/program_state
import glot_backend/system/request/context

pub fn run(
  effect: user_algebra.Effect(next_program),
  ctx: context.Context,
  store: UserStore,
  state: program_state.State,
  continue: fn(next_program, program_state.State) ->
    #(Result(a, error.Error), program_state.State),
) -> #(Result(a, error.Error), program_state.State) {
  case effect {
    user_algebra.GetUserByEmail(email:, next:) ->
      measured_interpreter.run_or_fail(
        fn() { store.get_by_email(ctx.regexes.is_email, email) },
        next,
        map_error: error.database_query_error,
        name: trace_name(user_algebra.GetUserByEmailEffectName),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    user_algebra.GetUserById(id:, next:) ->
      measured_interpreter.run_or_fail(
        fn() { store.get_by_id(ctx.regexes.is_email, id) },
        next,
        map_error: error.database_query_error,
        name: trace_name(user_algebra.GetUserByIdEffectName),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    user_algebra.GetUserByIdForUpdate(id:, next:) ->
      measured_interpreter.run_or_fail(
        fn() { store.get_by_id_for_update(ctx.regexes.is_email, id) },
        next,
        map_error: error.database_query_error,
        name: trace_name(user_algebra.GetUserByIdForUpdateEffectName),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    user_algebra.ListUsers(pagination:, filters:, next:) ->
      measured_interpreter.run_or_fail(
        fn() { store.list(ctx.regexes.is_email, pagination, filters) },
        next,
        map_error: error.database_query_error,
        name: trace_name(user_algebra.ListUsersEffectName),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    user_algebra.CreateUser(user: user, next: next) ->
      measured_interpreter.run(
        fn() { store.create(user) },
        next,
        name: trace_name(user_algebra.CreateUserEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
    user_algebra.UpdateUserLastLogin(id:, timestamp:, next:) ->
      measured_interpreter.run(
        fn() { store.update_last_login(id, timestamp) },
        next,
        name: trace_name(user_algebra.UpdateUserLastLoginEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
    user_algebra.UpdateUserEmail(id:, email:, timestamp:, next:) ->
      measured_interpreter.run(
        fn() { store.update_email(id, email, timestamp) },
        next,
        name: trace_name(user_algebra.UpdateUserEmailEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
    user_algebra.UpdateUserUsername(id:, username:, timestamp:, next:) ->
      measured_interpreter.run(
        fn() { store.update_username(id, username, timestamp) },
        next,
        name: trace_name(user_algebra.UpdateUserUsernameEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
    user_algebra.UpdateUserRole(id:, role:, timestamp:, next:) ->
      measured_interpreter.run(
        fn() { store.update_role(id, role, timestamp) },
        next,
        name: trace_name(user_algebra.UpdateUserRoleEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
    user_algebra.LockEmail(email:, next:) ->
      measured_interpreter.run(
        fn() { store.lock_email(email) },
        next,
        name: trace_name(user_algebra.LockEmailEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
    user_algebra.DeleteUsersByAccountId(account_id: account_id, next: next) ->
      measured_interpreter.run(
        fn() { store.delete_by_account_id(account_id) },
        next,
        name: trace_name(user_algebra.DeleteUsersByAccountIdEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
  }
}

fn trace_name(name: user_algebra.EffectName) -> effect_trace.EffectName {
  effect_trace.AuthEffectName(auth_algebra.UserName(name))
}

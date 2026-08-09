import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_backend/auth/model/user_list_filters.{type UserListFilters}
import glot_backend/system/effect/error/db_error
import glot_core/auth/user_model
import glot_core/email/email_address_model
import glot_core/pagination_model.{type CursorPagination}
import youid/uuid.{type Uuid}

pub type Effect(next) {
  GetUserByEmail(
    email: email_address_model.EmailAddress,
    next: fn(option.Option(user_model.HydratedUser)) -> next,
  )
  GetUserById(
    id: Uuid,
    next: fn(option.Option(user_model.HydratedUser)) -> next,
  )
  GetUserByIdForUpdate(
    id: Uuid,
    next: fn(option.Option(user_model.HydratedUser)) -> next,
  )
  ListUsers(
    pagination: CursorPagination,
    filters: UserListFilters,
    next: fn(List(user_model.HydratedUser)) -> next,
  )
  CreateUser(
    user: user_model.User,
    next: fn(Result(Nil, db_error.DbCommandError)) -> next,
  )
  UpdateUserLastLogin(
    id: Uuid,
    timestamp: Timestamp,
    next: fn(Result(Nil, db_error.DbCommandError)) -> next,
  )
  UpdateUserEmail(
    id: Uuid,
    email: email_address_model.EmailAddress,
    timestamp: Timestamp,
    next: fn(Result(Nil, db_error.DbCommandError)) -> next,
  )
  UpdateUserUsername(
    id: Uuid,
    username: String,
    timestamp: Timestamp,
    next: fn(Result(Nil, db_error.DbCommandError)) -> next,
  )
  UpdateUserRole(
    id: Uuid,
    role: user_model.UserRole,
    timestamp: Timestamp,
    next: fn(Result(Nil, db_error.DbCommandError)) -> next,
  )
  LockEmail(
    email: email_address_model.EmailAddress,
    next: fn(Result(Nil, db_error.DbCommandError)) -> next,
  )
  DeleteUsersByAccountId(
    account_id: Uuid,
    next: fn(Result(Nil, db_error.DbCommandError)) -> next,
  )
}

pub type EffectName {
  GetUserByEmailEffectName
  GetUserByIdEffectName
  GetUserByIdForUpdateEffectName
  ListUsersEffectName
  CreateUserEffectName
  UpdateUserLastLoginEffectName
  UpdateUserEmailEffectName
  UpdateUserUsernameEffectName
  UpdateUserRoleEffectName
  LockEmailEffectName
  DeleteUsersByAccountIdEffectName
}

pub fn map(effect: Effect(a), f: fn(a) -> b) -> Effect(b) {
  case effect {
    GetUserByEmail(email:, next:) ->
      GetUserByEmail(email: email, next: fn(value) { f(next(value)) })
    GetUserById(id:, next:) ->
      GetUserById(id: id, next: fn(value) { f(next(value)) })
    GetUserByIdForUpdate(id:, next:) ->
      GetUserByIdForUpdate(id: id, next: fn(value) { f(next(value)) })
    ListUsers(pagination:, filters:, next:) ->
      ListUsers(pagination: pagination, filters: filters, next: fn(value) {
        f(next(value))
      })
    CreateUser(user: user, next: next) ->
      CreateUser(user: user, next: fn(value) { f(next(value)) })
    UpdateUserLastLogin(id:, timestamp:, next:) ->
      UpdateUserLastLogin(id:, timestamp:, next: fn(value) { f(next(value)) })
    UpdateUserEmail(id:, email:, timestamp:, next:) ->
      UpdateUserEmail(id:, email:, timestamp:, next: fn(value) {
        f(next(value))
      })
    UpdateUserUsername(id:, username:, timestamp:, next:) ->
      UpdateUserUsername(id:, username:, timestamp:, next: fn(value) {
        f(next(value))
      })
    UpdateUserRole(id:, role:, timestamp:, next:) ->
      UpdateUserRole(id:, role:, timestamp:, next: fn(value) { f(next(value)) })
    LockEmail(email:, next:) ->
      LockEmail(email:, next: fn(value) { f(next(value)) })
    DeleteUsersByAccountId(account_id: account_id, next: next) ->
      DeleteUsersByAccountId(account_id: account_id, next: fn(value) {
        f(next(value))
      })
  }
}

pub fn effect_name_to_string(name: EffectName) -> String {
  case name {
    GetUserByEmailEffectName -> "get_user_by_email"
    GetUserByIdEffectName -> "get_user_by_id"
    GetUserByIdForUpdateEffectName -> "get_user_by_id_for_update"
    ListUsersEffectName -> "list_users"
    CreateUserEffectName -> "create_user"
    UpdateUserLastLoginEffectName -> "update_user_last_login"
    UpdateUserEmailEffectName -> "update_user_email"
    UpdateUserUsernameEffectName -> "update_user_username"
    UpdateUserRoleEffectName -> "update_user_role"
    LockEmailEffectName -> "lock_email"
    DeleteUsersByAccountIdEffectName -> "delete_users_by_account_id"
  }
}

import gleam/option.{type Option}
import glot_backend/auth/error as auth_error
import glot_backend/system/effect/error
import glot_backend/system/effect/error/resource_error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{
  type Program, type TransactionProgram,
}
import glot_backend/system/effect/transaction/transaction_program
import glot_core/auth/user_model.{type User}
import glot_core/snippet/snippet_model.{type HydratedSnippet}
import youid/uuid.{type Uuid}

pub fn can_view(snippet: HydratedSnippet, viewer: Option(User)) -> Bool {
  case snippet.identity.visibility {
    snippet_model.Public | snippet_model.Unlisted -> True
    snippet_model.Secret -> secret_is_visible_to(snippet, viewer)
  }
}

pub fn require_view(
  snippet: HydratedSnippet,
  viewer: Option(User),
) -> Program(Nil) {
  case can_view(snippet, viewer) {
    True -> program.succeed(Nil)
    False -> program.fail(error.resource(resource_error.SnippetNotFound))
  }
}

pub fn require_owner_tx(
  snippet: HydratedSnippet,
  actor_user_id: Uuid,
) -> TransactionProgram(Nil) {
  case snippet.user.id == actor_user_id {
    True -> transaction_program.succeed(Nil)
    False -> transaction_program.fail(error.auth(auth_error.NotOwner))
  }
}

fn secret_is_visible_to(
  snippet: HydratedSnippet,
  viewer: Option(User),
) -> Bool {
  case viewer {
    option.Some(user) ->
      user.id == snippet.user.id || user.role == user_model.AdminUser
    option.None -> False
  }
}

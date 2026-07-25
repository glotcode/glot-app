import gleam/option
import glot_core/auth/user_model.{type User}
import glot_core/snippet/snippet_model.{type HydratedSnippet}

pub fn can_view(snippet: HydratedSnippet, viewer: option.Option(User)) -> Bool {
  case snippet.identity.visibility {
    snippet_model.Public | snippet_model.Unlisted -> True
    snippet_model.Secret -> secret_is_visible_to(snippet, viewer)
  }
}

fn secret_is_visible_to(
  snippet: HydratedSnippet,
  viewer: option.Option(User),
) -> Bool {
  case viewer {
    option.Some(user) ->
      user.id == snippet.user.id || user.role == user_model.AdminUser
    option.None -> False
  }
}

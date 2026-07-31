import gleam/option
import glot_core/snippet/snippet_model
import glot_frontend/public/editor/model.{type Editor}
import youid/uuid.{type Uuid}

pub type SaveOperation {
  CreateSnippet
  UpdateSnippet(String)
}

pub fn is_owner(model: Editor, current_user_id: option.Option(Uuid)) -> Bool {
  model.snippet.owner_user_id == current_user_id
}

pub fn can_choose_visibility(
  model: Editor,
  current_user_id: option.Option(Uuid),
) -> Bool {
  case current_user_id {
    option.None -> False
    option.Some(_) ->
      model.snippet.slug == option.None || is_owner(model, current_user_id)
  }
}

pub fn save_operation(
  model: Editor,
  current_user_id: option.Option(Uuid),
) -> SaveOperation {
  case model.snippet.slug, is_owner(model, current_user_id) {
    option.Some(slug), True -> UpdateSnippet(slug)
    _, _ -> CreateSnippet
  }
}

pub fn visibility(
  model: Editor,
  current_user_id: option.Option(Uuid),
) -> snippet_model.Visibility {
  case model.snippet.slug {
    option.Some(_) -> model.snippet.visibility
    option.None ->
      case can_choose_visibility(model, current_user_id) {
        True -> model.save_draft.visibility
        False -> model.snippet.visibility
      }
  }
}

pub fn action_name(
  model: Editor,
  current_user_id: option.Option(Uuid),
) -> String {
  case save_operation(model, current_user_id) {
    CreateSnippet -> "Create snippet"
    UpdateSnippet(_) -> "Update snippet"
  }
}

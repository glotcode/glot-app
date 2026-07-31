import gleam/option
import glot_core/snippet/snippet_model
import glot_frontend/public/editor/model.{type Editor}
import youid/uuid.{type Uuid}

pub type SaveDecision {
  LoginRequired
  Authorized(SavePlan)
}

pub type SavePlan {
  CreateSnippet(visibility: snippet_model.Visibility)
  UpdateSnippet(slug: String, visibility: snippet_model.Visibility)
}

pub fn is_owner(model: Editor, current_user_id: option.Option(Uuid)) -> Bool {
  case current_user_id {
    option.Some(current_user_id) -> user_owns(model, current_user_id)
    option.None -> False
  }
}

pub fn can_choose_visibility(
  model: Editor,
  current_user_id: option.Option(Uuid),
) -> Bool {
  case current_user_id {
    option.None -> False
    option.Some(_) -> model.snippet.slug == option.None
  }
}

pub fn save_decision(
  model: Editor,
  current_user_id: option.Option(Uuid),
) -> SaveDecision {
  case current_user_id {
    option.None -> LoginRequired
    option.Some(current_user_id) ->
      Authorized(authorized_plan(model, current_user_id))
  }
}

pub fn plan_visibility(plan: SavePlan) -> snippet_model.Visibility {
  case plan {
    CreateSnippet(visibility) | UpdateSnippet(_, visibility) -> visibility
  }
}

pub fn plan_action_name(plan: SavePlan) -> String {
  case plan {
    CreateSnippet(_) -> "Create snippet"
    UpdateSnippet(_, _) -> "Update snippet"
  }
}

pub fn action_name(
  model: Editor,
  current_user_id: option.Option(Uuid),
) -> String {
  case save_decision(model, current_user_id) {
    LoginRequired -> "Create snippet"
    Authorized(plan) -> plan_action_name(plan)
  }
}

fn authorized_plan(model: Editor, current_user_id: Uuid) -> SavePlan {
  case model.snippet.slug, user_owns(model, current_user_id) {
    option.Some(slug), True -> UpdateSnippet(slug, model.snippet.visibility)
    option.Some(_), False -> CreateSnippet(model.snippet.visibility)
    option.None, _ -> CreateSnippet(model.save_draft.visibility)
  }
}

fn user_owns(model: Editor, current_user_id: Uuid) -> Bool {
  model.snippet.owner_user_id == option.Some(current_user_id)
}

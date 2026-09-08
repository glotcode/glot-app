import gleam/option
import glot_core/language
import glot_core/snippet/snippet_model
import glot_frontend/public/editor/environment
import glot_frontend/public/editor/model
import glot_frontend/public/editor/policy
import glot_frontend/public/editor/ready
import support/editor_fixture

pub fn save_decision_requires_login_before_resolving_a_plan_test() {
  assert policy.save_decision(new_editor(), option.None) == policy.LoginRequired
  assert !policy.is_owner(new_editor(), option.None)
}

pub fn authorized_plans_resolve_target_and_visibility_once_test() {
  let owner = editor_fixture.owner_id()
  let editor = existing_editor()

  assert policy.save_decision(editor, option.Some(owner))
    == policy.Authorized(policy.UpdateSnippet(
      "save-policy",
      snippet_model.Unlisted,
    ))
  assert policy.save_decision(
      editor,
      option.Some(editor_fixture.other_user_id()),
    )
    == policy.Authorized(policy.CreateSnippet(snippet_model.Unlisted))

  let new = with_visibility_draft(new_editor(), snippet_model.Secret)
  assert policy.save_decision(new, option.Some(owner))
    == policy.Authorized(policy.CreateSnippet(snippet_model.Secret))
}

pub fn visibility_is_selectable_only_for_an_authenticated_new_snippet_test() {
  let owner = editor_fixture.owner_id()
  let new = with_visibility_draft(new_editor(), snippet_model.Secret)

  assert policy.can_choose_visibility(new, option.Some(owner))
  assert !policy.can_choose_visibility(new, option.None)

  let existing = with_visibility_draft(existing_editor(), snippet_model.Secret)
  assert !policy.can_choose_visibility(existing, option.Some(owner))
  assert !policy.can_choose_visibility(
    existing,
    option.Some(editor_fixture.other_user_id()),
  )
}

pub fn plan_helpers_follow_the_resolved_plan_test() {
  let create = policy.CreateSnippet(snippet_model.Secret)
  let update = policy.UpdateSnippet("existing", snippet_model.Public)

  assert policy.plan_visibility(create) == snippet_model.Secret
  assert policy.plan_visibility(update) == snippet_model.Public
  assert policy.plan_action_name(create) == "Create snippet"
  assert policy.plan_action_name(update) == "Update snippet"
  assert policy.action_name(
      existing_editor(),
      option.Some(editor_fixture.owner_id()),
    )
    == "Update snippet"
  assert policy.action_name(
      existing_editor(),
      option.Some(editor_fixture.other_user_id()),
    )
    == "Create snippet"
  assert policy.action_name(existing_editor(), option.None) == "Create snippet"
}

fn new_editor() -> model.Editor {
  ready.new(language.JavaScript, environment.defaults())
}

fn existing_editor() -> model.Editor {
  let editor = new_editor()
  model.Editor(
    ..editor,
    snippet: model.Snippet(
      ..editor.snippet,
      slug: option.Some("save-policy"),
      owner_user_id: option.Some(editor_fixture.owner_id()),
    ),
  )
}

fn with_visibility_draft(
  editor: model.Editor,
  visibility: snippet_model.Visibility,
) -> model.Editor {
  model.Editor(..editor, save_draft: model.SaveDraft(visibility: visibility))
}

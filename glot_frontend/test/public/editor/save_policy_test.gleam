import gleam/option
import glot_core/language
import glot_core/snippet/snippet_model
import glot_frontend/public/editor/model
import glot_frontend/public/editor/policy
import glot_frontend/public/editor/ready
import glot_frontend/public/editor/settings
import support/editor_fixture

pub fn save_operation_updates_only_an_owned_existing_snippet_test() {
  let owner = editor_fixture.owner_id()
  let editor = existing_editor()

  assert policy.save_operation(editor, option.Some(owner))
    == policy.UpdateSnippet("save-policy")
  assert policy.save_operation(
      editor,
      option.Some(editor_fixture.other_user_id()),
    )
    == policy.CreateSnippet
  assert policy.save_operation(editor, option.None) == policy.CreateSnippet
  assert policy.save_operation(new_editor(), option.Some(owner))
    == policy.CreateSnippet
}

pub fn visibility_is_selectable_only_for_an_authenticated_new_snippet_test() {
  let owner = editor_fixture.owner_id()
  let new = with_visibility_draft(new_editor(), snippet_model.Secret)

  assert policy.can_choose_visibility(new, option.Some(owner))
  assert policy.visibility(new, option.Some(owner)) == snippet_model.Secret
  assert !policy.can_choose_visibility(new, option.None)
  assert policy.visibility(new, option.None) == snippet_model.Unlisted

  let existing = with_visibility_draft(existing_editor(), snippet_model.Secret)
  assert policy.can_choose_visibility(existing, option.Some(owner))
  assert policy.visibility(existing, option.Some(owner))
    == snippet_model.Unlisted
  assert !policy.can_choose_visibility(
    existing,
    option.Some(editor_fixture.other_user_id()),
  )
  assert policy.visibility(
      existing,
      option.Some(editor_fixture.other_user_id()),
    )
    == snippet_model.Unlisted
}

pub fn action_name_follows_the_resolved_operation_test() {
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
}

fn new_editor() -> model.Editor {
  ready.new(language.JavaScript, settings.defaults())
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

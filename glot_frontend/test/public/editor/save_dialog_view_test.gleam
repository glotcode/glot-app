import gleam/option
import gleam/string
import glot_core/language
import glot_frontend/public/editor/model
import glot_frontend/public/editor/ready
import glot_frontend/public/editor/save_dialog_view
import glot_frontend/public/editor/settings
import lustre/element
import support/editor_fixture
import youid/uuid.{type Uuid}

pub fn anonymous_users_receive_a_login_action_instead_of_a_save_form_test() {
  let rendered = render(new_editor(), option.None)

  assert string.contains(
    rendered,
    "You need to log in before you can save snippets.",
  )
  assert string.contains(rendered, ">Go to login</a>")
  assert string.contains(rendered, ">Close</button>")
  assert !string.contains(rendered, "type=\"submit\"")
}

pub fn authenticated_new_snippets_offer_visibility_and_save_test() {
  let rendered = render(new_editor(), option.Some(editor_fixture.owner_id()))

  assert_visibility_options(rendered)
  assert string.contains(rendered, "type=\"submit\">Save</button>")
  assert !string.contains(rendered, "Save new snippet")
}

pub fn non_owners_are_told_that_save_creates_a_copy_test() {
  let rendered =
    existing_editor()
    |> render(option.Some(editor_fixture.other_user_id()))

  assert string.contains(rendered, "create a new snippet in your account")
  assert string.contains(rendered, ">Save new snippet</button>")
  assert !string.contains(rendered, "aria-label=\"Visibility\"")
}

pub fn owners_of_existing_snippets_can_choose_visibility_test() {
  let rendered =
    existing_editor()
    |> render(option.Some(editor_fixture.owner_id()))

  assert_visibility_options(rendered)
  assert string.contains(rendered, "type=\"submit\">Save</button>")
  assert !string.contains(rendered, "create a new snippet in your account")
}

fn new_editor() -> model.Editor {
  ready.new(language.JavaScript, settings.defaults())
}

fn existing_editor() -> model.Editor {
  let base = new_editor()
  model.Editor(
    ..base,
    snippet: model.Snippet(
      ..base.snippet,
      slug: option.Some("owned-snippet"),
      owner_user_id: option.Some(editor_fixture.owner_id()),
      owner_username: option.Some("fixture-owner"),
    ),
  )
}

fn render(
  editor: model.Editor,
  current_user_id: option.Option(Uuid),
) -> String {
  save_dialog_view.view(editor, current_user_id)
  |> element.to_document_string
}

fn assert_visibility_options(rendered: String) {
  assert string.contains(rendered, "aria-label=\"Visibility\"")
  assert string.contains(rendered, ">Public</span>")
  assert string.contains(rendered, ">Unlisted</span>")
  assert string.contains(rendered, ">Secret</span>")
}

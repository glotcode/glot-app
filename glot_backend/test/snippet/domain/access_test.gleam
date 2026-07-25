import gleam/option
import glot_backend/snippet/domain/access
import glot_core/auth/user_model
import glot_core/snippet/snippet_model
import support/integration/fixture
import support/integration/model.{type TestFixture}

pub fn public_snippet_is_visible_to_everyone_test() {
  let fixture = test_fixture()
  let snippet = hydrated_snippet(fixture, snippet_model.Public)

  assert access.can_view(snippet, option.None)
}

pub fn unlisted_snippet_is_visible_to_everyone_test() {
  let fixture = test_fixture()
  let snippet = hydrated_snippet(fixture, snippet_model.Unlisted)

  assert access.can_view(snippet, option.None)
}

pub fn secret_snippet_is_visible_to_its_owner_test() {
  let fixture = test_fixture()
  let snippet = hydrated_snippet(fixture, snippet_model.Secret)

  assert access.can_view(snippet, option.Some(fixture.user))
}

pub fn secret_snippet_is_hidden_from_anonymous_users_test() {
  let fixture = test_fixture()
  let snippet = hydrated_snippet(fixture, snippet_model.Secret)

  assert !access.can_view(snippet, option.None)
}

pub fn secret_snippet_is_hidden_from_other_regular_users_test() {
  let fixture = test_fixture()
  let snippet = hydrated_snippet(fixture, snippet_model.Secret)
  let other_user =
    user_model.User(
      ..fixture.user,
      id: fixture.must_uuid("00000000-0000-0000-0000-000000000999"),
    )

  assert !access.can_view(snippet, option.Some(other_user))
}

pub fn secret_snippet_is_visible_to_admins_test() {
  let fixture = test_fixture()
  let snippet = hydrated_snippet(fixture, snippet_model.Secret)
  let admin =
    user_model.User(
      ..fixture.user,
      id: fixture.must_uuid("00000000-0000-0000-0000-000000000999"),
      role: user_model.AdminUser,
    )

  assert access.can_view(snippet, option.Some(admin))
}

fn test_fixture() {
  fixture.integration_fixture(
    next_uuids: [],
    jobs: [],
    account_delete_job_id: option.None,
  )
}

fn hydrated_snippet(
  fixture: TestFixture,
  visibility: snippet_model.Visibility,
) -> snippet_model.HydratedSnippet {
  snippet_model.HydratedSnippet(
    identity: snippet_model.Snippet(..fixture.snippet, visibility: visibility),
    user: fixture.user,
  )
}

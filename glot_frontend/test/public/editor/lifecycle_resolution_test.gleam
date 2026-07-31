import gleam/json
import gleam/option
import glot_core/language
import glot_frontend/public/editor/lifecycle
import glot_frontend/public/editor/lifecycle_resolution
import glot_web/page/editor as editor_ssr
import support/editor_fixture

pub fn new_editor_without_ssr_uses_the_route_language_test() {
  assert lifecycle_resolution.resolve(lifecycle.NewEditor("javascript"), "")
    == lifecycle_resolution.StartNew(language.JavaScript)
}

pub fn valid_new_editor_ssr_is_authoritative_test() {
  let raw_ssr = editor_ssr.new("python") |> encode

  assert lifecycle_resolution.resolve(
      lifecycle.NewEditor("javascript"),
      raw_ssr,
    )
    == lifecycle_resolution.StartNew(language.Python)
}

pub fn malformed_new_editor_ssr_falls_back_to_the_route_language_test() {
  assert lifecycle_resolution.resolve(
      lifecycle.NewEditor("python"),
      "{invalid ssr",
    )
    == lifecycle_resolution.StartNew(language.Python)
}

pub fn mismatched_existing_ssr_for_a_new_route_is_ignored_test() {
  let raw_ssr =
    editor_fixture.snippet("existing", "source")
    |> editor_ssr.from_snippet
    |> encode

  assert lifecycle_resolution.resolve(lifecycle.NewEditor("python"), raw_ssr)
    == lifecycle_resolution.StartNew(language.Python)
}

pub fn new_editor_ssr_terminal_states_are_preserved_test() {
  assert lifecycle_resolution.resolve(
      lifecycle.NewEditor("javascript"),
      editor_ssr.UnsupportedLanguage("server-language") |> encode,
    )
    == lifecycle_resolution.Unsupported("server-language")

  assert lifecycle_resolution.resolve(
      lifecycle.NewEditor("javascript"),
      editor_ssr.LoadError("SSR failed") |> encode,
    )
    == lifecycle_resolution.Failed("SSR failed")
}

pub fn valid_existing_editor_ssr_starts_the_embedded_editor_test() {
  let fixture = editor_fixture.snippet("existing", "source")
  let raw_ssr = fixture |> editor_ssr.from_snippet |> encode
  let assert lifecycle_resolution.StartExisting(editor_model) =
    lifecycle_resolution.resolve(
      lifecycle.ExistingEditor(fixture.slug),
      raw_ssr,
    )
  let editor_ssr.EditorModel(slug:, language: editor_language, files:, ..) =
    editor_model

  assert slug == option.Some(fixture.slug)
  assert editor_language == language.JavaScript
  assert files == fixture.data.files
}

pub fn absent_or_malformed_existing_editor_ssr_fetches_the_route_slug_test() {
  assert lifecycle_resolution.resolve(lifecycle.ExistingEditor("missing"), "")
    == lifecycle_resolution.FetchExisting("missing")
  assert lifecycle_resolution.resolve(
      lifecycle.ExistingEditor("malformed"),
      "{invalid ssr",
    )
    == lifecycle_resolution.FetchExisting("malformed")
}

pub fn mismatched_existing_route_ssr_fetches_instead_of_using_it_test() {
  assert lifecycle_resolution.resolve(
      lifecycle.ExistingEditor("existing"),
      editor_ssr.new("javascript") |> encode,
    )
    == lifecycle_resolution.FetchExisting("existing")
  assert lifecycle_resolution.resolve(
      lifecycle.ExistingEditor("existing"),
      editor_ssr.UnsupportedLanguage("javascript") |> encode,
    )
    == lifecycle_resolution.FetchExisting("existing")

  let stale_ssr =
    editor_fixture.snippet("other", "stale")
    |> editor_ssr.from_snippet
    |> encode
  assert lifecycle_resolution.resolve(
      lifecycle.ExistingEditor("existing"),
      stale_ssr,
    )
    == lifecycle_resolution.FetchExisting("existing")
}

pub fn existing_editor_ssr_load_error_is_preserved_test() {
  assert lifecycle_resolution.resolve(
      lifecycle.ExistingEditor("existing"),
      editor_ssr.LoadError("SSR failed") |> encode,
    )
    == lifecycle_resolution.Failed("SSR failed")
}

fn encode(model: editor_ssr.ViewModel) -> String {
  model |> editor_ssr.encode |> json.to_string
}

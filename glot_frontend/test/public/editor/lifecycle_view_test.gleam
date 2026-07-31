import gleam/string
import glot_frontend/public/editor/lifecycle
import glot_frontend/public/editor/lifecycle_view
import glot_frontend/public/editor/settings
import glot_frontend/ui/delayed_loading
import lustre/element

pub fn initializing_and_unrevealed_loading_render_no_page_content_test() {
  let initializing =
    lifecycle.Initializing(lifecycle.NewEditor("javascript"))
    |> render
  assert !string.contains(initializing, "main-content")

  let #(loading, _) = delayed_loading.begin(delayed_loading.idle())
  let unrevealed =
    lifecycle.LoadingSnippet("fixture", settings.defaults(), loading)
    |> render
  assert !string.contains(unrevealed, "main-content")
  assert !string.contains(unrevealed, "Loading snippet...")
}

pub fn revealed_loading_renders_an_accessible_status_page_test() {
  let #(loading, generation) = delayed_loading.begin(delayed_loading.idle())
  let visible = delayed_loading.reveal(loading, generation)
  let rendered =
    lifecycle.LoadingSnippet("fixture", settings.defaults(), visible)
    |> render

  assert string.contains(rendered, "id=\"main-content\"")
  assert string.contains(rendered, "role=\"status\"")
  assert string.contains(rendered, "Loading snippet...")
}

pub fn terminal_states_render_distinct_titles_and_messages_test() {
  let unsupported =
    lifecycle.UnsupportedLanguage("brainfuck")
    |> render
  assert string.contains(unsupported, "<h1>Unsupported language</h1>")
  assert string.contains(unsupported, "Unsupported language: brainfuck")

  let failed = lifecycle.LoadError("Snippet lookup failed.") |> render
  assert string.contains(failed, "<h1>Snippet unavailable</h1>")
  assert string.contains(failed, "Snippet lookup failed.")
}

fn render(model: lifecycle.Model) -> String {
  lifecycle_view.view(model) |> element.to_document_string
}

import glot_frontend/public/editor/lifecycle
import glot_frontend/ui/delayed_loading
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn view(model: lifecycle.Model) -> Element(msg) {
  case model {
    lifecycle.Initializing(_) -> element.none()
    lifecycle.UnsupportedLanguage(language) ->
      unavailable("Unsupported language", "Unsupported language: " <> language)
    lifecycle.LoadingSnippet(_, _, loading_indicator) ->
      loading(delayed_loading.is_visible(loading_indicator))
    lifecycle.LoadError(message) -> unavailable("Snippet unavailable", message)
  }
}

fn unavailable(title: String, message: String) -> Element(msg) {
  html.div([attribute.class("app-page")], [
    html.div([attribute.class("app-page__screen-glow")], []),
    html.main(
      [
        attribute.id("main-content"),
        attribute.attribute("tabindex", "-1"),
        attribute.class("app-shell app-shell--narrow"),
      ],
      [
        html.section([attribute.class("app-panel")], [
          html.h1([], [html.text(title)]),
          html.p([], [html.text(message)]),
        ]),
      ],
    ),
  ])
}

fn loading(show: Bool) -> Element(msg) {
  case show {
    False -> element.none()
    True ->
      html.div([attribute.class("app-page")], [
        html.div([attribute.class("app-page__screen-glow")], []),
        html.main(
          [
            attribute.id("main-content"),
            attribute.attribute("tabindex", "-1"),
            attribute.class("app-shell app-shell--narrow"),
          ],
          [
            html.div([attribute.class("app-panel")], [
              html.p(
                [
                  attribute.class("editor-page__loading"),
                  attribute.attribute("role", "status"),
                ],
                [html.text("Loading snippet...")],
              ),
            ]),
          ],
        ),
      ])
  }
}

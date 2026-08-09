import gleam/time/timestamp.{type Timestamp}
import glot_frontend/public/snippets/message.{type Msg}
import glot_frontend/public/snippets/model.{type Model}
import glot_frontend/ui/delayed_loading
import glot_web/page/seo
import glot_web/page/snippets
import lustre/element.{type Element}

pub fn view(model: Model, now: Timestamp) -> Element(Msg) {
  snippets.view(
    snippets.ViewModel(
      page: model.page,
      username: model.username,
      language: model.language,
      now: now,
    ),
    delayed_loading.is_visible(model.loading_indicator),
  )
}

pub fn metadata(model: Model, canonical_path: String) -> seo.Metadata {
  seo.snippets(model.username, canonical_path)
}

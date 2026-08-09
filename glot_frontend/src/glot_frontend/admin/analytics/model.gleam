import gleam/option.{type Option}
import glot_core/admin/analytics_dto
import glot_core/loadable
import glot_frontend/request_generation.{type Generation}

pub type Model {
  Model(
    analytics: loadable.Loadable(analytics_dto.AnalyticsResponse),
    days: Int,
    refreshing: Bool,
    refresh_error: Option(String),
    load_generation: Generation(LoadStream),
  )
}

pub type LoadStream {
  LoadStream
}

pub fn is_presentable(model: Model) -> Bool {
  loadable.is_terminal(model.analytics)
}

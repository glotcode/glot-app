import gleam/option
import glot_core/admin/analytics_dto
import glot_core/loadable
import glot_frontend/admin/analytics/managed
import glot_frontend/admin/analytics/message
import glot_frontend/admin/command
import glot_frontend/admin/effect/analytics
import glot_frontend/api/response

pub fn changing_range_keeps_loaded_dashboard_visible_test() {
  let #(initial, _) = managed.init()
  let #(loading, load_command) = managed.ensure_loaded(initial)
  let assert command.Analytics(analytics.GetAnalytics(_, complete)) =
    load_command
  let loaded_response =
    analytics_dto.AnalyticsResponse(
      days: 30,
      completed_through: option.Some("2026-08-08"),
      pageviews: [],
      product_events: [],
      runs: [],
      reliability: [],
    )
  let #(loaded, _) =
    managed.update(loading, complete(response.Success(loaded_response)))

  let #(refreshing, refresh_command) =
    managed.update(loaded, message.DaysSelected(90))

  assert refreshing.days == 90
  assert refreshing.refreshing
  assert refreshing.analytics == loadable.Loaded(loaded_response)
  let assert command.Analytics(analytics.GetAnalytics(request, _)) =
    refresh_command
  assert request.days == 90
}

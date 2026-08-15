import gleam/option
import gleam/string
import glot_core/admin/analytics_dto
import glot_core/loadable
import glot_frontend/admin/analytics/managed
import glot_frontend/admin/analytics/message
import glot_frontend/admin/analytics/view
import glot_frontend/admin/command
import glot_frontend/admin/effect/analytics
import glot_frontend/api/response
import lustre/element

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
      reliability: [
        analytics_dto.ReliabilityMetric(
          day: "2026-08-08",
          surface: "job",
          name: "classify_snippet",
          request_count: 42,
          error_count: 2,
          avg_duration_ns: 9_000_000_000,
        ),
      ],
      spam_classifier: analytics_dto.SpamClassifierOperationalMetrics(
        backlog: 500_000,
        classified: 42,
        failed: 0,
        allow: 0,
        review: 0,
        block: 0,
        attempted_backlog: 0,
        attempts: 0,
        pending_jobs: 0,
        running_jobs: 0,
        oldest_unclassified_at: option.None,
        latest_classified_at: option.None,
        latest_failed_at: option.None,
      ),
    )
  let #(loaded, _) =
    managed.update(loading, complete(response.Success(loaded_response)))

  let #(refreshing, refresh_command) =
    managed.update(loaded, message.DaysSelected(90))

  assert refreshing.days == 90
  assert refreshing.refreshing
  assert refreshing.analytics == loadable.Loaded(loaded_response)
  let rendered = view.view(loaded) |> element.to_document_string
  assert string.contains(rendered, "Spam classifier operations")
  assert string.contains(rendered, "500000")
  assert string.contains(rendered, "Daily classifier jobs")
  assert string.contains(rendered, "9000 ms")
  let assert command.Analytics(analytics.GetAnalytics(request, _)) =
    refresh_command
  assert request.days == 90
}

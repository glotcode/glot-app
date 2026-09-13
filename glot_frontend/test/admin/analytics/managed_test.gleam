import gleam/option
import gleam/string
import glot_core/admin/analytics_dto
import glot_core/loadable
import glot_frontend/admin/analytics/managed
import glot_frontend/admin/analytics/message
import glot_frontend/admin/analytics/model
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
      runnability: option.Some(analytics_dto.RunnabilityOperationalMetrics(
        total: 100,
        checked: 60,
        runnable: 45,
        not_runnable: 15,
        backlog: 35,
        failed: 5,
        attempts: 80,
        attempted_backlog: 7,
        pending_jobs: 1,
        running_jobs: 1,
        oldest_unchecked_at: option.None,
        latest_checked_at: option.None,
        latest_failed_at: option.None,
        enabled: option.Some(True),
      )),
      fingerprint_index: option.Some(analytics_dto.FingerprintIndexMetrics(
        "local-v1",
        600_000,
        150_000,
      )),
      days: 30,
      completed_through: option.Some("2026-08-08"),
      pageviews: [],
      product_events: [],
      runs: [],
      reliability: [
        analytics_dto.ReliabilityMetric(
          "2026-08-08",
          "job",
          "check_snippet_runnability",
          120,
          3,
          2_000_000_000,
        ),
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
  assert string.contains(rendered, "Snippet runnability")
  assert string.contains(rendered, "60 / 100")
  assert string.contains(rendered, "60%")
  assert string.contains(rendered, "Terminal check failures")
  assert string.contains(rendered, "Daily runnability jobs")
  assert string.contains(rendered, "2000 ms")
  assert string.contains(rendered, "Running")
  let assert option.Some(metrics) = loaded_response.runnability
  let render_runnability = fn(metrics) {
    view.view(
      model.Model(
        ..loaded,
        analytics: loadable.Loaded(
          analytics_dto.AnalyticsResponse(
            ..loaded_response,
            runnability: metrics,
          ),
        ),
      ),
    )
    |> element.to_document_string
  }
  let paused =
    analytics_dto.RunnabilityOperationalMetrics(
      ..metrics,
      running_jobs: 0,
      pending_jobs: 0,
      enabled: option.Some(False),
    )
  assert string.contains(render_runnability(option.Some(paused)), "Paused")
  assert string.contains(
    render_runnability(option.Some(
      analytics_dto.RunnabilityOperationalMetrics(
        ..paused,
        enabled: option.None,
      ),
    )),
    "Not scheduled",
  )
  assert string.contains(
    render_runnability(option.Some(
      analytics_dto.RunnabilityOperationalMetrics(..paused, pending_jobs: 1),
    )),
    "Queued",
  )
  assert string.contains(
    render_runnability(option.Some(
      analytics_dto.RunnabilityOperationalMetrics(..paused, backlog: 0),
    )),
    "Needs attention",
  )
  assert string.contains(
    render_runnability(option.Some(
      analytics_dto.RunnabilityOperationalMetrics(
        ..paused,
        total: 0,
        checked: 0,
        backlog: 0,
        failed: 0,
      ),
    )),
    "No snippets to check",
  )
  assert string.contains(
    render_runnability(option.Some(
      analytics_dto.RunnabilityOperationalMetrics(
        ..paused,
        total: 60,
        backlog: 0,
        failed: 0,
      ),
    )),
    "Checks up to date",
  )
  assert string.contains(
    render_runnability(option.None),
    "Runnability statistics are unavailable",
  )
  assert string.contains(rendered, "Snippet similarity index")
  assert string.contains(rendered, "150000 / 600000")
  assert string.contains(rendered, "450000")
  assert string.contains(rendered, "25%")
  assert string.contains(rendered, "Index incomplete")
  assert string.contains(rendered, "local-v1")
  let completed =
    view.view(model_with_index(loaded, loaded_response, 600_000, 600_000))
    |> element.to_document_string
  assert string.contains(completed, "100%")
  assert string.contains(completed, "Index up to date")
  let empty =
    view.view(model_with_index(loaded, loaded_response, 0, 0))
    |> element.to_document_string
  assert string.contains(empty, "No snippets to index")
  let unavailable =
    view.view(
      model.Model(
        ..loaded,
        analytics: loadable.Loaded(
          analytics_dto.AnalyticsResponse(
            ..loaded_response,
            fingerprint_index: option.None,
          ),
        ),
      ),
    )
    |> element.to_document_string
  assert string.contains(unavailable, "Indexing progress is unavailable")
  assert !string.contains(unavailable, "Index up to date")
  assert string.contains(rendered, "Spam classifier operations")
  assert string.contains(rendered, "500000")
  assert string.contains(rendered, "Daily classifier jobs")
  assert string.contains(rendered, "9000 ms")
  let assert command.Analytics(analytics.GetAnalytics(request, _)) =
    refresh_command
  assert request.days == 90
}

fn model_with_index(
  loaded: model.Model,
  data: analytics_dto.AnalyticsResponse,
  total: Int,
  indexed: Int,
) -> model.Model {
  model.Model(
    ..loaded,
    analytics: loadable.Loaded(
      analytics_dto.AnalyticsResponse(
        ..data,
        fingerprint_index: option.Some(analytics_dto.FingerprintIndexMetrics(
          "local-v1",
          total,
          indexed,
        )),
      ),
    ),
  )
}

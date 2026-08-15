import glot_backend/analytics/ports/store
import support/integration/adapter/unexpected

pub fn defaults() -> store.Store {
  store.Store(
    get_analytics: fn(_, _, _) { unexpected.query("analytics.get") },
    get_max_completed_metrics_day: fn() {
      unexpected.query("analytics.max_day")
    },
    get_first_metrics_source_day: fn(_) {
      unexpected.query("analytics.first_source_day")
    },
    insert_metrics_pageview_day: fn(_) {
      unexpected.command("analytics.insert_pageview_day")
    },
    insert_metrics_product_event_day: fn(_) {
      unexpected.command("analytics.insert_product_event_day")
    },
    insert_metrics_run_day: fn(_) {
      unexpected.command("analytics.insert_run_day")
    },
    insert_metrics_reliability_page_day: fn(_) {
      unexpected.command("analytics.insert_reliability_page_day")
    },
    insert_metrics_reliability_api_day: fn(_) {
      unexpected.command("analytics.insert_reliability_api_day")
    },
    insert_metrics_reliability_job_day: fn(_) {
      unexpected.command("analytics.insert_reliability_job_day")
    },
    insert_metrics_completed_day: fn(_) {
      unexpected.command("analytics.insert_completed_day")
    },
  )
}

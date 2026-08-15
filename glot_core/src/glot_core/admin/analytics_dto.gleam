import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}
import glot_core/helpers/timestamp_helpers

pub type GetAnalyticsRequest {
  GetAnalyticsRequest(days: Int)
}

pub type AnalyticsResponse {
  AnalyticsResponse(
    days: Int,
    completed_through: Option(String),
    pageviews: List(PageviewMetric),
    product_events: List(ProductEventMetric),
    runs: List(RunMetric),
    reliability: List(ReliabilityMetric),
    spam_classifier: SpamClassifierOperationalMetrics,
  )
}

pub type SpamClassifierOperationalMetrics {
  SpamClassifierOperationalMetrics(
    backlog: Int,
    classified: Int,
    failed: Int,
    allow: Int,
    review: Int,
    block: Int,
    attempted_backlog: Int,
    attempts: Int,
    pending_jobs: Int,
    running_jobs: Int,
    oldest_unclassified_at: Option(Timestamp),
    latest_classified_at: Option(Timestamp),
    latest_failed_at: Option(Timestamp),
  )
}

pub type PageviewMetric {
  PageviewMetric(
    day: String,
    route: String,
    path: String,
    views: Int,
    unique_sessions: Int,
    unique_users: Int,
  )
}

pub type ProductEventMetric {
  ProductEventMetric(
    day: String,
    event_name: String,
    event_count: Int,
    unique_sessions: Int,
    unique_users: Int,
  )
}

pub type RunMetric {
  RunMetric(
    day: String,
    language: String,
    successful_runs: Int,
    failed_runs: Int,
    unique_sessions: Int,
    unique_users: Int,
  )
}

pub type ReliabilityMetric {
  ReliabilityMetric(
    day: String,
    surface: String,
    name: String,
    request_count: Int,
    error_count: Int,
    avg_duration_ns: Int,
  )
}

pub fn request_decoder() -> decode.Decoder(GetAnalyticsRequest) {
  use days <- decode.field("days", decode.int)
  decode.success(GetAnalyticsRequest(days: days))
}

pub fn encode_request(request: GetAnalyticsRequest) -> json.Json {
  json.object([#("days", json.int(request.days))])
}

pub fn response_decoder() -> decode.Decoder(AnalyticsResponse) {
  use days <- decode.field("days", decode.int)
  use completed_through <- decode.field(
    "completedThrough",
    decode.optional(decode.string),
  )
  use pageviews <- decode.field("pageviews", decode.list(pageview_decoder()))
  use product_events <- decode.field(
    "productEvents",
    decode.list(product_event_decoder()),
  )
  use runs <- decode.field("runs", decode.list(run_decoder()))
  use reliability <- decode.field(
    "reliability",
    decode.list(reliability_decoder()),
  )
  use spam_classifier <- decode.field(
    "spamClassifier",
    spam_classifier_decoder(),
  )
  decode.success(AnalyticsResponse(
    days: days,
    completed_through: completed_through,
    pageviews: pageviews,
    product_events: product_events,
    runs: runs,
    reliability: reliability,
    spam_classifier: spam_classifier,
  ))
}

pub fn encode_response(response: AnalyticsResponse) -> json.Json {
  json.object([
    #("days", json.int(response.days)),
    #(
      "completedThrough",
      json.nullable(response.completed_through, json.string),
    ),
    #("pageviews", json.array(response.pageviews, encode_pageview)),
    #(
      "productEvents",
      json.array(response.product_events, encode_product_event),
    ),
    #("runs", json.array(response.runs, encode_run)),
    #("reliability", json.array(response.reliability, encode_reliability)),
    #("spamClassifier", encode_spam_classifier(response.spam_classifier)),
  ])
}

fn spam_classifier_decoder() -> decode.Decoder(SpamClassifierOperationalMetrics) {
  use backlog <- decode.field("backlog", decode.int)
  use classified <- decode.field("classified", decode.int)
  use failed <- decode.field("failed", decode.int)
  use allow <- decode.field("allow", decode.int)
  use review <- decode.field("review", decode.int)
  use block <- decode.field("block", decode.int)
  use attempted_backlog <- decode.field("attemptedBacklog", decode.int)
  use attempts <- decode.field("attempts", decode.int)
  use pending_jobs <- decode.field("pendingJobs", decode.int)
  use running_jobs <- decode.field("runningJobs", decode.int)
  use oldest_unclassified_at <- decode.field(
    "oldestUnclassifiedAt",
    decode.optional(timestamp_helpers.decoder()),
  )
  use latest_classified_at <- decode.field(
    "latestClassifiedAt",
    decode.optional(timestamp_helpers.decoder()),
  )
  use latest_failed_at <- decode.field(
    "latestFailedAt",
    decode.optional(timestamp_helpers.decoder()),
  )
  decode.success(SpamClassifierOperationalMetrics(
    backlog:,
    classified:,
    failed:,
    allow:,
    review:,
    block:,
    attempted_backlog:,
    attempts:,
    pending_jobs:,
    running_jobs:,
    oldest_unclassified_at:,
    latest_classified_at:,
    latest_failed_at:,
  ))
}

fn encode_spam_classifier(
  metrics: SpamClassifierOperationalMetrics,
) -> json.Json {
  json.object([
    #("backlog", json.int(metrics.backlog)),
    #("classified", json.int(metrics.classified)),
    #("failed", json.int(metrics.failed)),
    #("allow", json.int(metrics.allow)),
    #("review", json.int(metrics.review)),
    #("block", json.int(metrics.block)),
    #("attemptedBacklog", json.int(metrics.attempted_backlog)),
    #("attempts", json.int(metrics.attempts)),
    #("pendingJobs", json.int(metrics.pending_jobs)),
    #("runningJobs", json.int(metrics.running_jobs)),
    #(
      "oldestUnclassifiedAt",
      json.nullable(metrics.oldest_unclassified_at, timestamp_helpers.encode),
    ),
    #(
      "latestClassifiedAt",
      json.nullable(metrics.latest_classified_at, timestamp_helpers.encode),
    ),
    #(
      "latestFailedAt",
      json.nullable(metrics.latest_failed_at, timestamp_helpers.encode),
    ),
  ])
}

fn pageview_decoder() -> decode.Decoder(PageviewMetric) {
  use day <- decode.field("day", decode.string)
  use route <- decode.field("route", decode.string)
  use path <- decode.field("path", decode.string)
  use views <- decode.field("views", decode.int)
  use unique_sessions <- decode.field("uniqueSessions", decode.int)
  use unique_users <- decode.field("uniqueUsers", decode.int)
  decode.success(PageviewMetric(
    day,
    route,
    path,
    views,
    unique_sessions,
    unique_users,
  ))
}

fn product_event_decoder() -> decode.Decoder(ProductEventMetric) {
  use day <- decode.field("day", decode.string)
  use event_name <- decode.field("eventName", decode.string)
  use event_count <- decode.field("eventCount", decode.int)
  use unique_sessions <- decode.field("uniqueSessions", decode.int)
  use unique_users <- decode.field("uniqueUsers", decode.int)
  decode.success(ProductEventMetric(
    day,
    event_name,
    event_count,
    unique_sessions,
    unique_users,
  ))
}

fn run_decoder() -> decode.Decoder(RunMetric) {
  use day <- decode.field("day", decode.string)
  use language <- decode.field("language", decode.string)
  use successful_runs <- decode.field("successfulRuns", decode.int)
  use failed_runs <- decode.field("failedRuns", decode.int)
  use unique_sessions <- decode.field("uniqueSessions", decode.int)
  use unique_users <- decode.field("uniqueUsers", decode.int)
  decode.success(RunMetric(
    day,
    language,
    successful_runs,
    failed_runs,
    unique_sessions,
    unique_users,
  ))
}

fn reliability_decoder() -> decode.Decoder(ReliabilityMetric) {
  use day <- decode.field("day", decode.string)
  use surface <- decode.field("surface", decode.string)
  use name <- decode.field("name", decode.string)
  use request_count <- decode.field("requestCount", decode.int)
  use error_count <- decode.field("errorCount", decode.int)
  use avg_duration_ns <- decode.field("avgDurationNs", decode.int)
  decode.success(ReliabilityMetric(
    day,
    surface,
    name,
    request_count,
    error_count,
    avg_duration_ns,
  ))
}

fn encode_pageview(metric: PageviewMetric) -> json.Json {
  json.object([
    #("day", json.string(metric.day)),
    #("route", json.string(metric.route)),
    #("path", json.string(metric.path)),
    #("views", json.int(metric.views)),
    #("uniqueSessions", json.int(metric.unique_sessions)),
    #("uniqueUsers", json.int(metric.unique_users)),
  ])
}

fn encode_product_event(metric: ProductEventMetric) -> json.Json {
  json.object([
    #("day", json.string(metric.day)),
    #("eventName", json.string(metric.event_name)),
    #("eventCount", json.int(metric.event_count)),
    #("uniqueSessions", json.int(metric.unique_sessions)),
    #("uniqueUsers", json.int(metric.unique_users)),
  ])
}

fn encode_run(metric: RunMetric) -> json.Json {
  json.object([
    #("day", json.string(metric.day)),
    #("language", json.string(metric.language)),
    #("successfulRuns", json.int(metric.successful_runs)),
    #("failedRuns", json.int(metric.failed_runs)),
    #("uniqueSessions", json.int(metric.unique_sessions)),
    #("uniqueUsers", json.int(metric.unique_users)),
  ])
}

fn encode_reliability(metric: ReliabilityMetric) -> json.Json {
  json.object([
    #("day", json.string(metric.day)),
    #("surface", json.string(metric.surface)),
    #("name", json.string(metric.name)),
    #("requestCount", json.int(metric.request_count)),
    #("errorCount", json.int(metric.error_count)),
    #("avgDurationNs", json.int(metric.avg_duration_ns)),
  ])
}

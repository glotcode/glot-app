import gleam/option.{type Option}
import gleam/time/calendar.{type Date}
import glot_backend/system/effect/error/db_error
import glot_core/admin/analytics_dto.{type AnalyticsResponse}

pub type AnalyticsEffect(next) {
  GetAnalytics(
    days: Int,
    start_day: Date,
    end_day: Date,
    next: fn(Result(AnalyticsResponse, db_error.DbQueryError)) -> next,
  )
  GetMaxCompletedMetricsDay(
    next: fn(Result(Option(Date), db_error.DbQueryError)) -> next,
  )
  GetFirstMetricsSourceDay(
    before: Date,
    next: fn(Result(Option(Date), db_error.DbQueryError)) -> next,
  )
  InsertMetricsPageviewDay(
    day: Date,
    next: fn(Result(Nil, db_error.DbCommandError)) -> next,
  )
  InsertMetricsProductEventDay(
    day: Date,
    next: fn(Result(Nil, db_error.DbCommandError)) -> next,
  )
  InsertMetricsRunDay(
    day: Date,
    next: fn(Result(Nil, db_error.DbCommandError)) -> next,
  )
  InsertMetricsReliabilityPageDay(
    day: Date,
    next: fn(Result(Nil, db_error.DbCommandError)) -> next,
  )
  InsertMetricsReliabilityApiDay(
    day: Date,
    next: fn(Result(Nil, db_error.DbCommandError)) -> next,
  )
  InsertMetricsCompletedDay(
    day: Date,
    next: fn(Result(Nil, db_error.DbCommandError)) -> next,
  )
}

pub fn map(effect: AnalyticsEffect(a), f: fn(a) -> b) -> AnalyticsEffect(b) {
  case effect {
    GetAnalytics(days:, start_day:, end_day:, next:) ->
      GetAnalytics(days:, start_day:, end_day:, next: fn(value) {
        f(next(value))
      })
    GetMaxCompletedMetricsDay(next:) ->
      GetMaxCompletedMetricsDay(next: fn(value) { f(next(value)) })
    GetFirstMetricsSourceDay(before:, next:) ->
      GetFirstMetricsSourceDay(before: before, next: fn(value) {
        f(next(value))
      })
    InsertMetricsPageviewDay(day:, next:) ->
      InsertMetricsPageviewDay(day: day, next: fn(value) { f(next(value)) })
    InsertMetricsProductEventDay(day:, next:) ->
      InsertMetricsProductEventDay(day: day, next: fn(value) { f(next(value)) })
    InsertMetricsRunDay(day:, next:) ->
      InsertMetricsRunDay(day: day, next: fn(value) { f(next(value)) })
    InsertMetricsReliabilityPageDay(day:, next:) ->
      InsertMetricsReliabilityPageDay(day: day, next: fn(value) {
        f(next(value))
      })
    InsertMetricsReliabilityApiDay(day:, next:) ->
      InsertMetricsReliabilityApiDay(day: day, next: fn(value) {
        f(next(value))
      })
    InsertMetricsCompletedDay(day:, next:) ->
      InsertMetricsCompletedDay(day: day, next: fn(value) { f(next(value)) })
  }
}

pub type EffectName {
  GetAnalyticsEffectName
  GetMaxCompletedMetricsDayEffectName
  GetFirstMetricsSourceDayEffectName
  InsertMetricsPageviewDayEffectName
  InsertMetricsProductEventDayEffectName
  InsertMetricsRunDayEffectName
  InsertMetricsReliabilityPageDayEffectName
  InsertMetricsReliabilityApiDayEffectName
  InsertMetricsCompletedDayEffectName
}

pub fn effect_name_to_string(name: EffectName) -> String {
  case name {
    GetAnalyticsEffectName -> "get_analytics"
    GetMaxCompletedMetricsDayEffectName -> "get_max_completed_metrics_day"
    GetFirstMetricsSourceDayEffectName -> "get_first_metrics_source_day"
    InsertMetricsPageviewDayEffectName -> "insert_metrics_pageview_day"
    InsertMetricsProductEventDayEffectName -> "insert_metrics_product_event_day"
    InsertMetricsRunDayEffectName -> "insert_metrics_run_day"
    InsertMetricsReliabilityPageDayEffectName ->
      "insert_metrics_reliability_page_day"
    InsertMetricsReliabilityApiDayEffectName ->
      "insert_metrics_reliability_api_day"
    InsertMetricsCompletedDayEffectName -> "insert_metrics_completed_day"
  }
}

import gleam/option.{type Option}
import gleam/time/calendar.{type Date}
import glot_backend/system/effect/error/db_error
import glot_core/admin/analytics_dto.{type AnalyticsResponse}

pub type Store {
  Store(
    get_analytics: fn(Int, Date, Date) ->
      Result(AnalyticsResponse, db_error.DbQueryError),
    get_max_completed_metrics_day: fn() ->
      Result(Option(Date), db_error.DbQueryError),
    get_first_metrics_source_day: fn(Date) ->
      Result(Option(Date), db_error.DbQueryError),
    insert_metrics_pageview_day: fn(Date) ->
      Result(Nil, db_error.DbCommandError),
    insert_metrics_product_event_day: fn(Date) ->
      Result(Nil, db_error.DbCommandError),
    insert_metrics_run_day: fn(Date) -> Result(Nil, db_error.DbCommandError),
    insert_metrics_reliability_page_day: fn(Date) ->
      Result(Nil, db_error.DbCommandError),
    insert_metrics_reliability_api_day: fn(Date) ->
      Result(Nil, db_error.DbCommandError),
    insert_metrics_reliability_job_day: fn(Date) ->
      Result(Nil, db_error.DbCommandError),
    insert_metrics_completed_day: fn(Date) ->
      Result(Nil, db_error.DbCommandError),
  )
}

import gleam/int
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import gleam/time/calendar
import glot_backend/analytics/ports/store as analytics_store
import glot_backend/sql
import glot_backend/system/database as db_helpers
import glot_backend/system/effect/error/db_error
import glot_core/admin/analytics_dto

pub fn new(db: db_helpers.Db) -> analytics_store.Store {
  analytics_store.Store(
    get_analytics: fn(days, start_day, end_day) {
      get_analytics(db, days, start_day, end_day)
    },
    get_max_completed_metrics_day: fn() { get_max_completed_metrics_day(db) },
    get_first_metrics_source_day: fn(before) {
      get_first_metrics_source_day(db, before)
    },
    insert_metrics_pageview_day: fn(day) {
      insert_metrics_pageview_day(db, day)
    },
    insert_metrics_product_event_day: fn(day) {
      insert_metrics_product_event_day(db, day)
    },
    insert_metrics_run_day: fn(day) { insert_metrics_run_day(db, day) },
    insert_metrics_reliability_page_day: fn(day) {
      insert_metrics_reliability_page_day(db, day)
    },
    insert_metrics_reliability_api_day: fn(day) {
      insert_metrics_reliability_api_day(db, day)
    },
    insert_metrics_completed_day: fn(day) {
      insert_metrics_completed_day(db, day)
    },
  )
}

pub fn get_analytics(
  db: db_helpers.Db,
  days: Int,
  start_day: calendar.Date,
  end_day: calendar.Date,
) -> Result(analytics_dto.AnalyticsResponse, db_error.DbQueryError) {
  let to_error = fn(err) { db_error.DbQueryError(string.inspect(err)) }
  use completed_through <- result.try(get_max_completed_metrics_day(db))
  use pageviews <- result.try(db_helpers.query(
    db,
    sql.list_metrics_pageviews(start_day:, end_day:),
    to_error,
  ))
  use product_events <- result.try(db_helpers.query(
    db,
    sql.list_metrics_product_events(start_day:, end_day:),
    to_error,
  ))
  use runs <- result.try(db_helpers.query(
    db,
    sql.list_metrics_runs(start_day:, end_day:),
    to_error,
  ))
  use reliability <- result.try(db_helpers.query(
    db,
    sql.list_metrics_reliability(start_day:, end_day:),
    to_error,
  ))

  Ok(analytics_dto.AnalyticsResponse(
    days: days,
    completed_through: option.map(completed_through, date_to_string),
    pageviews: list.map(pageviews.rows, fn(row) {
      analytics_dto.PageviewMetric(
        date_to_string(row.day),
        row.route,
        row.path,
        row.views,
        row.unique_sessions,
        row.unique_users,
      )
    }),
    product_events: list.map(product_events.rows, fn(row) {
      analytics_dto.ProductEventMetric(
        date_to_string(row.day),
        row.event_name,
        row.event_count,
        row.unique_sessions,
        row.unique_users,
      )
    }),
    runs: list.map(runs.rows, fn(row) {
      analytics_dto.RunMetric(
        date_to_string(row.day),
        row.language,
        row.successful_runs,
        row.failed_runs,
        row.unique_sessions,
        row.unique_users,
      )
    }),
    reliability: list.map(reliability.rows, fn(row) {
      analytics_dto.ReliabilityMetric(
        date_to_string(row.day),
        row.surface,
        row.name,
        row.request_count,
        row.error_count,
        row.avg_duration_ns,
      )
    }),
  ))
}

fn date_to_string(date: calendar.Date) -> String {
  int.to_string(date.year)
  <> "-"
  <> padded(calendar.month_to_int(date.month))
  <> "-"
  <> padded(date.day)
}

fn padded(value: Int) -> String {
  string.pad_start(int.to_string(value), 2, "0")
}

pub fn get_max_completed_metrics_day(
  db: db_helpers.Db,
) -> Result(option.Option(calendar.Date), db_error.DbQueryError) {
  let to_error = fn(err) { db_error.DbQueryError(string.inspect(err)) }
  use returned <- result.try(db_helpers.query(
    db,
    sql.get_max_completed_metrics_day(),
    to_error,
  ))

  case returned.rows {
    [] -> Ok(option.None)
    [row] -> Ok(option.Some(row.day))
    _ ->
      Error(db_error.DbQueryError("Expected one max completed metrics day row"))
  }
}

pub fn get_first_metrics_source_day(
  db: db_helpers.Db,
  before: calendar.Date,
) -> Result(option.Option(calendar.Date), db_error.DbQueryError) {
  let to_error = fn(err) { db_error.DbQueryError(string.inspect(err)) }
  use returned <- result.try(db_helpers.query(
    db,
    sql.get_first_metrics_source_day(before_day: before),
    to_error,
  ))

  case returned.rows {
    [] -> Ok(option.None)
    [row] -> Ok(option.Some(row.day))
    _ ->
      Error(db_error.DbQueryError("Expected one first metrics source day row"))
  }
}

pub fn insert_metrics_pageview_day(
  db: db_helpers.Db,
  day: calendar.Date,
) -> Result(Nil, db_error.DbCommandError) {
  execute_rollup(db, sql.insert_metrics_pageview_day(day))
}

pub fn insert_metrics_product_event_day(
  db: db_helpers.Db,
  day: calendar.Date,
) -> Result(Nil, db_error.DbCommandError) {
  execute_rollup(db, sql.insert_metrics_product_event_day(day))
}

pub fn insert_metrics_run_day(
  db: db_helpers.Db,
  day: calendar.Date,
) -> Result(Nil, db_error.DbCommandError) {
  execute_rollup(db, sql.insert_metrics_run_day(day))
}

pub fn insert_metrics_reliability_page_day(
  db: db_helpers.Db,
  day: calendar.Date,
) -> Result(Nil, db_error.DbCommandError) {
  execute_rollup(db, sql.insert_metrics_reliability_page_day(day))
}

pub fn insert_metrics_reliability_api_day(
  db: db_helpers.Db,
  day: calendar.Date,
) -> Result(Nil, db_error.DbCommandError) {
  execute_rollup(db, sql.insert_metrics_reliability_api_day(day))
}

pub fn insert_metrics_completed_day(
  db: db_helpers.Db,
  day: calendar.Date,
) -> Result(Nil, db_error.DbCommandError) {
  execute_rollup(db, sql.insert_metrics_completed_day(day))
}

fn execute_rollup(
  db: db_helpers.Db,
  query: db_helpers.ExecuteParams,
) -> Result(Nil, db_error.DbCommandError) {
  let to_error = fn(err) { db_error.DbCommandError(string.inspect(err)) }
  db_helpers.execute(db, query, to_error)
  |> result.map(fn(_) { Nil })
}

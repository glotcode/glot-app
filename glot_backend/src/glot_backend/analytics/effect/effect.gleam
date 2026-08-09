import gleam/option.{type Option}
import gleam/time/calendar.{type Date}
import glot_backend/analytics/effect/algebra as analytics_algebra
import glot_backend/system/effect/error
import glot_backend/system/effect/error/db_error
import glot_backend/system/effect/program_types
import glot_core/admin/analytics_dto.{type AnalyticsResponse}

pub fn get_analytics(
  days: Int,
  start_day: Date,
  end_day: Date,
) -> program_types.Program(AnalyticsResponse) {
  program_types.Impure(
    program_types.DbEffect(
      program_types.AnalyticsEffect(analytics_algebra.GetAnalytics(
        days:,
        start_day:,
        end_day:,
        next: analytics_next,
      )),
    ),
  )
}

pub fn get_max_completed_metrics_day() -> program_types.Program(Option(Date)) {
  program_types.Impure(
    program_types.DbEffect(
      program_types.AnalyticsEffect(analytics_algebra.GetMaxCompletedMetricsDay(
        next: query_next,
      )),
    ),
  )
}

pub fn get_first_metrics_source_day(
  before: Date,
) -> program_types.Program(Option(Date)) {
  program_types.Impure(
    program_types.DbEffect(
      program_types.AnalyticsEffect(analytics_algebra.GetFirstMetricsSourceDay(
        before: before,
        next: query_next,
      )),
    ),
  )
}

pub fn insert_metrics_pageview_day(day: Date) -> program_types.Program(Nil) {
  program_types.Impure(
    program_types.DbEffect(insert_metrics_pageview_day_effect(day, next)),
  )
}

pub fn insert_metrics_product_event_day(
  day: Date,
) -> program_types.Program(Nil) {
  program_types.Impure(
    program_types.DbEffect(insert_metrics_product_event_day_effect(day, next)),
  )
}

pub fn insert_metrics_run_day(day: Date) -> program_types.Program(Nil) {
  program_types.Impure(
    program_types.DbEffect(insert_metrics_run_day_effect(day, next)),
  )
}

pub fn insert_metrics_reliability_page_day(
  day: Date,
) -> program_types.Program(Nil) {
  program_types.Impure(
    program_types.DbEffect(insert_metrics_reliability_page_day_effect(day, next)),
  )
}

pub fn insert_metrics_reliability_api_day(
  day: Date,
) -> program_types.Program(Nil) {
  program_types.Impure(
    program_types.DbEffect(insert_metrics_reliability_api_day_effect(day, next)),
  )
}

pub fn insert_metrics_pageview_day_tx(
  day: Date,
) -> program_types.TransactionProgram(Nil) {
  program_types.TxImpure(insert_metrics_pageview_day_effect(day, tx_next))
}

pub fn insert_metrics_product_event_day_tx(
  day: Date,
) -> program_types.TransactionProgram(Nil) {
  program_types.TxImpure(insert_metrics_product_event_day_effect(day, tx_next))
}

pub fn insert_metrics_run_day_tx(
  day: Date,
) -> program_types.TransactionProgram(Nil) {
  program_types.TxImpure(insert_metrics_run_day_effect(day, tx_next))
}

pub fn insert_metrics_reliability_page_day_tx(
  day: Date,
) -> program_types.TransactionProgram(Nil) {
  program_types.TxImpure(insert_metrics_reliability_page_day_effect(
    day,
    tx_next,
  ))
}

pub fn insert_metrics_reliability_api_day_tx(
  day: Date,
) -> program_types.TransactionProgram(Nil) {
  program_types.TxImpure(insert_metrics_reliability_api_day_effect(day, tx_next))
}

pub fn insert_metrics_completed_day_tx(
  day: Date,
) -> program_types.TransactionProgram(Nil) {
  program_types.TxImpure(insert_metrics_completed_day_effect(day, tx_next))
}

fn next(
  result: Result(Nil, db_error.DbCommandError),
) -> program_types.Program(Nil) {
  case result {
    Ok(_) -> program_types.Pure(Nil)
    Error(err) -> program_types.Fail(error.database_command_error(err))
  }
}

fn tx_next(
  result: Result(Nil, db_error.DbCommandError),
) -> program_types.TransactionProgram(Nil) {
  case result {
    Ok(_) -> program_types.TxPure(Nil)
    Error(err) -> program_types.TxFail(error.database_command_error(err))
  }
}

fn query_next(
  result: Result(Option(Date), db_error.DbQueryError),
) -> program_types.Program(Option(Date)) {
  case result {
    Ok(value) -> program_types.Pure(value)
    Error(err) -> program_types.Fail(error.database_query_error(err))
  }
}

fn analytics_next(
  result: Result(AnalyticsResponse, db_error.DbQueryError),
) -> program_types.Program(AnalyticsResponse) {
  case result {
    Ok(value) -> program_types.Pure(value)
    Error(err) -> program_types.Fail(error.database_query_error(err))
  }
}

fn insert_metrics_pageview_day_effect(
  day: Date,
  next: fn(Result(Nil, db_error.DbCommandError)) -> next,
) -> program_types.DbEffect(next) {
  program_types.AnalyticsEffect(analytics_algebra.InsertMetricsPageviewDay(
    day: day,
    next: next,
  ))
}

fn insert_metrics_product_event_day_effect(
  day: Date,
  next: fn(Result(Nil, db_error.DbCommandError)) -> next,
) -> program_types.DbEffect(next) {
  program_types.AnalyticsEffect(analytics_algebra.InsertMetricsProductEventDay(
    day: day,
    next: next,
  ))
}

fn insert_metrics_run_day_effect(
  day: Date,
  next: fn(Result(Nil, db_error.DbCommandError)) -> next,
) -> program_types.DbEffect(next) {
  program_types.AnalyticsEffect(analytics_algebra.InsertMetricsRunDay(
    day: day,
    next: next,
  ))
}

fn insert_metrics_reliability_page_day_effect(
  day: Date,
  next: fn(Result(Nil, db_error.DbCommandError)) -> next,
) -> program_types.DbEffect(next) {
  program_types.AnalyticsEffect(
    analytics_algebra.InsertMetricsReliabilityPageDay(day: day, next: next),
  )
}

fn insert_metrics_reliability_api_day_effect(
  day: Date,
  next: fn(Result(Nil, db_error.DbCommandError)) -> next,
) -> program_types.DbEffect(next) {
  program_types.AnalyticsEffect(
    analytics_algebra.InsertMetricsReliabilityApiDay(day: day, next: next),
  )
}

fn insert_metrics_completed_day_effect(
  day: Date,
  next: fn(Result(Nil, db_error.DbCommandError)) -> next,
) -> program_types.DbEffect(next) {
  program_types.AnalyticsEffect(analytics_algebra.InsertMetricsCompletedDay(
    day: day,
    next: next,
  ))
}

import gleam/option.{type Option}
import gleam/time/calendar.{type Date}
import glot_backend/analytics/effect/algebra as analytics_algebra
import glot_backend/system/effect/error
import glot_backend/system/effect/error/db_error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types
import glot_backend/system/effect/transaction/transaction_program
import glot_core/admin/analytics_dto.{type AnalyticsResponse}

pub fn get_analytics(
  days: Int,
  start_day: Date,
  end_day: Date,
) -> program_types.Program(AnalyticsResponse) {
  program.perform_db(
    program_types.AnalyticsEffect(
      analytics_algebra.GetAnalytics(
        days:,
        start_day:,
        end_day:,
        next: program.from_mapped_result(
          _,
          map_error: error.database_query_error,
        ),
      ),
    ),
  )
}

pub fn get_max_completed_metrics_day() -> program_types.Program(Option(Date)) {
  program.perform_db(
    program_types.AnalyticsEffect(
      analytics_algebra.GetMaxCompletedMetricsDay(
        next: program.from_mapped_result(
          _,
          map_error: error.database_query_error,
        ),
      ),
    ),
  )
}

pub fn get_first_metrics_source_day(
  before: Date,
) -> program_types.Program(Option(Date)) {
  program.perform_db(
    program_types.AnalyticsEffect(
      analytics_algebra.GetFirstMetricsSourceDay(
        before:,
        next: program.from_mapped_result(
          _,
          map_error: error.database_query_error,
        ),
      ),
    ),
  )
}

pub fn insert_metrics_pageview_day(day: Date) -> program_types.Program(Nil) {
  program.perform_db(
    insert_metrics_pageview_day_effect(day, program.from_mapped_result(
      _,
      map_error: error.database_command_error,
    )),
  )
}

pub fn insert_metrics_product_event_day(
  day: Date,
) -> program_types.Program(Nil) {
  program.perform_db(
    insert_metrics_product_event_day_effect(day, program.from_mapped_result(
      _,
      map_error: error.database_command_error,
    )),
  )
}

pub fn insert_metrics_run_day(day: Date) -> program_types.Program(Nil) {
  program.perform_db(
    insert_metrics_run_day_effect(day, program.from_mapped_result(
      _,
      map_error: error.database_command_error,
    )),
  )
}

pub fn insert_metrics_reliability_page_day(
  day: Date,
) -> program_types.Program(Nil) {
  program.perform_db(
    insert_metrics_reliability_page_day_effect(day, program.from_mapped_result(
      _,
      map_error: error.database_command_error,
    )),
  )
}

pub fn insert_metrics_reliability_api_day(
  day: Date,
) -> program_types.Program(Nil) {
  program.perform_db(
    insert_metrics_reliability_api_day_effect(day, program.from_mapped_result(
      _,
      map_error: error.database_command_error,
    )),
  )
}

pub fn insert_metrics_reliability_job_day(
  day: Date,
) -> program_types.Program(Nil) {
  program.perform_db(
    insert_metrics_reliability_job_day_effect(day, program.from_mapped_result(
      _,
      map_error: error.database_command_error,
    )),
  )
}

pub fn insert_metrics_pageview_day_tx(
  day: Date,
) -> program_types.TransactionProgram(Nil) {
  transaction_program.perform(
    insert_metrics_pageview_day_effect(
      day,
      transaction_program.from_mapped_result(
        _,
        map_error: error.database_command_error,
      ),
    ),
  )
}

pub fn insert_metrics_product_event_day_tx(
  day: Date,
) -> program_types.TransactionProgram(Nil) {
  transaction_program.perform(
    insert_metrics_product_event_day_effect(
      day,
      transaction_program.from_mapped_result(
        _,
        map_error: error.database_command_error,
      ),
    ),
  )
}

pub fn insert_metrics_run_day_tx(
  day: Date,
) -> program_types.TransactionProgram(Nil) {
  transaction_program.perform(
    insert_metrics_run_day_effect(day, transaction_program.from_mapped_result(
      _,
      map_error: error.database_command_error,
    )),
  )
}

pub fn insert_metrics_reliability_page_day_tx(
  day: Date,
) -> program_types.TransactionProgram(Nil) {
  transaction_program.perform(
    insert_metrics_reliability_page_day_effect(
      day,
      transaction_program.from_mapped_result(
        _,
        map_error: error.database_command_error,
      ),
    ),
  )
}

pub fn insert_metrics_reliability_api_day_tx(
  day: Date,
) -> program_types.TransactionProgram(Nil) {
  transaction_program.perform(
    insert_metrics_reliability_api_day_effect(
      day,
      transaction_program.from_mapped_result(
        _,
        map_error: error.database_command_error,
      ),
    ),
  )
}

pub fn insert_metrics_reliability_job_day_tx(
  day: Date,
) -> program_types.TransactionProgram(Nil) {
  transaction_program.perform(
    insert_metrics_reliability_job_day_effect(
      day,
      transaction_program.from_mapped_result(
        _,
        map_error: error.database_command_error,
      ),
    ),
  )
}

pub fn insert_metrics_completed_day_tx(
  day: Date,
) -> program_types.TransactionProgram(Nil) {
  transaction_program.perform(
    insert_metrics_completed_day_effect(
      day,
      transaction_program.from_mapped_result(
        _,
        map_error: error.database_command_error,
      ),
    ),
  )
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

fn insert_metrics_reliability_job_day_effect(
  day: Date,
  next: fn(Result(Nil, db_error.DbCommandError)) -> next,
) -> program_types.DbEffect(next) {
  program_types.AnalyticsEffect(
    analytics_algebra.InsertMetricsReliabilityJobDay(day: day, next: next),
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

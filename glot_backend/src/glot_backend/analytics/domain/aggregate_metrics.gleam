import gleam/option.{type Option}
import gleam/order
import gleam/time/calendar.{type Date, type TimeOfDay}
import gleam/time/duration
import gleam/time/timestamp.{type Timestamp}
import glot_backend/analytics/effect/effect as analytics_effect
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{
  type Program, type TransactionProgram,
}
import glot_backend/system/effect/transaction/transaction_effect
import glot_backend/system/effect/transaction/transaction_program
import glot_backend/system/request/context.{type Context}

pub fn aggregate_metrics(ctx: Context) -> Program(Nil) {
  let #(today, _) = calendar_date(ctx.timestamp)

  use maybe_next_day <- program.and_then(next_metrics_day(today))
  case maybe_next_day {
    option.None -> program.succeed(Nil)
    option.Some(day) ->
      case calendar.naive_date_compare(day, today) {
        order.Lt -> transaction_effect.run(aggregate_day_tx(day))
        _ -> program.succeed(Nil)
      }
  }
}

fn next_metrics_day(today: Date) -> Program(Option(Date)) {
  use maybe_max_completed_day <- program.and_then(
    analytics_effect.get_max_completed_metrics_day(),
  )

  case maybe_max_completed_day {
    option.Some(day) -> program.succeed(option.Some(add_days(day, 1)))
    option.None -> analytics_effect.get_first_metrics_source_day(today)
  }
}

fn aggregate_day_tx(day: Date) -> TransactionProgram(Nil) {
  transaction_program.sequence([
    analytics_effect.insert_metrics_pageview_day_tx(day),
    analytics_effect.insert_metrics_product_event_day_tx(day),
    analytics_effect.insert_metrics_run_day_tx(day),
    analytics_effect.insert_metrics_reliability_page_day_tx(day),
    analytics_effect.insert_metrics_reliability_api_day_tx(day),
    analytics_effect.insert_metrics_reliability_job_day_tx(day),
    analytics_effect.insert_metrics_completed_day_tx(day),
  ])
}

fn calendar_date(ts: Timestamp) -> #(Date, TimeOfDay) {
  timestamp.to_calendar(ts, calendar.utc_offset)
}

fn add_days(day: Date, days: Int) -> Date {
  let midnight =
    calendar.TimeOfDay(hours: 0, minutes: 0, seconds: 0, nanoseconds: 0)
  let #(next_day, _) =
    timestamp.from_calendar(day, midnight, calendar.utc_offset)
    |> timestamp.add(duration.seconds(days * 86_400))
    |> timestamp.to_calendar(calendar.utc_offset)

  next_day
}

import gleam/list
import gleam/option
import gleam/result
import gleam/string
import gleam/time/timestamp.{type Timestamp}
import glot_backend/job/adapter/postgres/job/row
import glot_backend/sql
import glot_backend/system/database as db_helpers
import glot_backend/system/effect/error/db_error
import glot_core/job/job_model
import glot_core/pagination_model.{type CursorPagination}
import youid/uuid.{type Uuid}

type FilterParams {
  FilterParams(
    statuses: List(String),
    job_type: option.Option(String),
    periodic_job_id: option.Option(BitArray),
  )
}

pub fn list(
  db: db_helpers.Db,
  filter: job_model.ListJobsFilter,
  pagination: CursorPagination,
) -> Result(List(job_model.Job), db_error.DbQueryError) {
  let params = filter_params(filter)

  case pagination {
    pagination_model.BeforePage(before_id, limit) -> {
      use before_uuid <- result.try(decode_cursor(before_id))
      db_helpers.query(
        db,
        sql.list_jobs_before(
          statuses: params.statuses,
          job_type: params.job_type,
          periodic_job_id: params.periodic_job_id,
          before_id: option.Some(uuid.to_bit_array(before_uuid)),
          page_limit: limit,
        ),
        query_error,
      )
      |> result.try(fn(returned) {
        returned.rows
        |> list.map(row.from_list_before)
        |> result.all
        |> result.map(list.reverse)
      })
    }
    pagination_model.InitialPage(limit)
    | pagination_model.AfterPage(_, limit) -> {
      use after_uuid <- result.try(after_cursor(pagination))
      db_helpers.query(
        db,
        sql.list_jobs_after(
          statuses: params.statuses,
          job_type: params.job_type,
          periodic_job_id: params.periodic_job_id,
          after_id: after_uuid |> option.map(uuid.to_bit_array),
          page_limit: limit,
        ),
        query_error,
      )
      |> result.try(fn(returned) {
        returned.rows
        |> list.map(row.from_list_after)
        |> result.all
      })
    }
  }
}

pub fn summarize(
  db: db_helpers.Db,
  filter: job_model.ListJobsFilter,
  now: Timestamp,
) -> Result(job_model.Summary, db_error.DbQueryError) {
  let params = filter_params(filter)
  use returned <- result.try(db_helpers.query(
    db,
    sql.summarize_jobs(
      statuses: params.statuses,
      job_type: params.job_type,
      periodic_job_id: params.periodic_job_id,
      now: now,
    ),
    query_error,
  ))

  case returned.rows {
    [summary] ->
      Ok(job_model.Summary(
        total_count: summary.total_count,
        pending_count: summary.pending_count,
        running_count: summary.running_count,
        failed_count: summary.failed_count,
        done_count: summary.done_count,
        overdue_count: summary.overdue_count,
      ))
    [] -> Error(db_error.DbQueryError("Expected one jobs summary row"))
    _ -> Error(db_error.DbQueryError("Expected at most one jobs summary row"))
  }
}

pub fn get_next(
  db: db_helpers.Db,
  queue: job_model.Queue,
  now: Timestamp,
  pending_status: job_model.Status,
) -> Result(option.Option(job_model.Job), db_error.DbQueryError) {
  use returned <- result.try(db_helpers.query(
    db,
    sql.get_next_job(
      pending_status: job_model.status_to_string(pending_status),
      queue_name: job_model.queue_to_string(queue),
      now: now,
    ),
    query_error,
  ))

  decode_optional(returned.rows, row.from_next, "Expected at most one job row")
}

pub fn get_expired_running(
  db: db_helpers.Db,
  queue: job_model.Queue,
  now: Timestamp,
  running_status: job_model.Status,
) -> Result(option.Option(job_model.Job), db_error.DbQueryError) {
  use returned <- result.try(db_helpers.query(
    db,
    sql.get_expired_running_job(
      running_status: job_model.status_to_string(running_status),
      queue_name: job_model.queue_to_string(queue),
      now: option.Some(now),
    ),
    query_error,
  ))

  decode_optional(
    returned.rows,
    row.from_expired_running,
    "Expected at most one expired job row",
  )
}

pub fn get_by_id(
  db: db_helpers.Db,
  id: Uuid,
) -> Result(option.Option(job_model.Job), db_error.DbQueryError) {
  use returned <- result.try(db_helpers.query(
    db,
    sql.get_job_by_id(uuid.to_bit_array(id)),
    query_error,
  ))

  decode_optional(returned.rows, row.from_id, "Expected at most one job row")
}

fn decode_optional(
  rows: List(row),
  decoder: fn(row) -> Result(job_model.Job, db_error.DbQueryError),
  unexpected_count_message: String,
) -> Result(option.Option(job_model.Job), db_error.DbQueryError) {
  case rows {
    [] -> Ok(option.None)
    [row] -> decoder(row) |> result.map(option.Some)
    _ -> Error(db_error.DbQueryError(unexpected_count_message))
  }
}

fn filter_params(filter: job_model.ListJobsFilter) -> FilterParams {
  FilterParams(
    statuses: list.map(filter.statuses, job_model.status_to_string),
    job_type: filter.job_type,
    periodic_job_id: filter.periodic_job_id |> option.map(uuid.to_bit_array),
  )
}

fn after_cursor(
  pagination: CursorPagination,
) -> Result(option.Option(Uuid), db_error.DbQueryError) {
  case pagination {
    pagination_model.AfterPage(cursor, _) ->
      decode_cursor(cursor) |> result.map(option.Some)
    pagination_model.InitialPage(_) -> Ok(option.None)
    pagination_model.BeforePage(_, _) -> Ok(option.None)
  }
}

fn decode_cursor(
  cursor: pagination_model.Cursor,
) -> Result(Uuid, db_error.DbQueryError) {
  uuid.from_string(pagination_model.to_string(cursor))
  |> result.map_error(fn(_) { db_error.DbQueryError("Invalid jobs cursor") })
}

fn query_error(error) -> db_error.DbQueryError {
  db_error.DbQueryError(string.inspect(error))
}

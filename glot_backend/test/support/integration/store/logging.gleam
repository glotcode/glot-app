import gleam/dict
import gleam/list
import gleam/time/timestamp
import glot_core/helpers/timestamp_helpers
import glot_core/run_log_model.{type RunLog}
import support/integration/model
import support/integration/store/common

pub fn insert_run_log(db: model.TestState, run_log: RunLog) -> model.TestState {
  model.TestState(
    ..db,
    run_logs: dict.insert(db.run_logs, common.uuid_key(run_log.id), run_log),
    write_steps: ["create_run_log", ..db.write_steps],
  )
}

pub fn delete_run_logs_before(
  db: model.TestState,
  before: timestamp.Timestamp,
) -> model.TestState {
  let before_microseconds = timestamp_helpers.to_microseconds(before)
  let kept_run_logs =
    db.run_logs
    |> dict.to_list
    |> list.filter(fn(entry) {
      let #(_, run_log) = entry
      timestamp_helpers.to_microseconds(run_log.created_at)
      >= before_microseconds
    })
    |> dict.from_list

  model.TestState(..db, run_logs: kept_run_logs)
}

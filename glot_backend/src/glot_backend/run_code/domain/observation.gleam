import gleam/option.{type Option}
import glot_core/run.{type RunResult}
import glot_core/run_log_model.{type RunOutcome}

pub type Observation {
  Observation(
    outcome: RunOutcome,
    duration_ns: Option(Int),
    failure_message: Option(String),
  )
}

pub fn from_run_result(run_result: RunResult) -> Observation {
  case run_result {
    Ok(data) ->
      Observation(
        outcome: run_log_model.RunSucceeded,
        duration_ns: option.Some(data.duration),
        failure_message: option.None,
      )
    Error(data) ->
      Observation(
        outcome: run_log_model.RunFailed,
        duration_ns: option.None,
        failure_message: option.Some(data.message),
      )
  }
}

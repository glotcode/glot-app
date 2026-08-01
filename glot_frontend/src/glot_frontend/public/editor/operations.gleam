import gleam/option
import glot_core/run
import glot_frontend/public/editor/execution_operation
import glot_frontend/public/editor/save_operation
import glot_frontend/request_generation.{type Generation}

pub opaque type Operations {
  Operations(
    execution: execution_operation.Operation,
    save: save_operation.Operation,
    console_owner: ConsoleOwner,
  )
}

pub type ConsoleOwner {
  ExecutionConsole
  SaveConsole
}

pub fn initial() -> Operations {
  Operations(
    execution: execution_operation.initial(),
    save: save_operation.initial(),
    console_owner: ExecutionConsole,
  )
}

pub fn begin_execution(
  operations: Operations,
) -> #(Operations, Generation(execution_operation.Stream)) {
  let #(execution, generation) = execution_operation.begin(operations.execution)
  #(
    Operations(
      ..operations,
      execution: execution,
      console_owner: ExecutionConsole,
    ),
    generation,
  )
}

pub fn begin_save(
  operations: Operations,
) -> #(Operations, Generation(save_operation.Stream)) {
  let #(save, generation) = save_operation.begin(operations.save)
  #(
    Operations(..operations, save: save, console_owner: SaveConsole),
    generation,
  )
}

pub fn complete_execution(
  operations: Operations,
  generation: Generation(execution_operation.Stream),
  result: run.RunResult,
) -> option.Option(Operations) {
  case
    execution_operation.is_current(operations.execution, generation)
    && execution_operation.is_running(operations.execution)
  {
    False -> option.None
    True ->
      option.Some(
        Operations(
          ..operations,
          execution: execution_operation.complete(operations.execution, result),
        ),
      )
  }
}

pub fn fail_execution(
  operations: Operations,
  generation: Generation(execution_operation.Stream),
  message: String,
) -> option.Option(Operations) {
  case
    execution_operation.is_current(operations.execution, generation)
    && execution_operation.is_running(operations.execution)
  {
    False -> option.None
    True ->
      option.Some(
        Operations(
          ..operations,
          execution: execution_operation.fail(operations.execution, message),
        ),
      )
  }
}

pub fn offer_execution_cancellation(
  operations: Operations,
  generation: Generation(execution_operation.Stream),
) -> option.Option(Operations) {
  use execution <- option.map(execution_operation.offer_cancellation(
    operations.execution,
    generation,
  ))
  Operations(..operations, execution: execution)
}

pub fn cancel_execution(operations: Operations) -> option.Option(Operations) {
  use execution <- option.map(execution_operation.cancel(operations.execution))
  Operations(..operations, execution: execution)
}

pub fn succeed_save(
  operations: Operations,
  generation: Generation(save_operation.Stream),
  slug: String,
) -> option.Option(Operations) {
  case save_operation.is_current(operations.save, generation) {
    False -> option.None
    True ->
      option.Some(
        Operations(
          ..operations,
          save: save_operation.succeed(operations.save, slug),
        ),
      )
  }
}

pub fn fail_save(
  operations: Operations,
  generation: Generation(save_operation.Stream),
  message: String,
) -> option.Option(Operations) {
  case save_operation.is_current(operations.save, generation) {
    False -> option.None
    True ->
      option.Some(
        Operations(
          ..operations,
          save: save_operation.fail(operations.save, message),
        ),
      )
  }
}

pub fn record_version_info(
  operations: Operations,
  value: String,
) -> Operations {
  Operations(
    ..operations,
    execution: execution_operation.record_version_info(
      operations.execution,
      value,
    ),
  )
}

pub fn execution_state(operations: Operations) -> execution_operation.State {
  execution_operation.state(operations.execution)
}

pub fn save_state(operations: Operations) -> save_operation.State {
  save_operation.state(operations.save)
}

pub fn version_info(operations: Operations) -> option.Option(String) {
  execution_operation.version_info(operations.execution)
}

pub fn execution_is_running(operations: Operations) -> Bool {
  execution_operation.is_running(operations.execution)
}

pub fn execution_cancellation_is_available(operations: Operations) -> Bool {
  execution_operation.cancellation_is_available(operations.execution)
}

pub fn save_is_saving(operations: Operations) -> Bool {
  save_operation.is_saving(operations.save)
}

pub fn console_owner(operations: Operations) -> ConsoleOwner {
  operations.console_owner
}

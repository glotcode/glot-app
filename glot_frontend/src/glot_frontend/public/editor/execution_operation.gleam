import gleam/option
import glot_core/run
import glot_frontend/request_generation.{type Generation}

pub opaque type Operation {
  Operation(
    generation: Generation(Stream),
    state: State,
    version_info: option.Option(String),
  )
}

pub type Stream {
  Stream
}

pub type State {
  Idle
  Running
  Completed(run.RunResult)
  RequestError(String)
}

pub fn initial() -> Operation {
  Operation(
    generation: request_generation.initial(),
    state: Idle,
    version_info: option.None,
  )
}

pub fn begin(operation: Operation) -> #(Operation, Generation(Stream)) {
  let generation = request_generation.next(operation.generation)
  #(Operation(..operation, generation: generation, state: Running), generation)
}

pub fn is_current(
  operation: Operation,
  generation: Generation(Stream),
) -> Bool {
  request_generation.is_current(operation.generation, generation)
}

pub fn complete(operation: Operation, result: run.RunResult) -> Operation {
  Operation(..operation, state: Completed(result))
}

pub fn fail(operation: Operation, message: String) -> Operation {
  Operation(..operation, state: RequestError(message))
}

pub fn record_version_info(operation: Operation, value: String) -> Operation {
  case value == "" {
    True -> operation
    False -> Operation(..operation, version_info: option.Some(value))
  }
}

pub fn state(operation: Operation) -> State {
  operation.state
}

pub fn version_info(operation: Operation) -> option.Option(String) {
  operation.version_info
}

pub fn is_running(operation: Operation) -> Bool {
  operation.state == Running
}

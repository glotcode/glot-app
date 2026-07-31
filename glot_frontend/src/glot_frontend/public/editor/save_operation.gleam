import glot_frontend/request_generation.{type Generation}

pub opaque type Operation {
  Operation(generation: Generation(Stream), state: State)
}

pub type Stream {
  Stream
}

pub type State {
  SaveIdle
  Saving
  Saved(slug: String)
  SaveError(String)
}

pub fn initial() -> Operation {
  Operation(generation: request_generation.initial(), state: SaveIdle)
}

pub fn begin(operation: Operation) -> #(Operation, Generation(Stream)) {
  let generation = request_generation.next(operation.generation)
  #(Operation(generation: generation, state: Saving), generation)
}

pub fn is_current(
  operation: Operation,
  generation: Generation(Stream),
) -> Bool {
  request_generation.is_current(operation.generation, generation)
}

pub fn succeed(operation: Operation, slug: String) -> Operation {
  Operation(..operation, state: Saved(slug))
}

pub fn fail(operation: Operation, message: String) -> Operation {
  Operation(..operation, state: SaveError(message))
}

pub fn reset_feedback(operation: Operation) -> Operation {
  Operation(..operation, state: SaveIdle)
}

pub fn state(operation: Operation) -> State {
  operation.state
}

pub fn is_saving(operation: Operation) -> Bool {
  operation.state == Saving
}

import glot_frontend/request_generation.{type Generation}

const delay_milliseconds = 1000

pub opaque type State {
  State(generation: Generation(Stream), loading: Bool, visible: Bool)
}

pub type Stream {
  Stream
}

pub fn idle() -> State {
  State(
    generation: request_generation.initial(),
    loading: False,
    visible: False,
  )
}

/// Start loading without choosing an effect implementation. Feature-owned
/// managed effect algebras use the returned generation to schedule a message.
pub fn begin(state: State) -> #(State, Generation(Stream)) {
  let generation = request_generation.next(state.generation)
  #(State(generation:, loading: True, visible: False), generation)
}

pub fn delay() -> Int {
  delay_milliseconds
}

pub fn reveal(state: State, generation: Generation(Stream)) -> State {
  case
    state.loading && request_generation.is_current(state.generation, generation)
  {
    True -> State(..state, visible: True)
    False -> state
  }
}

pub fn finish(state: State) -> State {
  State(..state, loading: False, visible: False)
}

pub fn is_visible(state: State) -> Bool {
  state.loading && state.visible
}

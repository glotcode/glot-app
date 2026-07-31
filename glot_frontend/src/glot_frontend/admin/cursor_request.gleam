import glot_frontend/request_generation.{type Generation}

pub opaque type State {
  State(generation: Generation(request_generation.Shared))
}

pub fn initial() -> State {
  State(request_generation.initial())
}

pub fn begin(state: State) -> #(State, Generation(request_generation.Shared)) {
  let generation = request_generation.next(state.generation)
  #(State(generation), generation)
}

pub fn generation(state: State) -> Generation(request_generation.Shared) {
  state.generation
}

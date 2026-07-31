import glot_frontend/request_generation.{type Generation}

pub type FirstStream {
  FirstStream
}

pub type SecondStream {
  SecondStream
}

pub fn generations_advance_and_only_the_latest_value_is_current_test() {
  let initial: Generation(FirstStream) = request_generation.initial()
  let next = request_generation.next(initial)

  assert request_generation.is_current(initial, initial)
  assert !request_generation.is_current(next, initial)
  assert request_generation.is_current(next, next)
}

pub fn independent_streams_can_start_from_the_same_global_primitive_test() {
  let first: Generation(FirstStream) = request_generation.initial()
  let second: Generation(SecondStream) = request_generation.initial()

  assert request_generation.is_current(first, first)
  assert request_generation.is_current(second, second)
}

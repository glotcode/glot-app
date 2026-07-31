/// Identifies the currently authoritative invocation of an asynchronous
/// request stream. The phantom `stream` type prevents unrelated streams from
/// exchanging generations while the private constructor prevents raw integer
/// construction and comparison.
pub opaque type Generation(stream) {
  Generation(Int)
}

/// Scope for request streams whose surrounding domain type already provides
/// the operation identity.
pub type Shared {
  Shared
}

pub fn initial() -> Generation(stream) {
  Generation(0)
}

pub fn next(generation: Generation(stream)) -> Generation(stream) {
  let Generation(value) = generation
  Generation(value + 1)
}

pub fn is_current(
  current: Generation(stream),
  received: Generation(stream),
) -> Bool {
  current == received
}

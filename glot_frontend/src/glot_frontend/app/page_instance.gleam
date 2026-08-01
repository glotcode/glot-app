/// Identifies one initialized page model. Unlike a route, an instance is never
/// reused when navigation leaves and later returns to the same destination.
pub opaque type PageInstance {
  PageInstance(Int)
}

pub fn initial() -> PageInstance {
  PageInstance(0)
}

pub fn next(instance: PageInstance) -> PageInstance {
  let PageInstance(value) = instance
  PageInstance(value + 1)
}

pub fn is_current(current: PageInstance, received: PageInstance) -> Bool {
  current == received
}

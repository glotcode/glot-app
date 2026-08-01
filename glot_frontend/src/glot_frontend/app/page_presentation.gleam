/// Coordinates the page being prepared by the router with the page currently
/// presented to the user. During a navigation the previous page remains
/// mounted until the destination reaches a presentable state.
pub opaque type Model(page) {
  Model(presented: page, transitioning: Bool)
}

/// Describes what a candidate did to the mounted page. Application roots use
/// this result to coordinate metadata and browser lifecycle effects without
/// reconstructing transition state from booleans.
pub type Transition(page) {
  Held(Model(page))
  Presented(Model(page))
  Updated(Model(page))
}

pub fn init(page: page) -> Model(page) {
  Model(presented: page, transitioning: False)
}

pub fn presented(model: Model(page)) -> page {
  model.presented
}

pub fn is_transitioning(model: Model(page)) -> Bool {
  model.transitioning
}

/// Begin preparing a route. Destinations which need no asynchronous work are
/// presented immediately; all others leave the current page mounted.
pub fn begin(
  model: Model(page),
  candidate: page,
  is_presentable: fn(page) -> Bool,
) -> Transition(page) {
  case is_presentable(candidate) {
    True -> Presented(Model(presented: candidate, transitioning: False))
    False -> Held(Model(..model, transitioning: True))
  }
}

/// Project the latest router model into the presentation. Normal page updates
/// are always reflected. During a transition the candidate is committed only
/// once it is presentable.
pub fn advance(
  model: Model(page),
  candidate: page,
  is_presentable: fn(page) -> Bool,
) -> Transition(page) {
  case model.transitioning, is_presentable(candidate) {
    True, False -> Held(model)
    True, True -> Presented(Model(presented: candidate, transitioning: False))
    False, _ -> Updated(Model(presented: candidate, transitioning: False))
  }
}

pub fn model(transition: Transition(page)) -> Model(page) {
  case transition {
    Held(model) | Presented(model) | Updated(model) -> model
  }
}

pub fn did_present(transition: Transition(page)) -> Bool {
  case transition {
    Presented(_) -> True
    Held(_) | Updated(_) -> False
  }
}

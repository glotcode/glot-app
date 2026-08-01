import gleam/option

pub type Loadable(data) {
  NotLoaded
  Loading
  Loaded(data)
  LoadError(String)
}

pub fn fold(
  state: Loadable(data),
  not_loaded: result,
  loading: result,
  loaded: fn(data) -> result,
  failed: fn(String) -> result,
) -> result {
  case state {
    NotLoaded -> not_loaded
    Loading -> loading
    Loaded(data) -> loaded(data)
    LoadError(message) -> failed(message)
  }
}

pub fn to_option(state: Loadable(data)) -> option.Option(data) {
  case state {
    Loaded(data) -> option.Some(data)
    NotLoaded | Loading | LoadError(_) -> option.None
  }
}

pub fn is_loading(state: Loadable(data)) -> Bool {
  case state {
    Loading -> True
    NotLoaded | Loaded(_) | LoadError(_) -> False
  }
}

/// Whether loading has reached a state that can be meaningfully presented.
/// Both successful values and terminal errors are presentable outcomes.
pub fn is_terminal(state: Loadable(data)) -> Bool {
  case state {
    Loaded(_) | LoadError(_) -> True
    NotLoaded | Loading -> False
  }
}

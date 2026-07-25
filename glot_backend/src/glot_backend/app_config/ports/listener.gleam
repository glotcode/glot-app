import glot_backend/app_config/model/config.{type DynamicConfig}

pub type Listener {
  Listener(updated: fn(DynamicConfig) -> Result(Nil, String))
}

pub fn no_op() -> Listener {
  Listener(updated: fn(_) { Ok(Nil) })
}

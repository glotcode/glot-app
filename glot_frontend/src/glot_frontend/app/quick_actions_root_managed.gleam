import glot_frontend/app/quick_actions
import glot_frontend/app/quick_actions_managed
import glot_web/page/top_bar

pub type Coordinator(model, action, command) {
  Coordinator(
    state: fn(model) -> quick_actions.Model,
    replace_state: fn(model, quick_actions.Model) -> model,
    sections: fn(model) -> List(top_bar.Section(action)),
    none: command,
    open_dialog: command,
    close_dialog: command,
    scroll_to: fn(Int) -> command,
    batch: fn(List(command)) -> command,
    run: fn(model, action) -> #(model, command),
  )
}

pub fn update(
  model: model,
  msg: quick_actions_managed.Msg,
  using coordinator: Coordinator(model, action, command),
) -> #(model, command) {
  let #(state, next) =
    quick_actions_managed.update(
      coordinator.state(model),
      msg,
      coordinator.sections(model),
    )
  let model = coordinator.replace_state(model, state)

  case next {
    quick_actions_managed.None -> #(model, coordinator.none)
    quick_actions_managed.OpenDialog -> #(model, coordinator.open_dialog)
    quick_actions_managed.CloseDialog -> #(model, coordinator.close_dialog)
    quick_actions_managed.ScrollTo(index) -> #(
      model,
      coordinator.scroll_to(index),
    )
    quick_actions_managed.Run(action) -> run(model, action, coordinator)
  }
}

pub fn select(
  model: model,
  action: action,
  using coordinator: Coordinator(model, action, command),
) -> #(model, command) {
  let model =
    coordinator.replace_state(
      model,
      quick_actions.clear_query(coordinator.state(model)),
    )
  run(model, action, coordinator)
}

pub fn reset(
  model: model,
  using coordinator: Coordinator(model, action, command),
) -> #(model, command) {
  #(
    coordinator.replace_state(model, quick_actions.init()),
    coordinator.close_dialog,
  )
}

fn run(
  model: model,
  action: action,
  coordinator: Coordinator(model, action, command),
) -> #(model, command) {
  let #(model, command) = coordinator.run(model, action)
  #(model, coordinator.batch([coordinator.close_dialog, command]))
}

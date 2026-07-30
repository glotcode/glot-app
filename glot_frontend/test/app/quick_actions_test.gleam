import gleam/list
import gleam/option
import gleeunit
import glot_core/route
import glot_frontend/app/public_quick_actions
import glot_frontend/app/quick_actions
import glot_frontend/app/quick_actions_managed
import glot_frontend/app/runtime
import glot_web/page/top_bar

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn changing_query_resets_selection_test() {
  let model = quick_actions.init() |> quick_actions.select(4)
  let changed = quick_actions.set_query(model, "jobs")

  assert changed.query == "jobs"
  assert changed.selected_index == 0
}

pub fn selection_wraps_in_both_directions_test() {
  let model = quick_actions.init()

  assert quick_actions.move(model, -1, 3).selected_index == 2
  assert quick_actions.move(model, 3, 3).selected_index == 0
}

pub fn empty_selection_is_always_zero_test() {
  let model = quick_actions.init() |> quick_actions.select(9)

  assert quick_actions.normalized_index(model, 0) == 0
  assert quick_actions.move(model, 1, 0).selected_index == 0
}

pub fn managed_keyboard_navigation_emits_scroll_command_test() {
  let #(model, command) =
    quick_actions_managed.update(
      quick_actions_managed.init(),
      quick_actions_managed.KeyPressed("ArrowUp"),
      sections(),
    )

  assert model.selected_index == 1
  assert command == quick_actions_managed.ScrollTo(1)
}

pub fn managed_submission_clears_query_and_returns_selected_action_test() {
  let model =
    quick_actions_managed.init()
    |> quick_actions.set_query("second")
    |> quick_actions.select(1)
  let #(model, command) =
    quick_actions_managed.update(
      model,
      quick_actions_managed.Submitted,
      sections(),
    )

  assert model.query == ""
  assert command == quick_actions_managed.Run("second")
}

pub fn managed_dismissal_resets_state_and_requests_dialog_close_test() {
  let model =
    quick_actions_managed.init()
    |> quick_actions.set_query("jobs")
    |> quick_actions.select(1)
  let #(model, command) =
    quick_actions_managed.update(
      model,
      quick_actions_managed.Dismissed,
      sections(),
    )

  assert model == quick_actions.init()
  assert command == quick_actions_managed.CloseDialog
}

pub fn initial_home_actions_keep_the_default_navigation_test() {
  let actions =
    public_quick_actions.sections(
      runtime.LoadingSession,
      route.Public(route.Home),
      "",
      [],
      route.to_string,
    )

  assert list.length(actions) == 2
  let assert [top_bar.Section(title: "Navigation", ..), ..] = actions
}

pub fn page_actions_participate_in_filtering_and_selection_test() {
  let page_action = action("Fixture action", "fixture")
  let sections =
    public_quick_actions.sections(
      runtime.LoadingSession,
      route.Public(route.Contact),
      "fixture",
      [page_action],
      route.to_string,
    )
  let assert option.Some(top_bar.Action(msg: selected, ..)) =
    public_quick_actions.selected(quick_actions.init(), sections)

  assert selected == "fixture"
}

fn sections() -> List(top_bar.Section(String)) {
  [
    top_bar.Section(title: "Fixture", actions: [
      action("First", "first"),
      action("Second", "second"),
    ]),
  ]
}

fn action(label: String, message: String) -> top_bar.Action(String) {
  top_bar.Action(
    label:,
    description: "",
    shortcut: [],
    target_route: option.None,
    msg: message,
  )
}

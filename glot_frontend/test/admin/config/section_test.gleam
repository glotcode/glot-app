import gleam/option
import gleeunit
import glot_frontend/admin/config/section
import glot_frontend/ui/mutation

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn edits_are_resettable_and_saved_atomically_test() {
  let initial = section.init(#("old", False))
  let #(loading, load_generation) = section.begin_load(initial)
  let assert option.Some(loaded) =
    section.loaded(loading, load_generation, #("old", False))
  let edited = section.edit(loaded, fn(_) { #("new", True) })

  assert section.is_dirty(edited)
  assert section.reset(edited).draft == #("old", False)

  let #(saving, save_generation) = section.begin_save(edited)
  let assert option.Some(saved) =
    section.saved(saving, save_generation, edited.draft)
  assert !section.is_dirty(saved)
  assert saved.saved == #("new", True)
  assert saved.mutation_state == mutation.Saved
}

pub fn load_and_save_failures_remain_independent_test() {
  let model = section.init(0)
  let #(loading, load_generation) = section.begin_load(model)
  let assert option.Some(load_failed) =
    section.load_failed(loading, load_generation, "load")
  let #(saving, save_generation) = section.begin_save(load_failed)
  let assert option.Some(save_failed) =
    section.save_failed(saving, save_generation, "save")

  assert save_failed.load_state == section.LoadError("load")
  assert save_failed.mutation_state == mutation.SaveError("save")
}

pub fn stale_load_and_save_completions_are_rejected_test() {
  let initial = section.init("initial")
  let #(first_loading, first_load) = section.begin_load(initial)
  let #(second_loading, second_load) = section.begin_load(first_loading)

  assert section.loaded(second_loading, first_load, "stale") == option.None
  assert section.load_failed(second_loading, first_load, "stale") == option.None
  let assert option.Some(loaded) =
    section.loaded(second_loading, second_load, "current")

  let #(first_saving, first_save) = section.begin_save(loaded)
  let #(second_saving, second_save) = section.begin_save(first_saving)

  assert section.saved(second_saving, first_save, "stale") == option.None
  assert section.save_failed(second_saving, first_save, "stale") == option.None
  let assert option.Some(saved) =
    section.saved(second_saving, second_save, "current")
  assert saved.saved == "current"
}

pub fn edits_and_resets_invalidate_pending_saves_test() {
  let initial = section.init("initial")
  let #(saving_before_edit, edit_save) = section.begin_save(initial)
  let edited = section.edit(saving_before_edit, fn(_) { "edited" })

  assert section.saved(edited, edit_save, "stale") == option.None
  assert edited.mutation_state == mutation.Idle

  let #(saving_before_reset, reset_save) = section.begin_save(edited)
  let reset = section.reset(saving_before_reset)

  assert section.save_failed(reset, reset_save, "stale") == option.None
  assert reset.draft == "initial"
  assert reset.mutation_state == mutation.Idle
}

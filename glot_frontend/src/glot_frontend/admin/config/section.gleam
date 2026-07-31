import glot_frontend/request_generation.{type Generation}
import glot_frontend/ui/mutation

pub type LoadState {
  NotLoaded
  Loading
  Ready
  LoadError(String)
}

pub type FormModel(fields) {
  FormModel(
    load_state: LoadState,
    saved: fields,
    draft: fields,
    mutation_state: mutation.MutationState,
    load_generation: Generation(LoadStream),
    save_generation: Generation(SaveStream),
  )
}

pub type LoadStream {
  LoadStream
}

pub type SaveStream {
  SaveStream
}

pub fn init(fields: fields) -> FormModel(fields) {
  FormModel(
    load_state: NotLoaded,
    saved: fields,
    draft: fields,
    mutation_state: mutation.Idle,
    load_generation: request_generation.initial(),
    save_generation: request_generation.initial(),
  )
}

pub fn begin_load(model: FormModel(fields)) -> FormModel(fields) {
  FormModel(
    ..model,
    load_state: Loading,
    load_generation: request_generation.next(model.load_generation),
  )
}

pub fn loaded(model: FormModel(fields), fields: fields) -> FormModel(fields) {
  FormModel(
    load_state: Ready,
    saved: fields,
    draft: fields,
    mutation_state: mutation.Idle,
    load_generation: model.load_generation,
    save_generation: model.save_generation,
  )
}

pub fn load_failed(
  model: FormModel(fields),
  message: String,
) -> FormModel(fields) {
  FormModel(..model, load_state: LoadError(message))
}

pub fn edit(
  model: FormModel(fields),
  change: fn(fields) -> fields,
) -> FormModel(fields) {
  FormModel(
    ..model,
    draft: change(model.draft),
    mutation_state: mutation.Idle,
    save_generation: request_generation.next(model.save_generation),
  )
}

pub fn reset(model: FormModel(fields)) -> FormModel(fields) {
  FormModel(
    ..model,
    draft: model.saved,
    mutation_state: mutation.Idle,
    save_generation: request_generation.next(model.save_generation),
  )
}

pub fn begin_save(model: FormModel(fields)) -> FormModel(fields) {
  FormModel(
    ..model,
    mutation_state: mutation.Saving,
    save_generation: request_generation.next(model.save_generation),
  )
}

pub fn is_current_load(
  model: FormModel(fields),
  generation: Generation(LoadStream),
) -> Bool {
  request_generation.is_current(model.load_generation, generation)
}

pub fn is_current_save(
  model: FormModel(fields),
  generation: Generation(SaveStream),
) -> Bool {
  request_generation.is_current(model.save_generation, generation)
}

pub fn saved(model: FormModel(fields), fields: fields) -> FormModel(fields) {
  FormModel(
    ..model,
    saved: fields,
    draft: fields,
    mutation_state: mutation.Saved,
  )
}

pub fn save_failed(
  model: FormModel(fields),
  message: String,
) -> FormModel(fields) {
  FormModel(..model, mutation_state: mutation.SaveError(message))
}

pub fn is_dirty(model: FormModel(fields)) -> Bool {
  model.saved != model.draft
}

pub fn is_ready(state: LoadState) -> Bool {
  state == Ready
}

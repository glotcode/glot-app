import gleam/option
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
    requests: Requests,
  )
}

pub opaque type Requests {
  Requests(
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
    requests: Requests(
      load_generation: request_generation.initial(),
      save_generation: request_generation.initial(),
    ),
  )
}

pub fn is_presentable(model: FormModel(fields)) -> Bool {
  case model.load_state {
    Ready | LoadError(_) -> True
    NotLoaded | Loading -> False
  }
}

pub fn begin_load(
  model: FormModel(fields),
) -> #(FormModel(fields), Generation(LoadStream)) {
  let generation = request_generation.next(model.requests.load_generation)
  #(
    FormModel(
      ..model,
      load_state: Loading,
      requests: Requests(..model.requests, load_generation: generation),
    ),
    generation,
  )
}

pub fn loaded(
  model: FormModel(fields),
  generation: Generation(LoadStream),
  fields: fields,
) -> option.Option(FormModel(fields)) {
  case is_current_load(model, generation) {
    False -> option.None
    True ->
      option.Some(
        FormModel(
          ..model,
          load_state: Ready,
          saved: fields,
          draft: fields,
          mutation_state: mutation.Idle,
        ),
      )
  }
}

pub fn load_failed(
  model: FormModel(fields),
  generation: Generation(LoadStream),
  message: String,
) -> option.Option(FormModel(fields)) {
  case is_current_load(model, generation) {
    False -> option.None
    True -> option.Some(FormModel(..model, load_state: LoadError(message)))
  }
}

pub fn edit(
  model: FormModel(fields),
  change: fn(fields) -> fields,
) -> FormModel(fields) {
  let save_generation = request_generation.next(model.requests.save_generation)
  FormModel(
    ..model,
    draft: change(model.draft),
    mutation_state: mutation.Idle,
    requests: Requests(..model.requests, save_generation: save_generation),
  )
}

pub fn reset(model: FormModel(fields)) -> FormModel(fields) {
  let save_generation = request_generation.next(model.requests.save_generation)
  FormModel(
    ..model,
    draft: model.saved,
    mutation_state: mutation.Idle,
    requests: Requests(..model.requests, save_generation: save_generation),
  )
}

pub fn begin_save(
  model: FormModel(fields),
) -> #(FormModel(fields), Generation(SaveStream)) {
  let generation = request_generation.next(model.requests.save_generation)
  #(
    FormModel(
      ..model,
      mutation_state: mutation.Saving,
      requests: Requests(..model.requests, save_generation: generation),
    ),
    generation,
  )
}

fn is_current_load(
  model: FormModel(fields),
  generation: Generation(LoadStream),
) -> Bool {
  request_generation.is_current(model.requests.load_generation, generation)
}

fn is_current_save(
  model: FormModel(fields),
  generation: Generation(SaveStream),
) -> Bool {
  request_generation.is_current(model.requests.save_generation, generation)
}

pub fn saved(
  model: FormModel(fields),
  generation: Generation(SaveStream),
  fields: fields,
) -> option.Option(FormModel(fields)) {
  case is_current_save(model, generation) {
    False -> option.None
    True ->
      option.Some(
        FormModel(
          ..model,
          saved: fields,
          draft: fields,
          mutation_state: mutation.Saved,
        ),
      )
  }
}

pub fn save_failed(
  model: FormModel(fields),
  generation: Generation(SaveStream),
  message: String,
) -> option.Option(FormModel(fields)) {
  case is_current_save(model, generation) {
    False -> option.None
    True ->
      option.Some(
        FormModel(..model, mutation_state: mutation.SaveError(message)),
      )
  }
}

pub fn validation_failed(
  model: FormModel(fields),
  message: String,
) -> FormModel(fields) {
  FormModel(..model, mutation_state: mutation.SaveError(message))
}

pub fn resolve(
  model: FormModel(fields),
  completion: option.Option(FormModel(fields)),
) -> FormModel(fields) {
  option.unwrap(completion, model)
}

pub fn is_dirty(model: FormModel(fields)) -> Bool {
  model.saved != model.draft
}

pub fn is_ready(state: LoadState) -> Bool {
  state == Ready
}

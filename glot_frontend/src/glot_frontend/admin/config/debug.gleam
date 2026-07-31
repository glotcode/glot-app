import glot_core/admin/debug_config_dto
import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/config/section
import glot_frontend/api/response as api_response
import glot_frontend/request_generation.{type Generation}
import glot_frontend/ui/mutation

pub type Model {
  Model(
    load_state: section.LoadState,
    saved: Fields,
    draft: Fields,
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

pub type Fields {
  Fields(enabled: Bool)
}

pub type Msg {
  Loaded(
    Generation(LoadStream),
    api_response.Response(debug_config_dto.DebugConfigResponse),
  )
  ToggleClicked
  ResetClicked
  SaveClicked
  SaveFinished(
    Generation(SaveStream),
    api_response.Response(debug_config_dto.DebugConfigResponse),
  )
}

pub fn init() -> Model {
  let fields = Fields(enabled: False)
  Model(
    load_state: section.NotLoaded,
    saved: fields,
    draft: fields,
    mutation_state: mutation.Idle,
    load_generation: request_generation.initial(),
    save_generation: request_generation.initial(),
  )
}

pub fn ensure_loaded(model: Model) -> #(Model, admin_effect.Command(Msg)) {
  case model.load_state {
    section.NotLoaded -> #(
      Model(
        ..model,
        load_state: section.Loading,
        load_generation: request_generation.next(model.load_generation),
      ),
      admin_effect.get_admin_debug_config(fn(result) {
        Loaded(request_generation.next(model.load_generation), result)
      }),
    )
    section.Loading | section.Ready | section.LoadError(_) -> #(
      model,
      admin_effect.none(),
    )
  }
}

pub fn update(model: Model, msg: Msg) -> #(Model, admin_effect.Command(Msg)) {
  case msg {
    Loaded(generation, _) if generation != model.load_generation -> #(
      model,
      admin_effect.none(),
    )
    Loaded(_, result) ->
      case result {
        api_response.Success(response) -> {
          let fields = Fields(enabled: response.enabled)
          #(
            Model(
              load_state: section.Ready,
              saved: fields,
              draft: fields,
              mutation_state: mutation.Idle,
              load_generation: model.load_generation,
              save_generation: model.save_generation,
            ),
            admin_effect.none(),
          )
        }
        api_response.ApiFailure(error) -> #(
          Model(
            ..model,
            load_state: section.LoadError(api_response.error_message(error)),
          ),
          admin_effect.none(),
        )
        api_response.HttpFailure(_) -> #(
          Model(
            ..model,
            load_state: section.LoadError("Could not load debug config."),
          ),
          admin_effect.none(),
        )
      }
    ToggleClicked -> #(
      Model(
        ..model,
        draft: Fields(enabled: !model.draft.enabled),
        mutation_state: mutation.Idle,
        save_generation: request_generation.next(model.save_generation),
      ),
      admin_effect.none(),
    )
    ResetClicked -> #(
      Model(
        ..model,
        draft: model.saved,
        mutation_state: mutation.Idle,
        save_generation: request_generation.next(model.save_generation),
      ),
      admin_effect.none(),
    )
    SaveClicked -> #(
      Model(
        ..model,
        mutation_state: mutation.Saving,
        save_generation: request_generation.next(model.save_generation),
      ),
      admin_effect.upsert_admin_debug_config(
        debug_config_dto.UpsertDebugConfigRequest(enabled: model.draft.enabled),
        fn(result) {
          SaveFinished(request_generation.next(model.save_generation), result)
        },
      ),
    )
    SaveFinished(generation, _) if generation != model.save_generation -> #(
      model,
      admin_effect.none(),
    )
    SaveFinished(_, result) ->
      case result {
        api_response.Success(response) -> {
          let fields = Fields(enabled: response.enabled)
          #(
            Model(
              ..model,
              saved: fields,
              draft: fields,
              mutation_state: mutation.Saved,
            ),
            admin_effect.none(),
          )
        }
        api_response.ApiFailure(error) -> #(
          Model(
            ..model,
            mutation_state: mutation.SaveError(api_response.error_message(error)),
          ),
          admin_effect.none(),
        )
        api_response.HttpFailure(_) -> #(
          Model(
            ..model,
            mutation_state: mutation.SaveError("Could not save debug config."),
          ),
          admin_effect.none(),
        )
      }
  }
}

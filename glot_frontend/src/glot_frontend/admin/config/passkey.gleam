import gleam/int
import gleam/result
import glot_core/admin/passkey_config_dto
import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/config/section
import glot_frontend/admin/ui/format as admin_format
import glot_frontend/api/response as api_response
import glot_frontend/request_generation.{type Generation}

pub type Fields {
  Fields(origin: String, rp_id: String, challenge_timeout_seconds: String)
}

pub type Model =
  section.FormModel(Fields)

pub type Msg {
  Loaded(
    Generation(section.LoadStream),
    api_response.Response(passkey_config_dto.PasskeyConfigResponse),
  )
  OriginChanged(String)
  RpIdChanged(String)
  ChallengeTimeoutSecondsChanged(String)
  ResetClicked
  SaveClicked
  SaveFinished(
    Generation(section.SaveStream),
    api_response.Response(passkey_config_dto.PasskeyConfigResponse),
  )
}

pub fn init() -> Model {
  section.init(Fields(origin: "", rp_id: "", challenge_timeout_seconds: ""))
}

pub fn ensure_loaded(model: Model) -> #(Model, admin_effect.Command(Msg)) {
  case model.load_state {
    section.NotLoaded -> #(
      section.begin_load(model),
      admin_effect.get_admin_passkey_config(fn(result) {
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
        api_response.Success(response) -> #(
          section.loaded(model, from_response(response)),
          admin_effect.none(),
        )
        api_response.ApiFailure(error) -> #(
          section.load_failed(model, api_response.error_message(error)),
          admin_effect.none(),
        )
        api_response.HttpFailure(_) -> #(
          section.load_failed(model, "Could not load passkey config."),
          admin_effect.none(),
        )
      }
    OriginChanged(origin) -> #(
      section.edit(model, fn(f) { Fields(..f, origin:) }),
      admin_effect.none(),
    )
    RpIdChanged(rp_id) -> #(
      section.edit(model, fn(f) { Fields(..f, rp_id:) }),
      admin_effect.none(),
    )
    ChallengeTimeoutSecondsChanged(challenge_timeout_seconds) -> #(
      section.edit(model, fn(f) { Fields(..f, challenge_timeout_seconds:) }),
      admin_effect.none(),
    )
    ResetClicked -> #(section.reset(model), admin_effect.none())
    SaveClicked ->
      case request(model.draft) {
        Ok(request) -> #(
          section.begin_save(model),
          admin_effect.upsert_admin_passkey_config(request, fn(result) {
            SaveFinished(request_generation.next(model.save_generation), result)
          }),
        )
        Error(message) -> #(
          section.save_failed(model, message),
          admin_effect.none(),
        )
      }
    SaveFinished(generation, _) if generation != model.save_generation -> #(
      model,
      admin_effect.none(),
    )
    SaveFinished(_, result) ->
      case result {
        api_response.Success(response) -> #(
          section.saved(model, from_response(response)),
          admin_effect.none(),
        )
        api_response.ApiFailure(error) -> #(
          section.save_failed(model, api_response.error_message(error)),
          admin_effect.none(),
        )
        api_response.HttpFailure(_) -> #(
          section.save_failed(model, "Could not save passkey config."),
          admin_effect.none(),
        )
      }
  }
}

fn from_response(response: passkey_config_dto.PasskeyConfigResponse) -> Fields {
  Fields(
    origin: response.origin,
    rp_id: response.rp_id,
    challenge_timeout_seconds: int.to_string(response.challenge_timeout_seconds),
  )
}

fn request(
  fields: Fields,
) -> Result(passkey_config_dto.UpsertPasskeyConfigRequest, String) {
  use challenge_timeout_seconds <- result.try(
    admin_format.parse_positive_int_with_error(
      fields.challenge_timeout_seconds,
      "Challenge timeout must be a positive integer.",
    ),
  )
  case fields.origin, fields.rp_id {
    "", _ -> Error("Origin must not be empty.")
    _, "" -> Error("RP ID must not be empty.")
    _, _ ->
      Ok(passkey_config_dto.UpsertPasskeyConfigRequest(
        origin: fields.origin,
        rp_id: fields.rp_id,
        challenge_timeout_seconds:,
      ))
  }
}

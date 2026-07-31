import gleam/int
import gleam/option
import gleam/result
import glot_core/admin/availability_config_dto
import glot_core/availability_mode
import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/config/section
import glot_frontend/admin/ui/format as admin_format
import glot_frontend/api/response as api_response
import glot_frontend/request_generation.{type Generation}

pub type Fields {
  Fields(
    mode: availability_mode.AvailabilityMode,
    message: String,
    retry_after_seconds: String,
  )
}

pub type Model =
  section.FormModel(Fields)

pub type Msg {
  Loaded(
    Generation(section.LoadStream),
    api_response.Response(availability_config_dto.AvailabilityConfigResponse),
  )
  ModeSelected(availability_mode.AvailabilityMode)
  MessageChanged(String)
  RetryAfterSecondsChanged(String)
  ResetClicked
  SaveClicked
  SaveFinished(
    Generation(section.SaveStream),
    api_response.Response(availability_config_dto.AvailabilityConfigResponse),
  )
}

pub fn init() -> Model {
  section.init(Fields(
    mode: availability_mode.NormalMode,
    message: "glot.io is temporarily unavailable right now.",
    retry_after_seconds: "",
  ))
}

pub fn ensure_loaded(model: Model) -> #(Model, admin_effect.Command(Msg)) {
  case model.load_state {
    section.NotLoaded -> #(
      section.begin_load(model),
      admin_effect.get_admin_availability_config(fn(result) {
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
          section.loaded(model, fields_from_response(response)),
          admin_effect.none(),
        )
        api_response.ApiFailure(error) -> #(
          section.load_failed(model, api_response.error_message(error)),
          admin_effect.none(),
        )
        api_response.HttpFailure(_) -> #(
          section.load_failed(model, "Could not load availability config."),
          admin_effect.none(),
        )
      }
    ModeSelected(mode) -> #(
      section.edit(model, fn(fields) { Fields(..fields, mode:) }),
      admin_effect.none(),
    )
    MessageChanged(message) -> #(
      section.edit(model, fn(fields) { Fields(..fields, message:) }),
      admin_effect.none(),
    )
    RetryAfterSecondsChanged(retry_after_seconds) -> #(
      section.edit(model, fn(fields) { Fields(..fields, retry_after_seconds:) }),
      admin_effect.none(),
    )
    ResetClicked -> #(section.reset(model), admin_effect.none())
    SaveClicked ->
      case request(model.draft) {
        Ok(request) -> #(
          section.begin_save(model),
          admin_effect.upsert_admin_availability_config(request, fn(result) {
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
          section.saved(model, fields_from_response(response)),
          admin_effect.none(),
        )
        api_response.ApiFailure(error) -> #(
          section.save_failed(model, api_response.error_message(error)),
          admin_effect.none(),
        )
        api_response.HttpFailure(_) -> #(
          section.save_failed(model, "Could not save availability config."),
          admin_effect.none(),
        )
      }
  }
}

fn fields_from_response(
  response: availability_config_dto.AvailabilityConfigResponse,
) -> Fields {
  Fields(
    mode: response.mode,
    message: response.message,
    retry_after_seconds: option.map(response.retry_after_seconds, int.to_string)
      |> option.unwrap(""),
  )
}

fn request(
  fields: Fields,
) -> Result(availability_config_dto.UpsertAvailabilityConfigRequest, String) {
  let retry_after_seconds = case fields.retry_after_seconds {
    "" -> Ok(option.None)
    value ->
      admin_format.parse_positive_int_with_error(
        value,
        "Retry-After seconds must be a positive integer.",
      )
      |> result.map(option.Some)
  }
  use retry_after_seconds <- result.try(retry_after_seconds)
  case fields.message {
    "" -> Error("Availability message must not be empty.")
    _ ->
      Ok(availability_config_dto.UpsertAvailabilityConfigRequest(
        mode: fields.mode,
        message: fields.message,
        retry_after_seconds:,
      ))
  }
}

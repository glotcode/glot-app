import gleam/int
import gleam/result
import glot_core/admin/docker_run_config_dto
import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/config/section
import glot_frontend/admin/ui/format as admin_format
import glot_frontend/api/response as api_response
import glot_frontend/request_generation.{type Generation}

pub type Fields {
  Fields(base_url: String, access_token: String, default_timeout_ms: String)
}

pub type Model =
  section.FormModel(Fields)

pub type Field {
  BaseUrl
  AccessToken
  DefaultTimeout
}

pub type Msg {
  Loaded(
    Generation(section.LoadStream),
    api_response.Response(docker_run_config_dto.DockerRunConfigResponse),
  )
  FieldChanged(Field, String)
  ResetClicked
  SaveClicked
  SaveFinished(
    Generation(section.SaveStream),
    api_response.Response(docker_run_config_dto.DockerRunConfigResponse),
  )
}

fn empty() -> Fields {
  Fields("", "", "")
}

pub fn is_empty(fields: Fields) -> Bool {
  fields == empty()
}

pub fn init() -> Model {
  section.init(empty())
}

pub fn ensure_loaded(model: Model) -> #(Model, admin_effect.Command(Msg)) {
  case model.load_state {
    section.NotLoaded -> #(
      section.begin_load(model),
      admin_effect.get_admin_docker_run_config(fn(result) {
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
        api_response.ApiFailure(error) ->
          case error.code {
            "docker_run_config_not_found" -> #(
              section.loaded(model, empty()),
              admin_effect.none(),
            )
            _ -> #(
              section.load_failed(model, api_response.error_message(error)),
              admin_effect.none(),
            )
          }
        api_response.HttpFailure(_) -> #(
          section.load_failed(model, "Could not load docker run config."),
          admin_effect.none(),
        )
      }
    FieldChanged(field, value) -> #(
      section.edit(model, fn(fields) { set(fields, field, value) }),
      admin_effect.none(),
    )
    ResetClicked -> #(section.reset(model), admin_effect.none())
    SaveClicked ->
      case request(model.draft) {
        Ok(request) -> #(
          section.begin_save(model),
          admin_effect.upsert_admin_docker_run_config(request, fn(result) {
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
          section.save_failed(model, "Could not save docker run config."),
          admin_effect.none(),
        )
      }
  }
}

fn set(fields: Fields, field: Field, value: String) -> Fields {
  case field {
    BaseUrl -> Fields(..fields, base_url: value)
    AccessToken -> Fields(..fields, access_token: value)
    DefaultTimeout -> Fields(..fields, default_timeout_ms: value)
  }
}

fn from_response(
  response: docker_run_config_dto.DockerRunConfigResponse,
) -> Fields {
  Fields(
    response.base_url,
    response.access_token,
    int.to_string(response.default_timeout_ms),
  )
}

fn request(
  fields: Fields,
) -> Result(docker_run_config_dto.UpsertDockerRunConfigRequest, String) {
  use default_timeout_ms <- result.try(
    admin_format.parse_positive_int_with_error(
      fields.default_timeout_ms,
      "Default timeout must be a positive integer.",
    ),
  )
  case fields.base_url, fields.access_token {
    "", _ -> Error("Base URL must not be empty.")
    _, "" -> Error("Access token must not be empty.")
    _, _ ->
      Ok(docker_run_config_dto.UpsertDockerRunConfigRequest(
        base_url: fields.base_url,
        access_token: fields.access_token,
        default_timeout_ms:,
      ))
  }
}

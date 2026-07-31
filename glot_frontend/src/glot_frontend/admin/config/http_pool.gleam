import gleam/int
import gleam/result
import glot_core/admin/http_pool_config_dto
import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/config/section
import glot_frontend/admin/ui/format as admin_format
import glot_frontend/api/response as api_response
import glot_frontend/request_generation.{type Generation}

pub type Fields {
  Fields(
    docker_run_max_sessions: String,
    cloudflare_email_max_sessions: String,
    keep_alive_timeout_ms: String,
  )
}

pub type Model =
  section.FormModel(Fields)

pub type Field {
  DockerRunMaxSessions
  CloudflareEmailMaxSessions
  KeepAliveTimeout
}

pub type Msg {
  Loaded(
    Generation(section.LoadStream),
    api_response.Response(http_pool_config_dto.HttpPoolConfigResponse),
  )
  FieldChanged(Field, String)
  ResetClicked
  SaveClicked
  SaveFinished(
    Generation(section.SaveStream),
    api_response.Response(http_pool_config_dto.HttpPoolConfigResponse),
  )
}

pub fn init() -> Model {
  section.init(Fields("", "", ""))
}

pub fn ensure_loaded(model: Model) -> #(Model, admin_effect.Command(Msg)) {
  case model.load_state {
    section.NotLoaded -> #(
      section.begin_load(model),
      admin_effect.get_admin_http_pool_config(fn(result) {
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
          section.load_failed(model, "Could not load HTTP pool config."),
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
          admin_effect.upsert_admin_http_pool_config(request, fn(result) {
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
          section.save_failed(model, "Could not save HTTP pool config."),
          admin_effect.none(),
        )
      }
  }
}

fn set(fields: Fields, field: Field, value: String) -> Fields {
  case field {
    DockerRunMaxSessions -> Fields(..fields, docker_run_max_sessions: value)
    CloudflareEmailMaxSessions ->
      Fields(..fields, cloudflare_email_max_sessions: value)
    KeepAliveTimeout -> Fields(..fields, keep_alive_timeout_ms: value)
  }
}

fn from_response(
  response: http_pool_config_dto.HttpPoolConfigResponse,
) -> Fields {
  Fields(
    int.to_string(response.docker_run_max_sessions),
    int.to_string(response.cloudflare_email_max_sessions),
    int.to_string(response.keep_alive_timeout_ms),
  )
}

fn request(
  fields: Fields,
) -> Result(http_pool_config_dto.UpsertHttpPoolConfigRequest, String) {
  use docker_run_max_sessions <- result.try(
    admin_format.parse_positive_int_with_error(
      fields.docker_run_max_sessions,
      "Docker-run max sessions must be a positive integer.",
    ),
  )
  use cloudflare_email_max_sessions <- result.try(
    admin_format.parse_positive_int_with_error(
      fields.cloudflare_email_max_sessions,
      "Cloudflare email max sessions must be a positive integer.",
    ),
  )
  use keep_alive_timeout_ms <- result.try(
    admin_format.parse_positive_int_with_error(
      fields.keep_alive_timeout_ms,
      "Keep-alive timeout must be a positive integer.",
    ),
  )

  Ok(http_pool_config_dto.UpsertHttpPoolConfigRequest(
    docker_run_max_sessions:,
    cloudflare_email_max_sessions:,
    keep_alive_timeout_ms:,
  ))
}

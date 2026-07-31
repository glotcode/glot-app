import gleam/int
import gleam/result
import glot_core/admin/auth_config_dto
import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/config/section
import glot_frontend/admin/ui/format as admin_format
import glot_frontend/api/response as api_response
import glot_frontend/request_generation.{type Generation}

pub type Fields {
  Fields(
    login_token_max_age: String,
    session_token_max_age: String,
    session_idle_timeout_seconds: String,
    session_cookie_max_age: String,
    session_refresh_interval_seconds: String,
    session_previous_token_grace_seconds: String,
    session_heartbeat_interval_seconds: String,
  )
}

pub type Model =
  section.FormModel(Fields)

pub type Field {
  LoginTokenMaxAge
  SessionTokenMaxAge
  SessionIdleTimeout
  SessionCookieMaxAge
  SessionRefreshInterval
  PreviousTokenGrace
  HeartbeatInterval
}

pub type Msg {
  Loaded(
    Generation(section.LoadStream),
    api_response.Response(auth_config_dto.AuthConfigResponse),
  )
  FieldChanged(Field, String)
  ResetClicked
  SaveClicked
  SaveFinished(
    Generation(section.SaveStream),
    api_response.Response(auth_config_dto.AuthConfigResponse),
  )
}

pub fn init() -> Model {
  section.init(Fields("", "", "", "", "", "", ""))
}

pub fn ensure_loaded(model: Model) -> #(Model, admin_effect.Command(Msg)) {
  case model.load_state {
    section.NotLoaded -> #(
      section.begin_load(model),
      admin_effect.get_admin_auth_config(fn(result) {
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
          section.load_failed(model, "Could not load auth config."),
          admin_effect.none(),
        )
      }
    FieldChanged(field, value) -> #(
      section.edit(model, fn(fields) { set_field(fields, field, value) }),
      admin_effect.none(),
    )
    ResetClicked -> #(section.reset(model), admin_effect.none())
    SaveClicked ->
      case request(model.draft) {
        Ok(request) -> #(
          section.begin_save(model),
          admin_effect.upsert_admin_auth_config(request, fn(result) {
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
          section.save_failed(model, "Could not save auth config."),
          admin_effect.none(),
        )
      }
  }
}

fn set_field(fields: Fields, field: Field, value: String) -> Fields {
  case field {
    LoginTokenMaxAge -> Fields(..fields, login_token_max_age: value)
    SessionTokenMaxAge -> Fields(..fields, session_token_max_age: value)
    SessionIdleTimeout -> Fields(..fields, session_idle_timeout_seconds: value)
    SessionCookieMaxAge -> Fields(..fields, session_cookie_max_age: value)
    SessionRefreshInterval ->
      Fields(..fields, session_refresh_interval_seconds: value)
    PreviousTokenGrace ->
      Fields(..fields, session_previous_token_grace_seconds: value)
    HeartbeatInterval ->
      Fields(..fields, session_heartbeat_interval_seconds: value)
  }
}

fn from_response(response: auth_config_dto.AuthConfigResponse) -> Fields {
  Fields(
    login_token_max_age: int.to_string(response.login_token_max_age),
    session_token_max_age: int.to_string(response.session_token_max_age),
    session_idle_timeout_seconds: int.to_string(
      response.session_idle_timeout_seconds,
    ),
    session_cookie_max_age: int.to_string(response.session_cookie_max_age),
    session_refresh_interval_seconds: int.to_string(
      response.session_refresh_interval_seconds,
    ),
    session_previous_token_grace_seconds: int.to_string(
      response.session_previous_token_grace_seconds,
    ),
    session_heartbeat_interval_seconds: int.to_string(
      response.session_heartbeat_interval_seconds,
    ),
  )
}

fn positive(value: String, message: String) -> Result(Int, String) {
  admin_format.parse_positive_int_with_error(value, message)
}

fn request(
  fields: Fields,
) -> Result(auth_config_dto.UpsertAuthConfigRequest, String) {
  use login_token_max_age <- result.try(positive(
    fields.login_token_max_age,
    "Login token max age must be a positive integer.",
  ))
  use session_token_max_age <- result.try(positive(
    fields.session_token_max_age,
    "Session max lifetime must be a positive integer.",
  ))
  use session_idle_timeout_seconds <- result.try(positive(
    fields.session_idle_timeout_seconds,
    "Session idle timeout must be a positive integer.",
  ))
  use session_cookie_max_age <- result.try(positive(
    fields.session_cookie_max_age,
    "Session cookie max age must be a positive integer.",
  ))
  use session_refresh_interval_seconds <- result.try(positive(
    fields.session_refresh_interval_seconds,
    "Session rotation interval must be a positive integer.",
  ))
  use session_previous_token_grace_seconds <- result.try(positive(
    fields.session_previous_token_grace_seconds,
    "Previous token grace window must be a positive integer.",
  ))
  use session_heartbeat_interval_seconds <- result.try(positive(
    fields.session_heartbeat_interval_seconds,
    "Heartbeat cadence must be a positive integer.",
  ))
  Ok(auth_config_dto.UpsertAuthConfigRequest(
    login_token_max_age:,
    session_token_max_age:,
    session_idle_timeout_seconds:,
    session_cookie_max_age:,
    session_refresh_interval_seconds:,
    session_previous_token_grace_seconds:,
    session_heartbeat_interval_seconds:,
  ))
}

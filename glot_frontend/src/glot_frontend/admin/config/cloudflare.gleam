import glot_core/admin/cloudflare_config_dto
import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/config/section
import glot_frontend/api/response as api_response
import glot_frontend/request_generation.{type Generation}

pub type Fields {
  Fields(account_id: String, api_token: String)
}

pub type Model =
  section.FormModel(Fields)

pub type Field {
  AccountId
  ApiToken
}

pub type Msg {
  Loaded(
    Generation(section.LoadStream),
    api_response.Response(cloudflare_config_dto.CloudflareConfigResponse),
  )
  FieldChanged(Field, String)
  ResetClicked
  SaveClicked
  SaveFinished(
    Generation(section.SaveStream),
    api_response.Response(cloudflare_config_dto.CloudflareConfigResponse),
  )
}

fn empty() -> Fields {
  Fields("", "")
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
      admin_effect.get_admin_cloudflare_config(fn(result) {
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
            "cloudflare_config_not_found" -> #(
              section.loaded(model, empty()),
              admin_effect.none(),
            )
            _ -> #(
              section.load_failed(model, api_response.error_message(error)),
              admin_effect.none(),
            )
          }
        api_response.HttpFailure(_) -> #(
          section.load_failed(model, "Could not load Cloudflare config."),
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
          admin_effect.upsert_admin_cloudflare_config(request, fn(result) {
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
          section.save_failed(model, "Could not save Cloudflare config."),
          admin_effect.none(),
        )
      }
  }
}

fn set(fields: Fields, field: Field, value: String) -> Fields {
  case field {
    AccountId -> Fields(..fields, account_id: value)
    ApiToken -> Fields(..fields, api_token: value)
  }
}

fn from_response(
  response: cloudflare_config_dto.CloudflareConfigResponse,
) -> Fields {
  Fields(response.account_id, response.api_token)
}

fn request(
  fields: Fields,
) -> Result(cloudflare_config_dto.UpsertCloudflareConfigRequest, String) {
  case fields.account_id, fields.api_token {
    "", _ -> Error("Account ID must not be empty.")
    _, "" -> Error("API token must not be empty.")
    _, _ ->
      Ok(cloudflare_config_dto.UpsertCloudflareConfigRequest(
        account_id: fields.account_id,
        api_token: fields.api_token,
      ))
  }
}

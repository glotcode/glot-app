import gleam/int
import gleam/option
import gleam/result
import glot_core/admin/email_config_dto
import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/config/section
import glot_frontend/admin/ui/format as admin_format
import glot_frontend/api/response as api_response
import glot_frontend/request_generation.{type Generation}

pub type Fields {
  Fields(
    from_address: String,
    from_name: String,
    contact_address: String,
    default_timeout_ms: String,
  )
}

pub type Model =
  section.FormModel(Fields)

pub type Field {
  FromAddress
  FromName
  ContactAddress
  DefaultTimeout
}

pub type Msg {
  Loaded(
    Generation(section.LoadStream),
    api_response.Response(email_config_dto.EmailConfigResponse),
  )
  FieldChanged(Field, String)
  ResetClicked
  SaveClicked
  SaveFinished(
    Generation(section.SaveStream),
    api_response.Response(email_config_dto.EmailConfigResponse),
  )
}

fn empty() -> Fields {
  Fields("", "", "", "")
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
      admin_effect.get_admin_email_config(fn(result) {
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
            "email_config_not_found" -> #(
              section.loaded(model, empty()),
              admin_effect.none(),
            )
            _ -> #(
              section.load_failed(model, api_response.error_message(error)),
              admin_effect.none(),
            )
          }
        api_response.HttpFailure(_) -> #(
          section.load_failed(model, "Could not load email config."),
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
          admin_effect.upsert_admin_email_config(request, fn(result) {
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
          section.save_failed(model, "Could not save email config."),
          admin_effect.none(),
        )
      }
  }
}

fn set(fields: Fields, field: Field, value: String) -> Fields {
  case field {
    FromAddress -> Fields(..fields, from_address: value)
    FromName -> Fields(..fields, from_name: value)
    ContactAddress -> Fields(..fields, contact_address: value)
    DefaultTimeout -> Fields(..fields, default_timeout_ms: value)
  }
}

fn from_response(response: email_config_dto.EmailConfigResponse) -> Fields {
  Fields(
    response.from_address,
    option.unwrap(response.from_name, ""),
    option.unwrap(response.contact_address, ""),
    int.to_string(response.default_timeout_ms),
  )
}

fn request(
  fields: Fields,
) -> Result(email_config_dto.UpsertEmailConfigRequest, String) {
  use default_timeout_ms <- result.try(
    admin_format.parse_positive_int_with_error(
      fields.default_timeout_ms,
      "Default timeout must be a positive integer.",
    ),
  )
  case fields.from_address {
    "" -> Error("From address must not be empty.")
    _ ->
      Ok(email_config_dto.UpsertEmailConfigRequest(
        from_address: fields.from_address,
        from_name: optional(fields.from_name),
        contact_address: optional(fields.contact_address),
        default_timeout_ms:,
      ))
  }
}

fn optional(value: String) -> option.Option(String) {
  case value {
    "" -> option.None
    _ -> option.Some(value)
  }
}

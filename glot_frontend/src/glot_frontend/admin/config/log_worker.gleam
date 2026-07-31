import gleam/int
import gleam/result
import glot_core/admin/log_worker_config_dto
import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/config/section
import glot_frontend/admin/ui/format as admin_format
import glot_frontend/api/response as api_response
import glot_frontend/request_generation.{type Generation}

pub type Fields {
  Fields(
    flush_interval_ms: String,
    max_batch_size: String,
    max_buffer_size: String,
  )
}

pub type Model =
  section.FormModel(Fields)

pub type Field {
  FlushInterval
  MaxBatchSize
  MaxBufferSize
}

pub type Msg {
  Loaded(
    Generation(section.LoadStream),
    api_response.Response(log_worker_config_dto.LogWorkerConfigResponse),
  )
  FieldChanged(Field, String)
  ResetClicked
  SaveClicked
  SaveFinished(
    Generation(section.SaveStream),
    api_response.Response(log_worker_config_dto.LogWorkerConfigResponse),
  )
}

pub fn init() -> Model {
  section.init(Fields("", "", ""))
}

pub fn ensure_loaded(model: Model) -> #(Model, admin_effect.Command(Msg)) {
  case model.load_state {
    section.NotLoaded -> #(
      section.begin_load(model),
      admin_effect.get_admin_log_worker_config(fn(result) {
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
          section.load_failed(model, "Could not load log worker config."),
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
          admin_effect.upsert_admin_log_worker_config(request, fn(result) {
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
          section.save_failed(model, "Could not save log worker config."),
          admin_effect.none(),
        )
      }
  }
}

fn set(fields: Fields, field: Field, value: String) -> Fields {
  case field {
    FlushInterval -> Fields(..fields, flush_interval_ms: value)
    MaxBatchSize -> Fields(..fields, max_batch_size: value)
    MaxBufferSize -> Fields(..fields, max_buffer_size: value)
  }
}

fn from_response(
  response: log_worker_config_dto.LogWorkerConfigResponse,
) -> Fields {
  Fields(
    int.to_string(response.flush_interval_ms),
    int.to_string(response.max_batch_size),
    int.to_string(response.max_buffer_size),
  )
}

fn request(
  fields: Fields,
) -> Result(log_worker_config_dto.UpsertLogWorkerConfigRequest, String) {
  use flush_interval_ms <- result.try(
    admin_format.parse_positive_int_with_error(
      fields.flush_interval_ms,
      "Flush interval must be a positive integer.",
    ),
  )
  use max_batch_size <- result.try(admin_format.parse_positive_int_with_error(
    fields.max_batch_size,
    "Max batch size must be a positive integer.",
  ))
  use max_buffer_size <- result.try(admin_format.parse_positive_int_with_error(
    fields.max_buffer_size,
    "Max buffer size must be a positive integer.",
  ))
  Ok(log_worker_config_dto.UpsertLogWorkerConfigRequest(
    flush_interval_ms:,
    max_batch_size:,
    max_buffer_size:,
  ))
}

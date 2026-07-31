import gleam/int
import gleam/result
import glot_core/admin/log_worker_config_dto
import glot_frontend/admin/ui/format as admin_format

pub type Fields {
  Fields(
    flush_interval_ms: String,
    max_batch_size: String,
    max_buffer_size: String,
  )
}

pub type Field {
  FlushInterval
  MaxBatchSize
  MaxBufferSize
}

pub fn initial() -> Fields {
  Fields("", "", "")
}

pub fn set(fields: Fields, field: Field, value: String) -> Fields {
  case field {
    FlushInterval -> Fields(..fields, flush_interval_ms: value)
    MaxBatchSize -> Fields(..fields, max_batch_size: value)
    MaxBufferSize -> Fields(..fields, max_buffer_size: value)
  }
}

pub fn from_response(
  response: log_worker_config_dto.LogWorkerConfigResponse,
) -> Fields {
  Fields(
    int.to_string(response.flush_interval_ms),
    int.to_string(response.max_batch_size),
    int.to_string(response.max_buffer_size),
  )
}

pub fn request(
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
    flush_interval_ms: flush_interval_ms,
    max_batch_size: max_batch_size,
    max_buffer_size: max_buffer_size,
  ))
}

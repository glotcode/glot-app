import glot_core/admin/api_log_dto
import glot_frontend/api/response as api_response
import glot_frontend/request_generation.{type Generation}

pub type Msg {
  LogsLoaded(
    Generation(request_generation.Shared),
    api_response.Response(api_log_dto.ListApiLogsResponse),
  )
  ErrorFilterSelected(api_log_dto.ApiLogErrorFilter)
  RequestIdFilterChanged(String)
  ApplyFilters
  NextPageClicked
  PreviousPageClicked
}

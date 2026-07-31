import glot_core/admin/run_log_dto
import glot_frontend/api/response as api_response
import glot_frontend/request_generation.{type Generation}

pub type Msg {
  LogsLoaded(
    Generation(request_generation.Shared),
    api_response.Response(run_log_dto.ListRunLogsResponse),
  )
  OutcomeFilterSelected(run_log_dto.RunLogOutcomeFilter)
  RequestIdFilterChanged(String)
  SessionIdFilterChanged(String)
  UserIdFilterChanged(String)
  LanguageFilterChanged(String)
  ApplyFilters
  NextPageClicked
  PreviousPageClicked
}

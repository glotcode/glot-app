import glot_core/admin/job_log_dto
import glot_frontend/api/response as api_response
import glot_frontend/request_generation.{type Generation}

pub type Msg {
  LogsLoaded(
    Generation(request_generation.Shared),
    api_response.Response(job_log_dto.ListJobLogsResponse),
  )
  ErrorFilterSelected(job_log_dto.JobLogErrorFilter)
  RequestIdFilterChanged(String)
  JobIdFilterChanged(String)
  ApplyFilters
  NextPageClicked
  PreviousPageClicked
}

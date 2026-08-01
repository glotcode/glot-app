import glot_core/admin/job_dto
import glot_frontend/api/response as api_response

pub type Msg {
  JobsLoaded(api_response.Response(job_dto.ListJobsResponse))
  StatusFilterSelected(job_dto.StatusFilter)
  JobTypeFilterSelected(String)
  NextPageClicked
  PreviousPageClicked
}

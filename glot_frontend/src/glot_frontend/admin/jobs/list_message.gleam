import glot_core/admin/job_dto
import glot_frontend/api/response as api_response
import glot_frontend/request_generation.{type Generation}

pub type Msg {
  JobsLoaded(
    Generation(request_generation.Shared),
    api_response.Response(job_dto.ListJobsResponse),
  )
  StatusFilterSelected(job_dto.StatusFilter)
  JobTypeFilterSelected(String)
  NextPageClicked
  PreviousPageClicked
}

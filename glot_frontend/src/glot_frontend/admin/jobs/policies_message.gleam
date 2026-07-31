import glot_core/admin/job_type_policy_dto
import glot_frontend/admin/jobs/policies_model.{
  type Field, type LoadStream, type SaveStream,
}
import glot_frontend/api/response as api_response
import glot_frontend/request_generation.{type Generation}

pub type Msg {
  PoliciesLoaded(
    Generation(LoadStream),
    api_response.Response(job_type_policy_dto.ListJobTypePoliciesResponse),
  )
  FieldChanged(String, Field, String)
  ResetClicked(String)
  SaveClicked(String)
  SaveFinished(
    String,
    Generation(SaveStream),
    api_response.Response(job_type_policy_dto.JobTypePolicyResponse),
  )
}

import glot_core/admin/rate_limit_config_dto
import glot_core/public_action
import glot_core/rate_limit
import glot_frontend/admin/rate_limits/model.{
  type EditorTab, type LoadStream, type SaveStream,
}
import glot_frontend/api/response as api_response
import glot_frontend/request_generation.{type Generation}

pub type Msg {
  PoliciesLoaded(
    Generation(LoadStream),
    api_response.Response(rate_limit_config_dto.RateLimitPoliciesResponse),
  )
  EditClicked(public_action.PublicAction)
  EditDialogClosed
  TabSelected(public_action.PublicAction, EditorTab)
  FieldChanged(
    public_action.PublicAction,
    EditorTab,
    rate_limit.TimeUnit,
    String,
  )
  CancelClicked
  SaveClicked(public_action.PublicAction)
  SaveFinished(
    public_action.PublicAction,
    Generation(SaveStream),
    api_response.Response(rate_limit_config_dto.RateLimitPolicyResponse),
  )
}

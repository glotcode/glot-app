import glot_core/admin/analytics_dto
import glot_core/admin_action
import glot_frontend/api/request
import glot_frontend/api/response
import lustre/effect

pub fn get_admin_analytics(
  analytics_request: analytics_dto.GetAnalyticsRequest,
  to_msg: fn(response.Response(analytics_dto.AnalyticsResponse)) -> msg,
) -> effect.Effect(msg) {
  let req =
    request.AdminRequest(
      admin_action.GetAdminAnalyticsAction,
      analytics_request,
    )
  request.send_admin(
    req,
    analytics_dto.encode_request,
    analytics_dto.response_decoder(),
    to_msg,
  )
}

import glot_core/admin/analytics_dto
import glot_frontend/api/response

pub type Command(msg) {
  GetAnalytics(
    analytics_dto.GetAnalyticsRequest,
    fn(response.Response(analytics_dto.AnalyticsResponse)) -> msg,
  )
}

pub fn map(command: Command(a), transform: fn(a) -> b) -> Command(b) {
  case command {
    GetAnalytics(request, complete) ->
      GetAnalytics(request, fn(result) { transform(complete(result)) })
  }
}

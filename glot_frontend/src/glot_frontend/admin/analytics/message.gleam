import glot_core/admin/analytics_dto
import glot_frontend/admin/analytics/model
import glot_frontend/api/response
import glot_frontend/request_generation.{type Generation}

pub type Msg {
  AnalyticsLoaded(
    Generation(model.LoadStream),
    response.Response(analytics_dto.AnalyticsResponse),
  )
  DaysSelected(Int)
  RefreshClicked
}

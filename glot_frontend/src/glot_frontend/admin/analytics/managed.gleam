import gleam/option
import glot_core/admin/analytics_dto
import glot_core/loadable
import glot_frontend/admin/analytics/message.{
  AnalyticsLoaded, DaysSelected, RefreshClicked,
}
import glot_frontend/admin/analytics/model.{type Model}
import glot_frontend/admin/command as admin_effect
import glot_frontend/api/response as api_response
import glot_frontend/request_generation

pub type Msg =
  message.Msg

pub fn init() -> #(Model, admin_effect.Command(Msg)) {
  #(
    model.Model(
      analytics: loadable.NotLoaded,
      days: 30,
      refreshing: False,
      refresh_error: option.None,
      load_generation: request_generation.initial(),
    ),
    admin_effect.none(),
  )
}

pub fn ensure_loaded(model: Model) -> #(Model, admin_effect.Command(Msg)) {
  case model.analytics {
    loadable.NotLoaded -> load(model)
    loadable.Loading | loadable.Loaded(_) | loadable.LoadError(_) -> #(
      model,
      admin_effect.none(),
    )
  }
}

pub fn update(model: Model, msg: Msg) -> #(Model, admin_effect.Command(Msg)) {
  case msg {
    AnalyticsLoaded(generation, _) if generation != model.load_generation -> #(
      model,
      admin_effect.none(),
    )
    AnalyticsLoaded(_, result) ->
      case result {
        api_response.Success(response) -> #(
          model.Model(
            ..model,
            analytics: loadable.Loaded(response),
            refreshing: False,
            refresh_error: option.None,
          ),
          admin_effect.none(),
        )
        api_response.ApiFailure(error) ->
          load_failed(model, api_response.error_message(error))
        api_response.HttpFailure(_) ->
          load_failed(model, "Could not load analytics.")
      }
    DaysSelected(days) if days == model.days -> #(model, admin_effect.none())
    DaysSelected(days) -> load(model.Model(..model, days: days))
    RefreshClicked -> load(model)
  }
}

fn load(model: Model) -> #(Model, admin_effect.Command(Msg)) {
  let generation = request_generation.next(model.load_generation)
  let analytics = case model.analytics {
    loadable.Loaded(_) -> model.analytics
    loadable.NotLoaded | loadable.Loading | loadable.LoadError(_) ->
      loadable.Loading
  }
  #(
    model.Model(
      ..model,
      analytics: analytics,
      refreshing: True,
      refresh_error: option.None,
      load_generation: generation,
    ),
    admin_effect.get_admin_analytics(
      analytics_dto.GetAnalyticsRequest(days: model.days),
      fn(response) { AnalyticsLoaded(generation, response) },
    ),
  )
}

fn load_failed(
  model: Model,
  message: String,
) -> #(Model, admin_effect.Command(Msg)) {
  case model.analytics {
    loadable.Loaded(_) -> #(
      model.Model(
        ..model,
        refreshing: False,
        refresh_error: option.Some(message),
      ),
      admin_effect.none(),
    )
    loadable.NotLoaded | loadable.Loading | loadable.LoadError(_) -> #(
      model.Model(
        ..model,
        analytics: loadable.LoadError(message),
        refreshing: False,
        refresh_error: option.None,
      ),
      admin_effect.none(),
    )
  }
}

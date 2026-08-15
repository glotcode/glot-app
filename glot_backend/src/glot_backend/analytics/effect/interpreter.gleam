import glot_backend/analytics/effect/algebra as analytics_algebra
import glot_backend/analytics/ports/store.{type Store}
import glot_backend/system/effect/effect_trace
import glot_backend/system/effect/error
import glot_backend/system/effect/measured_interpreter
import glot_backend/system/effect/program_state

pub fn run(
  effect: analytics_algebra.AnalyticsEffect(next_program),
  store: Store,
  state: program_state.State,
  continue: fn(next_program, program_state.State) ->
    #(Result(a, error.Error), program_state.State),
) -> #(Result(a, error.Error), program_state.State) {
  case effect {
    analytics_algebra.GetAnalytics(days:, start_day:, end_day:, next:) ->
      measured_interpreter.run(
        fn() { store.get_analytics(days, start_day, end_day) },
        next,
        name: trace_name(analytics_algebra.GetAnalyticsEffectName),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    analytics_algebra.GetMaxCompletedMetricsDay(next:) ->
      measured_interpreter.run(
        store.get_max_completed_metrics_day,
        next,
        name: trace_name(analytics_algebra.GetMaxCompletedMetricsDayEffectName),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    analytics_algebra.GetFirstMetricsSourceDay(before:, next:) ->
      measured_interpreter.run(
        fn() { store.get_first_metrics_source_day(before) },
        next,
        name: trace_name(analytics_algebra.GetFirstMetricsSourceDayEffectName),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    analytics_algebra.InsertMetricsPageviewDay(day:, next:) ->
      measured_interpreter.run(
        fn() { store.insert_metrics_pageview_day(day) },
        next,
        name: trace_name(analytics_algebra.InsertMetricsPageviewDayEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
    analytics_algebra.InsertMetricsProductEventDay(day:, next:) ->
      measured_interpreter.run(
        fn() { store.insert_metrics_product_event_day(day) },
        next,
        name: trace_name(
          analytics_algebra.InsertMetricsProductEventDayEffectName,
        ),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
    analytics_algebra.InsertMetricsRunDay(day:, next:) ->
      measured_interpreter.run(
        fn() { store.insert_metrics_run_day(day) },
        next,
        name: trace_name(analytics_algebra.InsertMetricsRunDayEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
    analytics_algebra.InsertMetricsReliabilityPageDay(day:, next:) ->
      measured_interpreter.run(
        fn() { store.insert_metrics_reliability_page_day(day) },
        next,
        name: trace_name(
          analytics_algebra.InsertMetricsReliabilityPageDayEffectName,
        ),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
    analytics_algebra.InsertMetricsReliabilityApiDay(day:, next:) ->
      measured_interpreter.run(
        fn() { store.insert_metrics_reliability_api_day(day) },
        next,
        name: trace_name(
          analytics_algebra.InsertMetricsReliabilityApiDayEffectName,
        ),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
    analytics_algebra.InsertMetricsReliabilityJobDay(day:, next:) ->
      measured_interpreter.run(
        fn() { store.insert_metrics_reliability_job_day(day) },
        next,
        name: trace_name(
          analytics_algebra.InsertMetricsReliabilityJobDayEffectName,
        ),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
    analytics_algebra.InsertMetricsCompletedDay(day:, next:) ->
      measured_interpreter.run(
        fn() { store.insert_metrics_completed_day(day) },
        next,
        name: trace_name(analytics_algebra.InsertMetricsCompletedDayEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
  }
}

fn trace_name(name: analytics_algebra.EffectName) -> effect_trace.EffectName {
  effect_trace.AnalyticsEffectName(name)
}

import glot_backend/snippet/effect/algebra as snippet_algebra
import glot_backend/snippet/ports/store.{type Store}
import glot_backend/system/effect/effect_trace
import glot_backend/system/effect/error
import glot_backend/system/effect/program_state
import glot_backend/system/runtime/erlang

pub fn run(
  effect: snippet_algebra.SnippetEffect(next_program),
  store: Store,
  state: program_state.State,
  continue: fn(next_program, program_state.State) ->
    #(Result(a, error.Error), program_state.State),
) -> #(Result(a, error.Error), program_state.State) {
  case effect {
    snippet_algebra.GetSnippetById(id, next) -> {
      let started_at = erlang.perf_counter_ns()
      let result = store.get_snippet_by_id(id)
      continue(
        next(result),
        program_state.add_effect_measurement(
          state,
          effect_trace.SnippetEffectName(
            snippet_algebra.GetSnippetByIdEffectName,
          ),
          effect_trace.DatabaseReadEffect,
          started_at,
        ),
      )
    }
    snippet_algebra.GetSnippetBySlug(slug, next) -> {
      let started_at = erlang.perf_counter_ns()
      let result = store.get_snippet_by_slug(slug)
      continue(
        next(result),
        program_state.add_effect_measurement(
          state,
          effect_trace.SnippetEffectName(
            snippet_algebra.GetSnippetBySlugEffectName,
          ),
          effect_trace.DatabaseReadEffect,
          started_at,
        ),
      )
    }
    snippet_algebra.GetSnippetBySlugForUpdate(slug, next) -> {
      let started_at = erlang.perf_counter_ns()
      let result = store.get_snippet_by_slug_for_update(slug)
      continue(
        next(result),
        program_state.add_effect_measurement(
          state,
          effect_trace.SnippetEffectName(
            snippet_algebra.GetSnippetBySlugForUpdateEffectName,
          ),
          effect_trace.DatabaseReadEffect,
          started_at,
        ),
      )
    }
    snippet_algebra.GetAdminSnippetBySlug(slug, next) -> {
      let started_at = erlang.perf_counter_ns()
      let result = store.get_admin_snippet_by_slug(slug)
      continue(
        next(result),
        program_state.add_effect_measurement(
          state,
          effect_trace.SnippetEffectName(
            snippet_algebra.GetAdminSnippetBySlugEffectName,
          ),
          effect_trace.DatabaseReadEffect,
          started_at,
        ),
      )
    }
    snippet_algebra.ListSnippets(filter:, pagination:, next:) -> {
      let started_at = erlang.perf_counter_ns()
      let result = store.list_snippets(filter, pagination)
      continue(
        next(result),
        program_state.add_effect_measurement(
          state,
          effect_trace.SnippetEffectName(snippet_algebra.ListSnippetsEffectName),
          effect_trace.DatabaseReadEffect,
          started_at,
        ),
      )
    }
    snippet_algebra.ListAdminSnippets(username:, pagination:, next:) -> {
      let started_at = erlang.perf_counter_ns()
      let result = store.list_admin_snippets(username, pagination)
      continue(
        next(result),
        program_state.add_effect_measurement(
          state,
          effect_trace.SnippetEffectName(
            snippet_algebra.ListAdminSnippetsEffectName,
          ),
          effect_trace.DatabaseReadEffect,
          started_at,
        ),
      )
    }
    snippet_algebra.DeleteSnippet(id, next) -> {
      let started_at = erlang.perf_counter_ns()
      let result = store.delete_snippet(id)
      continue(
        next(result),
        program_state.add_effect_measurement(
          state,
          effect_trace.SnippetEffectName(
            snippet_algebra.DeleteSnippetEffectName,
          ),
          effect_trace.DatabaseWriteEffect,
          started_at,
        ),
      )
    }
    snippet_algebra.DeleteSnippetsByAccountId(account_id:, next:) -> {
      let started_at = erlang.perf_counter_ns()
      let result = store.delete_snippets_by_account_id(account_id)
      continue(
        next(result),
        program_state.add_effect_measurement(
          state,
          effect_trace.SnippetEffectName(
            snippet_algebra.DeleteSnippetsByAccountIdEffectName,
          ),
          effect_trace.DatabaseWriteEffect,
          started_at,
        ),
      )
    }
    snippet_algebra.CreateSnippet(snippet_value, next) -> {
      let started_at = erlang.perf_counter_ns()
      let result = store.create_snippet(snippet_value)
      continue(
        next(result),
        program_state.add_effect_measurement(
          state,
          effect_trace.SnippetEffectName(
            snippet_algebra.CreateSnippetEffectName,
          ),
          effect_trace.DatabaseWriteEffect,
          started_at,
        ),
      )
    }
    snippet_algebra.UpdateSnippet(snippet_value, next) -> {
      let started_at = erlang.perf_counter_ns()
      let result = store.update_snippet(snippet_value)
      continue(
        next(result),
        program_state.add_effect_measurement(
          state,
          effect_trace.SnippetEffectName(
            snippet_algebra.UpdateSnippetEffectName,
          ),
          effect_trace.DatabaseWriteEffect,
          started_at,
        ),
      )
    }
  }
}

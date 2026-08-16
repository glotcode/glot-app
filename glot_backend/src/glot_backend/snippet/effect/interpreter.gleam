import glot_backend/snippet/effect/algebra as snippet_algebra
import glot_backend/snippet/ports/store.{type Store}
import glot_backend/system/effect/effect_trace
import glot_backend/system/effect/error
import glot_backend/system/effect/measured_interpreter
import glot_backend/system/effect/program_state

pub fn run(
  effect: snippet_algebra.SnippetEffect(next_program),
  store: Store,
  state: program_state.State,
  continue: fn(next_program, program_state.State) ->
    #(Result(a, error.Error), program_state.State),
) -> #(Result(a, error.Error), program_state.State) {
  case effect {
    snippet_algebra.GetSnippetById(id, next) ->
      measured_interpreter.run(
        fn() { store.get_snippet_by_id(id) },
        next,
        name: trace_name(snippet_algebra.GetSnippetByIdEffectName),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    snippet_algebra.GetSnippetBySlug(slug, next) ->
      measured_interpreter.run(
        fn() { store.get_snippet_by_slug(slug) },
        next,
        name: trace_name(snippet_algebra.GetSnippetBySlugEffectName),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    snippet_algebra.GetSnippetBySlugForUpdate(slug, next) ->
      measured_interpreter.run(
        fn() { store.get_snippet_by_slug_for_update(slug) },
        next,
        name: trace_name(snippet_algebra.GetSnippetBySlugForUpdateEffectName),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    snippet_algebra.GetAdminSnippetBySlug(slug, next) ->
      measured_interpreter.run(
        fn() { store.get_admin_snippet_by_slug(slug) },
        next,
        name: trace_name(snippet_algebra.GetAdminSnippetBySlugEffectName),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    snippet_algebra.ListSnippets(filter:, pagination:, next:) ->
      measured_interpreter.run(
        fn() { store.list_snippets(filter, pagination) },
        next,
        name: trace_name(snippet_algebra.ListSnippetsEffectName),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    snippet_algebra.ListAdminSnippets(
      username:,
      spam_classification:,
      pagination:,
      next:,
    ) ->
      measured_interpreter.run(
        fn() {
          store.list_admin_snippets(username, spam_classification, pagination)
        },
        next,
        name: trace_name(snippet_algebra.ListAdminSnippetsEffectName),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    snippet_algebra.DeleteSnippet(id, next) ->
      measured_interpreter.run(
        fn() { store.delete_snippet(id) },
        next,
        name: trace_name(snippet_algebra.DeleteSnippetEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
    snippet_algebra.DeleteSnippetsByAccountId(account_id:, next:) ->
      measured_interpreter.run(
        fn() { store.delete_snippets_by_account_id(account_id) },
        next,
        name: trace_name(snippet_algebra.DeleteSnippetsByAccountIdEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
    snippet_algebra.CreateSnippet(snippet_value, next) ->
      measured_interpreter.run(
        fn() { store.create_snippet(snippet_value) },
        next,
        name: trace_name(snippet_algebra.CreateSnippetEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
    snippet_algebra.UpdateSnippet(snippet_value, next) ->
      measured_interpreter.run(
        fn() { store.update_snippet(snippet_value) },
        next,
        name: trace_name(snippet_algebra.UpdateSnippetEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
    snippet_algebra.GetNewestUnclassifiedSnippet(next:) ->
      measured_interpreter.run(
        fn() { store.get_newest_unclassified_snippet() },
        next,
        name: trace_name(snippet_algebra.GetNewestUnclassifiedSnippetEffectName),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    snippet_algebra.IncrementSpamClassificationAttempts(
      id:,
      expected_updated_at:,
      next:,
    ) ->
      measured_interpreter.run(
        fn() {
          store.increment_spam_classification_attempts(id, expected_updated_at)
        },
        next,
        name: trace_name(
          snippet_algebra.IncrementSpamClassificationAttemptsEffectName,
        ),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
    snippet_algebra.StoreSpamClassification(
      id:,
      expected_updated_at:,
      classification:,
      next:,
    ) ->
      measured_interpreter.run(
        fn() {
          store.store_spam_classification(
            id,
            expected_updated_at,
            classification,
          )
        },
        next,
        name: trace_name(snippet_algebra.StoreSpamClassificationEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
    snippet_algebra.StoreSpamClassificationFailure(
      id:,
      expected_updated_at:,
      failure:,
      next:,
    ) ->
      measured_interpreter.run(
        fn() {
          store.store_spam_classification_failure(
            id,
            expected_updated_at,
            failure,
          )
        },
        next,
        name: trace_name(
          snippet_algebra.StoreSpamClassificationFailureEffectName,
        ),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
  }
}

fn trace_name(name: snippet_algebra.EffectName) -> effect_trace.EffectName {
  effect_trace.SnippetEffectName(name)
}

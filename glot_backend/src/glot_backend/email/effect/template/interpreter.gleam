import glot_backend/email/effect/template/algebra as email_template_algebra
import glot_backend/email/ports/template_store.{type TemplateStore}
import glot_backend/system/effect/effect_trace
import glot_backend/system/effect/error
import glot_backend/system/effect/measured_interpreter
import glot_backend/system/effect/program_state

pub fn run(
  effect: email_template_algebra.EmailTemplateEffect(next_program),
  store: TemplateStore,
  state: program_state.State,
  continue: fn(next_program, program_state.State) ->
    #(Result(a, error.Error), program_state.State),
) -> #(Result(a, error.Error), program_state.State) {
  case effect {
    email_template_algebra.ListEmailTemplates(next:) ->
      measured_interpreter.run_or_fail(
        store.list,
        next,
        map_error: error.database_query_error,
        name: effect_trace.EmailTemplateEffectName(
          email_template_algebra.ListEmailTemplatesEffectName,
        ),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    email_template_algebra.GetEmailTemplateByName(name:, next:) ->
      measured_interpreter.run_or_fail(
        fn() { store.get(name) },
        next,
        map_error: error.database_query_error,
        name: effect_trace.EmailTemplateEffectName(
          email_template_algebra.GetEmailTemplateByNameEffectName,
        ),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    email_template_algebra.UpdateEmailTemplate(template:, next:) ->
      measured_interpreter.run_or_fail(
        fn() { store.update(template) },
        next,
        map_error: error.database_command_error,
        name: effect_trace.EmailTemplateEffectName(
          email_template_algebra.UpdateEmailTemplateEffectName,
        ),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
  }
}

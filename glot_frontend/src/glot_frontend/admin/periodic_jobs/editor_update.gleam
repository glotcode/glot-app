import gleam/option
import glot_core/admin/periodic_job_dto
import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/periodic_jobs/editor_policy
import glot_frontend/admin/periodic_jobs/message.{
  EnabledToggled, IntervalSecondsChanged, NextRunAtParsed, NextRunDateChanged,
  NextRunTimeChanged, PayloadChanged, ResetClicked, SaveClicked, SaveFinished,
  SavedPeriodicJobFormatted,
}
import glot_frontend/admin/periodic_jobs/model.{
  type Model, Idle, Model, PeriodicJobEditor, PeriodicJobFields, Ready,
  SaveError, Saving,
}
import glot_frontend/api/response as api_response
import glot_frontend/request_generation

pub fn update(
  model: Model,
  msg: message.Msg,
) -> #(Model, admin_effect.Command(message.Msg)) {
  case msg {
    PayloadChanged(value) ->
      change(model, fn(editor) {
        PeriodicJobEditor(
          ..editor,
          draft: PeriodicJobFields(..editor.draft, payload: value),
          state: Idle,
        )
      })
    IntervalSecondsChanged(value) ->
      change(model, fn(editor) {
        PeriodicJobEditor(
          ..editor,
          draft: PeriodicJobFields(..editor.draft, interval_seconds: value),
          state: Idle,
        )
      })
    EnabledToggled ->
      change(model, fn(editor) {
        PeriodicJobEditor(
          ..editor,
          draft: PeriodicJobFields(
            ..editor.draft,
            enabled: !editor.draft.enabled,
          ),
          state: Idle,
        )
      })
    NextRunDateChanged(value) ->
      change(model, fn(editor) {
        PeriodicJobEditor(
          ..editor,
          draft: PeriodicJobFields(..editor.draft, next_run_date: value),
          state: Idle,
        )
      })
    NextRunTimeChanged(value) ->
      change(model, fn(editor) {
        PeriodicJobEditor(
          ..editor,
          draft: PeriodicJobFields(..editor.draft, next_run_time: value),
          state: Idle,
        )
      })
    ResetClicked ->
      change(model, fn(editor) {
        PeriodicJobEditor(..editor, draft: editor.saved, state: Idle)
      })
    SaveClicked -> save(model)
    NextRunAtParsed(generation, _) if generation != model.save_generation -> #(
      model,
      admin_effect.none(),
    )
    NextRunAtParsed(generation, result) -> parsed(model, generation, result)
    SaveFinished(generation, _) if generation != model.save_generation -> #(
      model,
      admin_effect.none(),
    )
    SaveFinished(generation, result) -> finished(model, generation, result)
    SavedPeriodicJobFormatted(generation, _, _)
      if generation != model.save_generation
    -> #(model, admin_effect.none())
    SavedPeriodicJobFormatted(_, periodic_job, local) -> #(
      Model(
        ..model,
        periodic_job: option.Some(editor_policy.from_response(
          periodic_job,
          local,
        )),
        status: Ready,
      ),
      admin_effect.none(),
    )
    _ -> #(model, admin_effect.none())
  }
}

fn change(model: Model, update_editor) {
  #(editor_policy.update_model(model, update_editor), admin_effect.none())
}

fn save(model: Model) {
  case model.periodic_job {
    option.None -> #(model, admin_effect.none())
    option.Some(editor) ->
      case editor_policy.validate(editor) {
        Ok(_) -> {
          let generation = request_generation.next(model.save_generation)
          #(
            Model(
              ..editor_policy.update_model(model, fn(current) {
                PeriodicJobEditor(..current, state: Saving)
              }),
              save_generation: generation,
            ),
            admin_effect.ParseLocalDateTime(
              editor.draft.next_run_date,
              editor.draft.next_run_time,
              fn(result) { NextRunAtParsed(generation, result) },
            ),
          )
        }
        Error(message) ->
          change(model, fn(current) {
            PeriodicJobEditor(..current, state: SaveError(message))
          })
      }
  }
}

fn parsed(model: Model, generation, result) {
  case model.periodic_job, result {
    option.Some(editor), option.Some(next_run_at) ->
      case editor.state, editor_policy.to_request(editor, next_run_at) {
        Saving, Ok(request) -> #(
          model,
          admin_effect.update_admin_periodic_job(request, fn(result) {
            SaveFinished(generation, result)
          }),
        )
        _, _ -> #(model, admin_effect.none())
      }
    option.Some(editor), option.None ->
      case editor.state {
        Saving ->
          change(model, fn(_) {
            PeriodicJobEditor(
              ..editor,
              state: SaveError("Next run date or time is invalid."),
            )
          })
        _ -> #(model, admin_effect.none())
      }
    option.None, _ -> #(model, admin_effect.none())
  }
}

fn finished(
  model: Model,
  generation,
  result: api_response.Response(periodic_job_dto.UpdatePeriodicJobResponse),
) {
  case result {
    api_response.Success(response) -> #(
      model,
      admin_effect.FormatLocalDateTime(
        response.periodic_job.next_run_at,
        fn(local) {
          SavedPeriodicJobFormatted(generation, response.periodic_job, local)
        },
      ),
    )
    api_response.ApiFailure(error) ->
      change(model, fn(editor) {
        PeriodicJobEditor(
          ..editor,
          state: SaveError(api_response.error_message(error)),
        )
      })
    api_response.HttpFailure(_) ->
      change(model, fn(editor) {
        PeriodicJobEditor(
          ..editor,
          state: SaveError("Could not save periodic job."),
        )
      })
  }
}

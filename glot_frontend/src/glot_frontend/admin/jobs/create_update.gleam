import gleam/option
import glot_core/admin/job_dto
import glot_core/route
import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/jobs/constants
import glot_frontend/admin/jobs/create_job_policy
import glot_frontend/admin/jobs/message.{
  CreateJobCancelled, CreateJobDialogClosed, CreateJobFinished,
  CreateJobMaxAttemptsChanged, CreateJobPayloadChanged, CreateJobRunAtParsed,
  CreateJobRunDateChanged, CreateJobRunTimeChanged, CreateJobSubmitted,
  CreateJobTimeoutSecondsChanged, OpenCreateJobAt, OpenCreateJobClicked,
  OpenCreateJobWithLocalDateTime,
}
import glot_frontend/admin/jobs/model.{
  type Model, CreateJobDraft, CreateJobEditor, CreateJobError, CreateJobSaving,
  Model,
}
import glot_frontend/api/response as api_response
import glot_frontend/request_generation

pub fn update(
  model: Model,
  msg: message.Msg,
) -> #(Model, admin_effect.Command(message.Msg)) {
  case msg {
    OpenCreateJobClicked -> #(model, admin_effect.CurrentTime(OpenCreateJobAt))
    OpenCreateJobAt(now) ->
      case model.job {
        option.Some(_) -> #(
          model,
          admin_effect.FormatLocalDateTime(now, OpenCreateJobWithLocalDateTime),
        )
        option.None -> #(model, admin_effect.none())
      }
    OpenCreateJobWithLocalDateTime(local) ->
      case model.job {
        option.Some(job) -> #(
          Model(
            ..model,
            create_job_editor: option.Some(create_job_policy.from_job(
              job,
              local,
            )),
          ),
          admin_effect.OpenDialog(constants.create_job_dialog_id),
        )
        option.None -> #(model, admin_effect.none())
      }
    CreateJobDialogClosed -> #(
      Model(..model, create_job_editor: option.None),
      admin_effect.none(),
    )
    CreateJobCancelled -> #(
      Model(..model, create_job_editor: option.None),
      admin_effect.CloseDialog(constants.create_job_dialog_id),
    )
    CreateJobSubmitted -> submit(model)
    CreateJobRunAtParsed(generation, _)
      if generation != model.create_generation
    -> #(model, admin_effect.none())
    CreateJobRunAtParsed(generation, result) ->
      parsed(model, generation, result)
    CreateJobFinished(generation, _) if generation != model.create_generation -> #(
      model,
      admin_effect.none(),
    )
    CreateJobFinished(_, result) -> finished(model, result)
    CreateJobPayloadChanged(value) ->
      change(model, fn(editor) {
        CreateJobEditor(
          ..editor,
          draft: CreateJobDraft(..editor.draft, payload: value),
          state: create_job_policy.reset_state(editor.state),
        )
      })
    CreateJobMaxAttemptsChanged(value) ->
      change(model, fn(editor) {
        CreateJobEditor(
          ..editor,
          draft: CreateJobDraft(..editor.draft, max_attempts: value),
          state: create_job_policy.reset_state(editor.state),
        )
      })
    CreateJobTimeoutSecondsChanged(value) ->
      change(model, fn(editor) {
        CreateJobEditor(
          ..editor,
          draft: CreateJobDraft(..editor.draft, timeout_seconds: value),
          state: create_job_policy.reset_state(editor.state),
        )
      })
    CreateJobRunDateChanged(value) ->
      change(model, fn(editor) {
        CreateJobEditor(
          ..editor,
          draft: CreateJobDraft(..editor.draft, run_date: value),
          state: create_job_policy.reset_state(editor.state),
        )
      })
    CreateJobRunTimeChanged(value) ->
      change(model, fn(editor) {
        CreateJobEditor(
          ..editor,
          draft: CreateJobDraft(..editor.draft, run_time: value),
          state: create_job_policy.reset_state(editor.state),
        )
      })
    _ -> #(model, admin_effect.none())
  }
}

fn submit(model: Model) {
  case model.create_job_editor {
    option.Some(editor) ->
      case create_job_policy.validate(editor) {
        Ok(_) -> {
          let generation = request_generation.next(model.create_generation)
          #(
            Model(
              ..model,
              create_job_editor: option.Some(
                CreateJobEditor(..editor, state: CreateJobSaving),
              ),
              create_generation: generation,
            ),
            admin_effect.ParseLocalDateTime(
              editor.draft.run_date,
              editor.draft.run_time,
              fn(result) { CreateJobRunAtParsed(generation, result) },
            ),
          )
        }
        Error(message) -> #(
          Model(
            ..model,
            create_job_editor: option.Some(
              CreateJobEditor(..editor, state: CreateJobError(message)),
            ),
          ),
          admin_effect.none(),
        )
      }
    option.None -> #(model, admin_effect.none())
  }
}

fn parsed(model: Model, generation, result) {
  case model.create_job_editor, result {
    option.Some(editor), option.Some(run_at) ->
      case editor.state, create_job_policy.to_request(editor, run_at) {
        CreateJobSaving, Ok(request) -> #(
          model,
          admin_effect.create_admin_job(request, fn(result) {
            CreateJobFinished(generation, result)
          }),
        )
        _, _ -> #(model, admin_effect.none())
      }
    option.Some(editor), option.None ->
      case editor.state {
        CreateJobSaving -> #(
          Model(
            ..model,
            create_job_editor: option.Some(
              CreateJobEditor(
                ..editor,
                state: CreateJobError("Run date or time is invalid."),
              ),
            ),
          ),
          admin_effect.none(),
        )
        _ -> #(model, admin_effect.none())
      }
    option.None, _ -> #(model, admin_effect.none())
  }
}

fn finished(
  model: Model,
  result: api_response.Response(job_dto.GetJobResponse),
) {
  case model.create_job_editor {
    option.Some(editor) ->
      case result {
        api_response.Success(response) -> #(
          Model(..model, create_job_editor: option.None),
          admin_effect.batch([
            admin_effect.CloseDialog(constants.create_job_dialog_id),
            navigate_to_job(response.job.id),
          ]),
        )
        api_response.ApiFailure(error) ->
          failure(model, editor, api_response.error_message(error))
        api_response.HttpFailure(_) ->
          failure(model, editor, "Could not create job.")
      }
    option.None -> #(model, admin_effect.none())
  }
}

fn failure(model, editor, message) {
  #(
    Model(
      ..model,
      create_job_editor: option.Some(
        CreateJobEditor(..editor, state: CreateJobError(message)),
      ),
    ),
    admin_effect.none(),
  )
}

fn change(model: Model, update_editor) {
  #(create_job_policy.update_model(model, update_editor), admin_effect.none())
}

fn navigate_to_job(job_id) {
  admin_effect.Navigate(route.Admin(route.AdminJob(job_id)))
}

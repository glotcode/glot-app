import gleam/list
import gleam/option
import glot_core/loadable
import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/jobs/policies_message.{
  type Msg, FieldChanged, PoliciesLoaded, ResetClicked, SaveClicked,
  SaveFinished,
}
import glot_frontend/admin/jobs/policies_model.{type Model, Model, PolicyEditor}
import glot_frontend/admin/jobs/policies_policy as policy
import glot_frontend/api/response as api_response
import glot_frontend/request_generation
import glot_frontend/ui/mutation

pub fn init() -> #(Model, admin_effect.Command(Msg)) {
  #(
    Model(
      policies: loadable.NotLoaded,
      load_generation: request_generation.initial(),
    ),
    admin_effect.none(),
  )
}

pub fn ensure_loaded(model: Model) -> #(Model, admin_effect.Command(Msg)) {
  case model.policies {
    loadable.NotLoaded -> {
      let generation = request_generation.next(model.load_generation)
      #(
        Model(policies: loadable.Loading, load_generation: generation),
        admin_effect.get_admin_job_type_policies(fn(result) {
          PoliciesLoaded(generation, result)
        }),
      )
    }
    loadable.Loading | loadable.Loaded(_) | loadable.LoadError(_) -> #(
      model,
      admin_effect.none(),
    )
  }
}

pub fn update(model: Model, msg: Msg) -> #(Model, admin_effect.Command(Msg)) {
  let current_save_generation = case msg {
    SaveFinished(job_type, _, _) ->
      policy.find_editor(policy.loaded_policies(model), job_type)
      |> option.map(fn(editor) { editor.save_generation })
    _ -> option.None
  }
  case msg {
    PoliciesLoaded(generation, _) if generation != model.load_generation -> #(
      model,
      admin_effect.none(),
    )
    PoliciesLoaded(_, result) ->
      case result {
        api_response.Success(response) -> #(
          Model(
            policies: loadable.Loaded(list.map(
              response.policies,
              policy.editor_from_response,
            )),
            load_generation: model.load_generation,
          ),
          admin_effect.none(),
        )
        api_response.ApiFailure(error) -> #(
          Model(
            policies: loadable.LoadError(api_response.error_message(error)),
            load_generation: model.load_generation,
          ),
          admin_effect.none(),
        )
        api_response.HttpFailure(_) -> #(
          Model(
            policies: loadable.LoadError("Could not load job type policies."),
            load_generation: model.load_generation,
          ),
          admin_effect.none(),
        )
      }

    FieldChanged(job_type, field, value) -> #(
      Model(
        ..model,
        policies: loadable.Loaded(
          policy.update_editor(
            policy.loaded_policies(model),
            job_type,
            fn(editor) {
              PolicyEditor(
                ..editor,
                draft: policy.update_field(editor.draft, field, value),
                state: mutation.clear_feedback(editor.state),
                save_generation: request_generation.next(editor.save_generation),
              )
            },
          ),
        ),
      ),
      admin_effect.none(),
    )

    ResetClicked(job_type) -> #(
      Model(
        ..model,
        policies: loadable.Loaded(
          policy.update_editor(
            policy.loaded_policies(model),
            job_type,
            fn(editor) {
              PolicyEditor(
                ..editor,
                draft: editor.saved,
                state: mutation.Idle,
                save_generation: request_generation.next(editor.save_generation),
              )
            },
          ),
        ),
      ),
      admin_effect.none(),
    )

    SaveClicked(job_type) ->
      case policy.find_editor(policy.loaded_policies(model), job_type) {
        option.None -> #(model, admin_effect.none())
        option.Some(editor) ->
          case policy.request_from_editor(editor) {
            Ok(request) -> #(
              Model(
                ..model,
                policies: loadable.Loaded(
                  policy.update_editor(
                    policy.loaded_policies(model),
                    job_type,
                    fn(current) {
                      PolicyEditor(
                        ..current,
                        state: mutation.Saving,
                        save_generation: request_generation.next(
                          editor.save_generation,
                        ),
                      )
                    },
                  ),
                ),
              ),
              admin_effect.upsert_admin_job_type_policy(request, fn(result) {
                SaveFinished(
                  job_type,
                  request_generation.next(editor.save_generation),
                  result,
                )
              }),
            )
            Error(message) -> #(
              Model(
                ..model,
                policies: loadable.Loaded(
                  policy.update_editor(
                    policy.loaded_policies(model),
                    job_type,
                    fn(current) {
                      PolicyEditor(
                        ..current,
                        state: mutation.SaveError(message),
                      )
                    },
                  ),
                ),
              ),
              admin_effect.none(),
            )
          }
      }

    SaveFinished(_job_type, generation, _)
      if option.Some(generation) != current_save_generation
    -> #(model, admin_effect.none())
    SaveFinished(job_type, generation, result) ->
      case result {
        api_response.Success(response) -> #(
          Model(
            ..model,
            policies: loadable.Loaded(
              policy.update_editor(
                policy.loaded_policies(model),
                job_type,
                fn(_) {
                  let editor = policy.editor_from_response(response)
                  PolicyEditor(
                    ..editor,
                    state: mutation.Saved,
                    save_generation: generation,
                  )
                },
              ),
            ),
          ),
          admin_effect.none(),
        )
        api_response.ApiFailure(error) -> #(
          Model(
            ..model,
            policies: loadable.Loaded(
              policy.update_editor(
                policy.loaded_policies(model),
                job_type,
                fn(editor) {
                  PolicyEditor(
                    ..editor,
                    state: mutation.SaveError(api_response.error_message(error)),
                  )
                },
              ),
            ),
          ),
          admin_effect.none(),
        )
        api_response.HttpFailure(_) -> #(
          Model(
            ..model,
            policies: loadable.Loaded(
              policy.update_editor(
                policy.loaded_policies(model),
                job_type,
                fn(editor) {
                  PolicyEditor(
                    ..editor,
                    state: mutation.SaveError("Could not save job type policy."),
                  )
                },
              ),
            ),
          ),
          admin_effect.none(),
        )
      }
  }
}

import gleam/option
import glot_core/loadable
import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/rate_limits/constants
import glot_frontend/admin/rate_limits/message.{
  CancelClicked, EditClicked, EditDialogClosed, FieldChanged, PoliciesLoaded,
  SaveClicked, SaveFinished, TabSelected,
}
import glot_frontend/admin/rate_limits/model.{
  type LoadStream, ActiveEditor, AnonymousTab, Model, PolicyEditor,
}
import glot_frontend/admin/rate_limits/policy
import glot_frontend/api/response as api_response
import glot_frontend/request_generation.{type Generation}
import glot_frontend/ui/mutation

const edit_dialog_id = constants.edit_dialog_id

pub type Model =
  model.Model

pub type Msg =
  message.Msg

pub fn init() -> #(Model, admin_effect.Command(Msg)) {
  #(
    Model(
      policies: loadable.NotLoaded,
      active_editor: option.None,
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
        Model(..model, policies: loadable.Loading, load_generation: generation),
        load_policies(generation),
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
    SaveFinished(action, _, _) ->
      policy.find(policy.loaded(model), action)
      |> option.map(fn(policy) { policy.save_generation })
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
            policies: loadable.Loaded(policy.from_responses(response.policies)),
            active_editor: option.None,
            load_generation: model.load_generation,
          ),
          admin_effect.none(),
        )
        api_response.ApiFailure(error) -> #(
          Model(
            ..model,
            policies: loadable.LoadError(api_response.error_message(error)),
          ),
          admin_effect.none(),
        )
        api_response.HttpFailure(_) -> #(
          Model(
            ..model,
            policies: loadable.LoadError("Could not load rate limit policies."),
          ),
          admin_effect.none(),
        )
      }

    EditClicked(action) -> {
      let existing_policies = policy.loaded(model)
      let next_policies =
        policy.update(existing_policies, action, fn(policy) {
          PolicyEditor(
            ..policy,
            draft_tabs: policy.saved_tabs,
            state: mutation.Idle,
            save_generation: request_generation.next(policy.save_generation),
          )
        })

      #(
        Model(
          ..model,
          policies: loadable.Loaded(next_policies),
          active_editor: option.Some(ActiveEditor(action:, tab: AnonymousTab)),
        ),
        admin_effect.OpenDialog(edit_dialog_id),
      )
    }

    EditDialogClosed -> #(
      policy.invalidate_active_save(model),
      admin_effect.none(),
    )

    TabSelected(action, tab) -> #(
      Model(
        ..model,
        active_editor: option.Some(ActiveEditor(action:, tab: tab)),
      ),
      admin_effect.none(),
    )

    FieldChanged(action, tab, unit, value) -> #(
      Model(
        ..model,
        policies: loadable.Loaded(
          policy.update(policy.loaded(model), action, fn(policy) {
            PolicyEditor(
              ..policy,
              draft_tabs: policy.update_tab(policy.draft_tabs, tab, fn(fields) {
                policy.update_limit(fields, unit, value)
              }),
              state: mutation.Idle,
              save_generation: request_generation.next(policy.save_generation),
            )
          }),
        ),
      ),
      admin_effect.none(),
    )

    CancelClicked -> #(
      policy.invalidate_active_save(model),
      admin_effect.CloseDialog(edit_dialog_id),
    )

    SaveClicked(action) ->
      case policy.find(policy.loaded(model), action) {
        option.None -> #(model, admin_effect.none())
        option.Some(policy) ->
          case policy.to_request(policy) {
            Ok(request) -> {
              let generation = request_generation.next(policy.save_generation)
              #(
                Model(
                  ..model,
                  policies: loadable.Loaded(
                    policy.update(policy.loaded(model), action, fn(row) {
                      PolicyEditor(
                        ..row,
                        state: mutation.Saving,
                        save_generation: generation,
                      )
                    }),
                  ),
                ),
                admin_effect.upsert_admin_rate_limit_policy(request, fn(result) {
                  SaveFinished(action, generation, result)
                }),
              )
            }
            Error(message) -> #(
              Model(
                ..model,
                policies: loadable.Loaded(
                  policy.update(policy.loaded(model), action, fn(row) {
                    PolicyEditor(..row, state: mutation.SaveError(message))
                  }),
                ),
              ),
              admin_effect.none(),
            )
          }
      }

    SaveFinished(_action, generation, _)
      if option.Some(generation) != current_save_generation
    -> #(model, admin_effect.none())
    SaveFinished(action, generation, result) ->
      case result {
        api_response.Success(response) -> {
          let saved_tabs = policy.tabs_from_rules(response.rules)

          #(
            Model(
              ..model,
              policies: loadable.Loaded(
                policy.update(policy.loaded(model), action, fn(policy) {
                  PolicyEditor(
                    ..policy,
                    saved_tabs: saved_tabs,
                    draft_tabs: saved_tabs,
                    state: mutation.Saved,
                    save_generation: generation,
                  )
                }),
              ),
              active_editor: option.None,
            ),
            admin_effect.CloseDialog(edit_dialog_id),
          )
        }

        api_response.ApiFailure(error) -> #(
          Model(
            ..model,
            policies: loadable.Loaded(
              policy.update(policy.loaded(model), action, fn(policy) {
                PolicyEditor(
                  ..policy,
                  state: mutation.SaveError(api_response.error_message(error)),
                )
              }),
            ),
          ),
          admin_effect.none(),
        )

        api_response.HttpFailure(_) -> #(
          Model(
            ..model,
            policies: loadable.Loaded(
              policy.update(policy.loaded(model), action, fn(policy) {
                PolicyEditor(
                  ..policy,
                  state: mutation.SaveError("Could not save rate limit policy."),
                )
              }),
            ),
          ),
          admin_effect.none(),
        )
      }
  }
}

fn load_policies(
  generation: Generation(LoadStream),
) -> admin_effect.Command(Msg) {
  admin_effect.get_admin_rate_limit_policies(fn(result) {
    PoliciesLoaded(generation, result)
  })
}

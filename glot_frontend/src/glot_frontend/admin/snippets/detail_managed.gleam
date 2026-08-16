import gleam/option
import glot_core/admin/snippet_dto
import glot_core/loadable
import glot_core/route
import glot_core/snippet/snippet_dto as public_snippet_dto
import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/snippets/detail_constants as constants
import glot_frontend/admin/snippets/detail_message.{
  ClassificationFinished, ClassifyClicked, DeleteCancelled, DeleteClicked,
  DeleteConfirmed, DeleteDialogClosed, DeleteFinished, SnippetLoaded,
}
import glot_frontend/admin/snippets/detail_model.{
  ClassificationIdle, Classifying, DeleteIdle, Deleting, Model,
}
import glot_frontend/admin/ui/loadable as loadable_effect
import glot_frontend/api/response as api_response
import glot_frontend/request_generation

pub type Model =
  detail_model.Model

pub type Msg =
  detail_message.Msg

pub fn init(slug: String) -> #(Model, admin_effect.Command(Msg)) {
  #(
    Model(
      slug: slug,
      snippet: loadable.NotLoaded,
      pending_delete: option.None,
      classification_state: ClassificationIdle,
      classification_error: option.None,
      classification_generation: request_generation.initial(),
      delete_state: DeleteIdle,
      delete_generation: request_generation.initial(),
    ),
    admin_effect.none(),
  )
}

pub fn ensure_loaded(model: Model) -> #(Model, admin_effect.Command(Msg)) {
  case
    loadable_effect.ensure_loaded(
      model.snippet,
      admin_effect.get_admin_snippet(
        snippet_dto.GetSnippetRequest(slug: model.slug),
        SnippetLoaded,
      ),
    )
  {
    #(snippet, next_effect) -> #(Model(..model, snippet: snippet), next_effect)
  }
}

pub fn update(model: Model, msg: Msg) -> #(Model, admin_effect.Command(Msg)) {
  case msg {
    SnippetLoaded(result) ->
      case result {
        api_response.Success(response) -> #(
          Model(
            ..model,
            snippet: loadable.Loaded(response.snippet),
            pending_delete: option.None,
            classification_error: option.None,
            delete_state: DeleteIdle,
          ),
          admin_effect.none(),
        )
        api_response.ApiFailure(error) -> #(
          Model(
            ..model,
            snippet: loadable.LoadError(api_response.error_message(error)),
            pending_delete: option.None,
            delete_state: DeleteIdle,
          ),
          admin_effect.none(),
        )
        api_response.HttpFailure(_) -> #(
          Model(
            ..model,
            snippet: loadable.LoadError("Could not load snippet."),
            pending_delete: option.None,
            delete_state: DeleteIdle,
          ),
          admin_effect.none(),
        )
      }

    ClassifyClicked ->
      case model.snippet, model.classification_state {
        loadable.Loaded(snippet), ClassificationIdle -> {
          let generation =
            request_generation.next(model.classification_generation)
          #(
            Model(
              ..model,
              classification_state: Classifying,
              classification_error: option.None,
              classification_generation: generation,
            ),
            admin_effect.classify_admin_snippet(
              snippet_dto.GetSnippetRequest(slug: snippet.slug),
              fn(result) { ClassificationFinished(generation, result) },
            ),
          )
        }
        _, _ -> #(model, admin_effect.none())
      }

    ClassificationFinished(generation, _)
      if generation != model.classification_generation
    -> #(model, admin_effect.none())
    ClassificationFinished(_, result) ->
      case result {
        api_response.Success(response) -> #(
          Model(
            ..model,
            snippet: loadable.Loaded(response.snippet),
            classification_state: ClassificationIdle,
            classification_error: option.None,
          ),
          admin_effect.none(),
        )
        api_response.ApiFailure(error) -> #(
          Model(
            ..model,
            classification_state: ClassificationIdle,
            classification_error: option.Some(api_response.error_message(error)),
          ),
          admin_effect.none(),
        )
        api_response.HttpFailure(_) -> #(
          Model(
            ..model,
            classification_state: ClassificationIdle,
            classification_error: option.Some("Could not classify snippet."),
          ),
          admin_effect.none(),
        )
      }

    DeleteClicked ->
      case model.snippet {
        loadable.Loaded(snippet) -> #(
          Model(..model, pending_delete: option.Some(snippet)),
          admin_effect.OpenDialog(constants.delete_dialog_id),
        )
        _ -> #(model, admin_effect.none())
      }

    DeleteCancelled -> #(
      model,
      admin_effect.CloseDialog(constants.delete_dialog_id),
    )

    DeleteDialogClosed -> #(
      Model(..model, pending_delete: option.None),
      admin_effect.none(),
    )

    DeleteConfirmed ->
      case model.pending_delete {
        option.Some(snippet) -> #(
          Model(
            ..model,
            delete_state: Deleting,
            delete_generation: request_generation.next(model.delete_generation),
          ),
          admin_effect.batch([
            admin_effect.CloseDialog(constants.delete_dialog_id),
            admin_effect.delete_admin_snippet(
              public_snippet_dto.DeleteSnippetRequest(slug: snippet.slug),
              fn(result) {
                DeleteFinished(
                  request_generation.next(model.delete_generation),
                  result,
                )
              },
            ),
          ]),
        )
        option.None -> #(model, admin_effect.none())
      }

    DeleteFinished(generation, _) if generation != model.delete_generation -> #(
      model,
      admin_effect.none(),
    )
    DeleteFinished(_, result) ->
      case result {
        api_response.Success(_) -> #(
          Model(..model, pending_delete: option.None, delete_state: DeleteIdle),
          navigate_to_snippets(),
        )
        api_response.ApiFailure(error) -> #(
          Model(
            ..model,
            snippet: loadable.LoadError(api_response.error_message(error)),
            pending_delete: option.None,
            delete_state: DeleteIdle,
          ),
          admin_effect.none(),
        )
        api_response.HttpFailure(_) -> #(
          Model(
            ..model,
            snippet: loadable.LoadError("Could not delete snippet."),
            pending_delete: option.None,
            delete_state: DeleteIdle,
          ),
          admin_effect.none(),
        )
      }
  }
}

fn navigate_to_snippets() -> admin_effect.Command(Msg) {
  admin_effect.Navigate(route.Admin(route.AdminSnippets(query: option.None)))
}

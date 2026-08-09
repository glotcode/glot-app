import gleam/option
import glot_frontend/account/snippets/delete_update
import glot_frontend/account/snippets/loading_update
import glot_frontend/account/snippets/message.{
  type Msg, DeleteCancelled, DeleteClicked, DeleteConfirmed, DeleteDialogClosed,
  DeleteFinished, LoadingDelayElapsed, NextPageClicked, PreviousPageClicked,
  SnippetsLoaded,
}
import glot_frontend/account/snippets/model.{type Model}
import glot_frontend/account/snippets/pagination_update

pub fn init(
  after after: option.Option(String),
  before before: option.Option(String),
  language language_filter: option.Option(String),
) {
  loading_update.init(after, before, language_filter)
}

pub fn update(model: Model, msg: Msg) {
  case msg {
    SnippetsLoaded(_, _) | LoadingDelayElapsed(_, _) ->
      loading_update.update(model, msg)
    NextPageClicked | PreviousPageClicked ->
      pagination_update.update(model, msg)
    DeleteClicked(_)
    | DeleteCancelled
    | DeleteDialogClosed
    | DeleteConfirmed(_)
    | DeleteFinished(_, _) -> delete_update.update(model, msg)
  }
}

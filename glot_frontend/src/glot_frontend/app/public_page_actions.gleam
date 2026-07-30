import gleam/list
import gleam/option
import glot_frontend/app/public_page_message.{type Msg, EditorPageMsg}
import glot_frontend/app/public_page_state.{type Model, Editor}
import glot_frontend/public/editor/quick_actions as editor_quick_actions
import glot_web/page/top_bar
import youid/uuid.{type Uuid}

pub fn actions(
  model: Model,
  current_user_id: option.Option(Uuid),
) -> List(top_bar.Action(Msg)) {
  case model {
    Editor(editor) ->
      list.map(
        editor_quick_actions.actions(editor, current_user_id),
        fn(action) { top_bar.map_action(action, EditorPageMsg) },
      )
    _ -> []
  }
}

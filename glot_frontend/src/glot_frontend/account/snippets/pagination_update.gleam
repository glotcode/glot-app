import gleam/option
import glot_core/language
import glot_core/pagination_model
import glot_core/route
import glot_frontend/account/snippets/command
import glot_frontend/account/snippets/message.{
  NextPageClicked, PreviousPageClicked,
}
import glot_frontend/account/snippets/model.{type Model}

pub fn update(state: Model, msg: message.Msg) {
  case msg {
    NextPageClicked -> navigate_cursor(model.next_cursor(state), True, state)
    PreviousPageClicked ->
      navigate_cursor(model.previous_cursor(state), False, state)
    _ -> #(state, command.none())
  }
}

fn navigate_cursor(
  cursor: option.Option(pagination_model.Cursor),
  forwards: Bool,
  state: Model,
) {
  case cursor {
    option.Some(value) -> {
      let cursor = option.Some(pagination_model.to_string(value))
      #(
        state,
        navigate_to(
          case forwards {
            True -> cursor
            False -> option.None
          },
          case forwards {
            True -> option.None
            False -> cursor
          },
          state.language,
        ),
      )
    }
    option.None -> #(state, command.none())
  }
}

fn navigate_to(after, before, language_filter) {
  let #(path, query) =
    route.path_and_query(
      route.Account(route.AccountSnippets(
        after:,
        before:,
        language: option.map(language_filter, language.to_string),
      )),
    )
  command.Navigate(path, query)
}

import gleam/list
import gleam/option
import glot_core/admin/spam_review_dto
import glot_core/loadable
import glot_core/pagination_model
import glot_core/route
import glot_core/snippet/manual_review.{type ManualReview}
import glot_frontend/admin/command
import glot_frontend/admin/effect/content
import glot_frontend/admin/list_query
import glot_frontend/admin/spam_review/message.{type Msg}
import glot_frontend/admin/spam_review/model.{type Model}
import glot_frontend/admin/spam_review/query
import glot_frontend/admin/ui/cursor_page
import glot_frontend/api/response

pub fn init(
  raw_query: option.Option(String),
) -> #(Model, command.Command(Msg)) {
  let draft = query.parse(raw_query)
  #(
    model.Model(
      loadable.NotLoaded,
      raw_query,
      draft,
      draft,
      0,
      False,
      option.None,
      option.None,
    ),
    command.none(),
  )
}

pub fn ensure_loaded(model: Model) -> #(Model, command.Command(Msg)) {
  case model.page {
    loadable.NotLoaded -> load(model)
    _ -> #(model, command.none())
  }
}

fn load(model: Model) {
  case query.validate(model.applied) {
    Error(error) -> #(
      model.Model(..model, page: loadable.LoadError(error)),
      command.none(),
    )
    Ok(filter) -> #(
      model.Model(
        ..model,
        page: loadable.Loading,
        generation: model.generation + 1,
      ),
      command.Content(
        content.GetSpamReview(
          spam_review_dto.ListRequest(
            list_query.pagination(list_query.parse(model.raw_query), 1),
            filter,
            list_query.value(list_query.parse(model.raw_query), "focus"),
            list_query.value_or(
              list_query.parse(model.raw_query),
              "inclusive",
              "",
            )
              == "1",
          ),
          message.Loaded(model.generation + 1, _),
        ),
      ),
    )
  }
}

pub fn current(model: Model) {
  cursor_page.current_page(model.page)
  |> pagination_model.items
  |> list.first
  |> option.from_result
}

pub fn update(model: Model, msg: Msg) -> #(Model, command.Command(Msg)) {
  case msg {
    message.Loaded(generation, _) if generation != model.generation -> #(
      model,
      command.none(),
    )
    message.Loaded(_, result) -> #(
      model.Model(
        ..model,
        page: cursor_page.page_from_response(
          result,
          fn(page) { page },
          "Could not load review queue. Retry loading.",
        ),
      ),
      command.none(),
    )
    message.Saved(item, result) -> saved(model, item, result)
    message.Undone(result) -> undone(model, result)
    _ if model.saving -> #(model, command.none())
    message.FieldChanged(field, value) -> #(
      model.Model(..model, draft: query.set(model.draft, field, value)),
      command.none(),
    )
    message.Apply ->
      case query.validate(model.draft) {
        Error(error) -> #(
          model.Model(..model, error: option.Some(error)),
          command.none(),
        )
        Ok(_) -> navigate(model, model.draft, pagination_model.InitialPage(1))
      }
    message.Clear ->
      navigate(model, query.all(), pagination_model.InitialPage(1))
    message.Previous ->
      browse(model, cursor_page.previous_pagination(model.page, 1))
    message.Next -> browse(model, cursor_page.next_pagination(model.page, 1))
    message.Reload -> load(model.Model(..model, error: option.None))
    message.Save(verdict) ->
      case current(model) {
        option.None -> #(model, command.none())
        option.Some(item) -> #(
          model.Model(..model, saving: True, error: option.None),
          command.Content(
            content.SaveManualReview(
              spam_review_dto.SaveRequest(
                item.snippet.slug,
                verdict,
                item.manual_review.version,
                item.snippet.updated_at,
              ),
              message.Saved(item, _),
            ),
          ),
        )
      }
    message.Undo ->
      case model.undo {
        option.None -> #(model, command.none())
        option.Some(undo) -> #(
          model.Model(..model, saving: True, error: option.None),
          command.Content(content.SaveManualReview(
            spam_review_dto.SaveRequest(
              undo.item.snippet.slug,
              undo.item.manual_review.verdict,
              undo.saved_version,
              undo.item.snippet.updated_at,
            ),
            message.Undone,
          )),
        )
      }
  }
}

fn saved(
  model: Model,
  item: spam_review_dto.ReviewSnippet,
  result: response.Response(ManualReview),
) {
  case model.saving, result {
    False, _ -> #(model, command.none())
    True, response.Success(review) -> {
      let next_model =
        model.Model(
          ..model,
          undo: option.Some(model.Undo(item, model.raw_query, review.version)),
        )
      navigate(
        next_model,
        model.applied,
        pagination_model.AfterPage(
          pagination_model.from_string(item.snippet.slug),
          1,
        ),
      )
    }
    True, _ -> save_failed(model, result)
  }
}

fn undone(model: Model, result) {
  case model.saving, model.undo, result {
    True, option.Some(undo), response.Success(_) -> #(
      model.Model(..model, undo: option.None),
      command.Navigate(
        route.Admin(
          route.AdminSpamReview(query.focus(undo.query, undo.item.snippet.slug)),
        ),
      ),
    )
    True, _, _ -> save_failed(model, result)
    False, _, _ -> #(model, command.none())
  }
}

fn save_failed(model: Model, result) {
  #(
    model.Model(
      ..model,
      saving: False,
      error: option.Some(response.user_message(
        result,
        "Could not save the review. Retry the action.",
      )),
    ),
    command.none(),
  )
}

fn browse(model: Model, pagination) {
  case pagination {
    option.None -> #(model, command.none())
    option.Some(pagination) ->
      case current(model) {
        option.Some(_) -> navigate(model, model.applied, pagination)
        option.None -> #(
          model,
          command.Navigate(
            route.Admin(
              route.AdminSpamReview(option.Some(
                option.unwrap(query.encode(model.applied, pagination), "")
                <> "&inclusive=1",
              )),
            ),
          ),
        )
      }
  }
}

fn navigate(model: Model, draft, pagination) {
  let raw_query = query.encode(draft, pagination)
  case raw_query == model.raw_query {
    True ->
      load(
        model.Model(
          ..model,
          draft:,
          applied: draft,
          saving: False,
          error: option.None,
        ),
      )
    False -> #(
      model,
      command.Navigate(route.Admin(route.AdminSpamReview(raw_query))),
    )
  }
}

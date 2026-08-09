import gleam/option
import glot_core/language
import glot_core/loadable
import glot_core/pagination_model
import glot_core/snippet/snippet_dto
import glot_frontend/account/snippets/command
import glot_frontend/account/snippets/message.{
  LoadingDelayElapsed, SnippetsLoaded,
}
import glot_frontend/account/snippets/model.{type Model, type Request}
import glot_frontend/api/response as api_response
import glot_frontend/ui/delayed_loading

const page_limit = 20

pub fn init(
  after: option.Option(String),
  before: option.Option(String),
  language language_slug: option.Option(String),
) {
  let language_filter = option.then(language_slug, language.from_string)
  let request = model.request(after:, before:, language: language_filter)
  let #(indicator, generation) = delayed_loading.begin(delayed_loading.idle())
  let state =
    model.Model(
      page: loadable.Loading,
      after:,
      before:,
      language: language_filter,
      pending_delete: option.None,
      deleting_slug: option.None,
      mutation_error: option.None,
      request:,
      loading_indicator: indicator,
    )
  #(state, commands(request, generation))
}

pub fn reload(state: Model) {
  let #(indicator, generation) = delayed_loading.begin(state.loading_indicator)
  #(
    model.Model(
      ..state,
      page: loadable.Loading,
      pending_delete: option.None,
      deleting_slug: option.None,
      mutation_error: option.None,
      loading_indicator: indicator,
    ),
    commands(state.request, generation),
  )
}

pub fn update(state: Model, msg: message.Msg) {
  case msg {
    SnippetsLoaded(request, result) -> loaded(state, request, result)
    LoadingDelayElapsed(request, generation) ->
      case request == state.request {
        True -> #(
          model.Model(
            ..state,
            loading_indicator: delayed_loading.reveal(
              state.loading_indicator,
              generation,
            ),
          ),
          command.none(),
        )
        False -> #(state, command.none())
      }
    _ -> #(state, command.none())
  }
}

fn loaded(
  state: Model,
  request: Request,
  result: api_response.Response(snippet_dto.ListSnippetsResponse),
) {
  case request == state.request, result {
    False, _ -> #(state, command.none())
    True, api_response.Success(response) -> #(
      model.Model(
        ..state,
        page: loadable.Loaded(response.page),
        pending_delete: option.None,
        mutation_error: option.None,
        loading_indicator: delayed_loading.finish(state.loading_indicator),
      ),
      command.none(),
    )
    True, api_response.ApiFailure(error) ->
      failed(state, api_response.error_message(error))
    True, api_response.HttpFailure(_) ->
      failed(state, "Could not load your snippets.")
  }
}

fn failed(state: Model, message: String) {
  #(
    model.Model(
      ..state,
      page: loadable.LoadError(message),
      pending_delete: option.None,
      loading_indicator: delayed_loading.finish(state.loading_indicator),
    ),
    command.none(),
  )
}

fn commands(request: Request, generation) {
  command.batch([
    load_page(request),
    command.Schedule(
      delayed_loading.delay(),
      LoadingDelayElapsed(request, generation),
    ),
  ])
}

fn load_page(request: Request) {
  command.ListSnippets(
    snippet_dto.ListSessionSnippetsRequest(
      pagination: pagination_from_cursors(
        model.request_after(request),
        model.request_before(request),
      ),
      languages: languages_from_filter(model.request_language(request)),
    ),
    fn(result) { SnippetsLoaded(request, result) },
  )
}

fn languages_from_filter(
  language_filter: option.Option(language.Language),
) -> List(language.Language) {
  case language_filter {
    option.Some(lang) -> [lang]
    option.None -> []
  }
}

fn pagination_from_cursors(
  after: option.Option(String),
  before: option.Option(String),
) {
  case after, before {
    option.Some(cursor), option.None ->
      pagination_model.AfterPage(
        cursor: pagination_model.from_string(cursor),
        limit: page_limit,
      )
    option.None, option.Some(cursor) ->
      pagination_model.BeforePage(
        cursor: pagination_model.from_string(cursor),
        limit: page_limit,
      )
    option.None, option.None | option.Some(_), option.Some(_) ->
      pagination_model.InitialPage(limit: page_limit)
  }
}

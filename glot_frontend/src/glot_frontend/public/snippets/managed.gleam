import gleam/json
import gleam/option
import glot_core/language
import glot_core/loadable
import glot_frontend/api/response as api_response
import glot_frontend/public/snippets/command
import glot_frontend/public/snippets/message.{
  type Msg, EnvironmentLoaded, LoadingDelayElapsed, SnippetsLoaded,
}
import glot_frontend/public/snippets/model.{type Model, Model, Request}
import glot_frontend/ui/delayed_loading
import glot_web/page/snippets

pub fn init(
  after after: option.Option(String),
  before before: option.Option(String),
  username username: option.Option(String),
  language language_filter: option.Option(String),
) -> #(Model, command.Command(Msg)) {
  let language_filter = option.then(language_filter, language.from_string)
  let request = Request(after:, before:, username:, language: language_filter)
  #(
    Model(
      page: loadable.Loading,
      username: username,
      language: language_filter,
      request:,
      loading_indicator: delayed_loading.idle(),
    ),
    command.LoadSsr(fn(raw) { EnvironmentLoaded(request, raw) }),
  )
}

pub fn update(model: Model, msg: Msg) -> #(Model, command.Command(Msg)) {
  case msg {
    EnvironmentLoaded(request, raw) ->
      case request == model.request {
        False -> #(model, command.none())
        True ->
          case parse_ssr(raw) {
            option.Some(model) -> #(model, command.none())
            option.None -> start_loading(model)
          }
      }
    SnippetsLoaded(request, result) ->
      case request == model.request, result {
        False, _ -> #(model, command.none())
        True, api_response.Success(response) -> #(
          Model(
            ..model,
            page: loadable.Loaded(response.page),
            loading_indicator: delayed_loading.finish(model.loading_indicator),
          ),
          command.none(),
        )
        True, api_response.ApiFailure(error) -> #(
          Model(
            ..model,
            page: loadable.LoadError(api_response.error_message(error)),
            loading_indicator: delayed_loading.finish(model.loading_indicator),
          ),
          command.none(),
        )
        True, api_response.HttpFailure(_) -> #(
          Model(
            ..model,
            page: loadable.LoadError("Could not load snippets."),
            loading_indicator: delayed_loading.finish(model.loading_indicator),
          ),
          command.none(),
        )
      }
    LoadingDelayElapsed(request, generation) ->
      case request == model.request {
        True -> #(
          Model(
            ..model,
            loading_indicator: delayed_loading.reveal(
              model.loading_indicator,
              generation,
            ),
          ),
          command.none(),
        )
        False -> #(model, command.none())
      }
  }
}

fn load_page(request: model.Request) -> command.Command(Msg) {
  command.ListPublicSnippets(
    snippets.public_request(
      after: request.after,
      before: request.before,
      username: request.username,
      language: request.language,
    ),
    fn(result) { SnippetsLoaded(request, result) },
  )
}

fn parse_ssr(raw: String) -> option.Option(Model) {
  case raw {
    "" -> option.None
    raw ->
      case json.parse(raw, snippets.decoder()) {
        Ok(view_model) -> option.Some(from_view_model(view_model))
        Error(_) -> option.None
      }
  }
}

fn start_loading(model: Model) -> #(Model, command.Command(Msg)) {
  let #(loading_indicator, generation) =
    delayed_loading.begin(model.loading_indicator)
  #(
    Model(..model, page: loadable.Loading, loading_indicator:),
    command.batch([
      load_page(model.request),
      command.Schedule(
        delayed_loading.delay(),
        LoadingDelayElapsed(model.request, generation),
      ),
    ]),
  )
}

fn from_view_model(view_model: snippets.ViewModel) -> Model {
  Model(
    page: view_model.page,
    username: view_model.username,
    language: view_model.language,
    request: Request(
      after: option.None,
      before: option.None,
      username: view_model.username,
      language: view_model.language,
    ),
    loading_indicator: delayed_loading.idle(),
  )
}

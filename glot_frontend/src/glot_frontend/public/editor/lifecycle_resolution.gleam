import gleam/json
import gleam/option
import glot_core/language
import glot_frontend/public/editor/lifecycle
import glot_web/page/editor as editor_ssr

/// The pure decision produced from an editor route and its optional SSR data.
pub type Resolution {
  StartNew(language.Language)
  StartExisting(editor_ssr.EditorModel)
  FetchExisting(String)
  Unsupported(String)
  Failed(String)
}

pub fn resolve(target: lifecycle.Target, raw_ssr: String) -> Resolution {
  let ssr_model = decode(raw_ssr)

  case target {
    lifecycle.NewEditor(language_slug) -> resolve_new(language_slug, ssr_model)
    lifecycle.ExistingEditor(slug) -> resolve_existing(slug, ssr_model)
  }
}

fn resolve_new(
  language_slug: String,
  ssr_model: option.Option(editor_ssr.ViewModel),
) -> Resolution {
  case ssr_model {
    option.Some(editor_ssr.NewSnippet(editor_ssr.EditorModel(language:, ..))) ->
      StartNew(language)
    option.Some(editor_ssr.UnsupportedLanguage(language_slug)) ->
      Unsupported(language_slug)
    option.Some(editor_ssr.LoadError(message)) -> Failed(message)
    option.Some(editor_ssr.ExistingSnippet(_)) | option.None ->
      case language.from_string(language_slug) {
        option.Some(language) -> StartNew(language)
        option.None -> Unsupported(language_slug)
      }
  }
}

fn resolve_existing(
  slug: String,
  ssr_model: option.Option(editor_ssr.ViewModel),
) -> Resolution {
  case ssr_model {
    option.Some(editor_ssr.ExistingSnippet(model)) ->
      case model.slug {
        option.Some(ssr_slug) if ssr_slug != slug -> FetchExisting(slug)
        _ -> StartExisting(model)
      }
    option.Some(editor_ssr.LoadError(message)) -> Failed(message)
    option.Some(editor_ssr.NewSnippet(_))
    | option.Some(editor_ssr.UnsupportedLanguage(_))
    | option.None -> FetchExisting(slug)
  }
}

fn decode(raw_ssr: String) -> option.Option(editor_ssr.ViewModel) {
  case raw_ssr {
    "" -> option.None
    raw_ssr ->
      case json.parse(raw_ssr, editor_ssr.decoder()) {
        Ok(model) -> option.Some(model)
        Error(_) -> option.None
      }
  }
}
